#!/usr/bin/env bash
# ============================================================================
# show.sh — Show details of a specific build
# ============================================================================
#
# PURPOSE:
#   Deep-dive into one build. Shows the full JSON data plus any generated
#   content files (LinkedIn posts, resume bullets, etc.) that exist for it.
#
# USAGE:
#   portfol show b_20260326_001
#
# HOW GREP FINDS THE BUILD:
#   Instead of parsing every line with jq (slow), we use grep to find
#   the line containing our build ID (fast). grep is optimized for text
#   search — it's orders of magnitude faster than jq for this use case.
#   Then we pipe just THAT ONE line to jq for pretty-printing.
#
# ============================================================================

portfol_show() {
  # Grab the build ID from the first argument
  local build_id="${1:-}"

  # ── Input Validation ───────────────────────────────────────────────────
  # Always validate inputs early. It's better to give a clear error message
  # than to let the script crash with a confusing jq error 20 lines later.
  #
  if [[ -z "$build_id" ]]; then
    portfol_error "Usage: portfol show <build_id>"
    return 1    # Return 1 = failure (convention: 0 = success, non-zero = error)
  fi

  if [[ ! -f "$BUILDS_FILE" ]]; then
    portfol_error "No builds logged yet."
    return 1
  fi

  # ── Find the Build ────────────────────────────────────────────────────
  #
  # grep searches for the build ID in the file and returns matching lines.
  # | head -1 takes only the first match (in case of duplicates).
  #
  # WHY GREP, NOT JQ?
  #   grep "text" file     → scans at ~GB/s, returns matching lines
  #   jq 'select(.id=="text")' file  → parses every line as JSON, much slower
  #   For a lookup-by-ID, grep is the right tool.
  #
  local entry=$(grep "\"$build_id\"" "$BUILDS_FILE" | head -1)

  if [[ -z "$entry" ]]; then
    portfol_error "Build not found: $build_id"
    return 1
  fi

  # ── Display the Build ─────────────────────────────────────────────────
  #
  # jq '.' pretty-prints JSON with indentation and syntax coloring.
  # The '.' filter means "the whole thing" (identity filter).
  #
  portfol_header "Build: $build_id"
  echo "$entry" | jq '.'

  # ── Check for Generated Content ───────────────────────────────────────
  #
  # Each generate mode saves files to a predictable path:
  #   ~/.portfol/outputs/<mode>/<build_id>.md
  #
  # We check each output directory for a file matching this build's ID.
  # The `for dir in ... ; do` loop iterates over the directory names.
  #
  local has_outputs=false
  for dir in linkedin-posts resume-bullets upwork-gigs; do
    local outfile="$OUTPUTS_DIR/$dir/${build_id}.md"
    if [[ -f "$outfile" ]]; then
      # Only print the "Generated Content" header on the first match
      if ! $has_outputs; then
        echo ""
        echo -e "  ${BOLD}Generated Content:${RESET}"
        has_outputs=true
      fi
      portfol_success "$dir → $outfile"
    fi
  done

  # If no content has been generated yet, suggest the command
  if ! $has_outputs; then
    echo ""
    echo -e "  ${DIM}No content generated yet. Run: portfol generate resume-bullet --build $build_id${RESET}"
  fi
}
