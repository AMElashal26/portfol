#!/usr/bin/env bash
# ============================================================================
# log.sh — Log a new build entry
# ============================================================================
#
# PURPOSE:
#   This is the MOST IMPORTANT command in portfol. Everything else depends on
#   having builds logged. When you finish building something in your terminal,
#   you run `portfol log --quick "what I built"` and it:
#
#   1. Creates a unique build ID (b_20260326_001)
#   2. Scans your filesystem for recently modified files
#   3. Auto-detects what languages/tools you used from file extensions
#   4. Saves everything as a single JSON line in ~/.portfol/builds.jsonl
#
# TWO MODES:
#   --quick "desc"  → One-liner, no questions asked (for when you're in flow)
#   (no args)       → Interactive mode, asks what you built
#
# DATA FORMAT — JSONL:
#   JSONL = JSON Lines. Each line in builds.jsonl is a complete, independent
#   JSON object. This is different from a JSON array (which wraps everything
#   in [...]).
#
#   JSONL advantages:
#     - Append-only: just `echo >> file` (no need to parse the whole file)
#     - Streamable: process one line at a time (low memory)
#     - grep-friendly: `grep "python" builds.jsonl` just works
#     - jq-native: `jq '.' builds.jsonl` processes each line automatically
#     - The format used by BigQuery, n8n, and most data pipelines
#
# ============================================================================


# ── Main Entry Point ───────────────────────────────────────────────────────
#
# This function parses command-line arguments and decides which mode to use.
#
# ARGUMENT PARSING PATTERN:
#   We use a `while` loop + `case` to handle flags. This is the standard
#   bash pattern (you'll see it in almost every CLI tool's source code).
#
#   The loop processes arguments one by one:
#     $1 = first arg, $2 = second arg, etc.
#     `shift` removes $1 and slides everything down
#     $# is the count of remaining arguments
#     $* is all remaining arguments as one string
#
portfol_log() {
  local quick_mode=false      # Will we skip the interactive prompts?
  local description=""         # What did you build?
  local from_git=false         # Are we pulling the description from git?

  # Loop through all arguments
  while [[ $# -gt 0 ]]; do     # While there are still arguments to process
    case "$1" in
      --quick|-q)
        quick_mode=true
        shift                   # Remove the --quick flag from the args
        if [[ $# -gt 0 ]]; then
          description="$*"      # Everything after --quick is the description
          break                 # Stop parsing, we have what we need
        fi
        ;;
      --from-git)
        # Pull the last commit message as the description
        # This is used by the `gc` alias (future Phase 5)
        # git log -1 --pretty=%B → prints just the commit message, no metadata
        description=$(git log -1 --pretty=%B 2>/dev/null || echo "")
        quick_mode=true
        from_git=true
        shift
        ;;
      *)
        # Anything that isn't a flag becomes the description
        description="$*"
        quick_mode=true
        break
        ;;
    esac
  done

  # Route to the right mode
  if $quick_mode && [[ -n "$description" ]]; then
    _log_quick "$description"
  else
    _log_interactive
  fi
}


# ── Quick Log Mode ─────────────────────────────────────────────────────────
#
# The fast path. One line in, one line out. Designed for ADHD-friendly flow:
# you just finished building something → type `plog "what I did"` → done.
#
# FLOW:
#   1. Generate a unique build ID
#   2. Find recently modified files (auto-detection)
#   3. Guess skills from file extensions
#   4. Build a JSON object with all this data
#   5. Append it to builds.jsonl
#
_log_quick() {
  local description="$1"

  # Generate a unique ID for this build (see utils.sh for how this works)
  local build_id=$(generate_build_id)

  # ISO 8601 timestamp in UTC
  # date -u = UTC time (consistent regardless of timezone)
  # The format string creates: 2026-03-26T22:15:00Z
  #   %Y = year, %m = month, %d = day, %H = hour, %M = min, %S = sec
  #   T separates date from time, Z means "UTC/Zulu time"
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")


  # ── Step 1: Find Recently Modified Files ────────────────────────────────
  #
  # `find` searches the filesystem for files matching criteria.
  #
  # Breaking down the command:
  #   find "$HOME/Developer" "$HOME/scripts" "$HOME/Claude_ref"
  #     ↑ Search in these three directories (where you likely code)
  #
  #   -maxdepth 3
  #     ↑ Don't go more than 3 levels deep (avoids node_modules rabbit holes)
  #
  #   -type f
  #     ↑ Only files (not directories)
  #
  #   -not -path "*/.git/*"
  #     ↑ Exclude .git internals (pack files, refs, etc.)
  #
  #   -not -name ".DS_Store"
  #     ↑ Exclude macOS metadata files
  #
  #   -mmin -120
  #     ↑ Modified within the last 120 minutes (2 hours)
  #     -mmin means "modification time in minutes"
  #     The minus sign means "less than" (so -120 = less than 120 min ago)
  #
  #   2>/dev/null
  #     ↑ Suppress "permission denied" errors on folders we can't read
  #
  #   | head -10
  #     ↑ Only keep the first 10 results (keeps things manageable)
  #
  #   || true
  #     ↑ If find fails (e.g., directory doesn't exist), don't crash
  #       (remember: set -e would kill us otherwise)
  #
  local recent_files_json="[]"     # Default: empty JSON array
  local file_list=""
  file_list=$(find "$HOME/Developer" "$HOME/scripts" "$HOME/Claude_ref" \
    -maxdepth 3 -type f \
    -not -path "*/.git/*" \
    -not -path "*/node_modules/*" \
    -not -name ".DS_Store" \
    -not -name ".*" \
    -mmin -120 2>/dev/null | head -10 || true)

  # Convert the file list to a JSON array using jq
  # Pipeline explained:
  #   echo "$file_list"     → outputs each file path on its own line
  #   | jq -R .             → -R reads raw text (not JSON), . wraps each line in quotes
  #                           Input:  /path/to/file.sh
  #                           Output: "/path/to/file.sh"
  #   | jq -s .             → -s "slurps" all inputs into a JSON array
  #                           Output: ["/path/to/file.sh", "/path/to/other.py"]
  #
  if [[ -n "$file_list" ]]; then
    recent_files_json=$(echo "$file_list" | jq -R . | jq -s .)
  fi


  # ── Step 2: Auto-Detect Skills From File Extensions ─────────────────────
  #
  # We look at what file types were recently modified and infer what
  # technologies you were using. This is a simple heuristic — not perfect,
  # but good enough to auto-tag your builds.
  #
  # BASH ARRAYS:
  #   local skills=()           ← creates an empty array
  #   skills+=("Python")        ← appends "Python" to the array
  #   ${#skills[@]}             ← array length
  #   ${skills[@]}              ← all elements
  #
  # THE WHILE/READ LOOP:
  #   while IFS= read -r f; do ... done <<< "$file_list"
  #
  #   This reads $file_list line by line, storing each line in $f.
  #   IFS= prevents leading/trailing whitespace from being trimmed.
  #   -r prevents backslash interpretation (treats \ as literal).
  #   <<< is a "here string" — feeds a variable as stdin to a command.
  #
  # PARAMETER EXPANSION — ${f##*.}:
  #   This extracts the file extension:
  #     f="/path/to/script.sh"
  #     ${f##*.}  → "sh"
  #
  #   How it works:
  #     ## = remove the LONGEST match from the FRONT
  #     *. = everything up to and including the last dot
  #     So it strips "/path/to/script." leaving just "sh"
  #
  local skills=()
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue    # Skip empty lines
    case "${f##*.}" in
      sh|bash)          skills+=("Shell Scripting") ;;
      py)               skills+=("Python") ;;
      js|ts)            skills+=("JavaScript") ;;
      jsx|tsx)          skills+=("React") ;;
      applescript|scpt) skills+=("AppleScript") ;;
      json)             skills+=("JSON/Data") ;;
      md)               skills+=("Documentation") ;;
    esac
  done <<< "$file_list"

  # Deduplicate skills
  # Pipeline: array → one per line → sort unique → wrap as JSON strings → make array
  #
  #   printf '%s\n' "${skills[@]}"   → prints each skill on its own line
  #   sort -u                         → sorts and removes duplicates (-u = unique)
  #   jq -R .                         → wraps each line in quotes (raw → JSON string)
  #   jq -s .                         → slurps into a JSON array
  #
  local unique_skills_json="[]"
  if [[ ${#skills[@]} -gt 0 ]]; then
    unique_skills_json=$(printf '%s\n' "${skills[@]}" | sort -u | jq -R . | jq -s .)
  fi


  # ── Step 3: Build and Save the JSONL Entry ──────────────────────────────
  #
  # jq -cn builds a JSON object from scratch:
  #   -c = compact output (one line, no pretty-printing — critical for JSONL!)
  #   -n = don't read input, just construct output
  #
  #   --arg name value      → creates a string variable accessible as $name in the jq expression
  #   --argjson name value  → creates a JSON variable (for arrays/objects, not strings)
  #
  # The jq expression inside the single quotes is like a mini template:
  #   { id: $id, ... }  → builds a JSON object using the variables we passed in
  #
  local entry
  entry=$(jq -cn \
    --arg id "$build_id" \
    --arg ts "$timestamp" \
    --arg desc "$description" \
    --argjson files "$recent_files_json" \
    --argjson skills "$unique_skills_json" \
    '{
      id: $id,
      timestamp: $ts,
      title: $desc,
      description: $desc,
      source_files: $files,
      skills_demonstrated: $skills,
      tags: [],
      status: "active"
    }')

  # Append to the builds file
  # >> means APPEND (add to end), > would OVERWRITE (destroy everything!)
  echo "$entry" >> "$BUILDS_FILE"

  # ── Step 4: Confirm to the User ────────────────────────────────────────
  local file_count=$(echo "$recent_files_json" | jq 'length')
  portfol_success "Logged: ${CYAN}${build_id}${RESET}"
  portfol_success "${file_count} recent files detected"
  echo -e "  ${DIM}Run 'portfol show $build_id' to review${RESET}"
}


# ── Interactive Log Mode ───────────────────────────────────────────────────
#
# When you just type `portfol log` with no arguments, this asks you
# what you built. Currently simple — will get richer in Phase 1
# (showing detected files, asking about tags, etc.)
#
# `read -p "prompt: " variable` prints the prompt and waits for input,
# storing whatever you type into $variable.
#
_log_interactive() {
  portfol_header "Log a New Build"

  read -p "  What did you build? (one line): " description
  if [[ -z "$description" ]]; then
    portfol_error "Description required."
    return 1
  fi

  # Reuse the quick path with the description we just got
  _log_quick "$description"
}
