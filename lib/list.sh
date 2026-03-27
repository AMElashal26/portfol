#!/usr/bin/env bash
# ============================================================================
# list.sh — List all logged builds
# ============================================================================
#
# PURPOSE:
#   Shows a summary of every build you've logged, newest at the bottom.
#   Optionally filter by tag: `portfol list automation`
#
# HOW IT READS JSONL:
#   The `while read` loop processes builds.jsonl one line at a time.
#   Each line is a complete JSON object, so we pipe it to jq to extract fields.
#   This is the beauty of JSONL — you don't need to parse the whole file.
#
# ============================================================================

portfol_list() {
  # -s checks if file exists AND has content (size > 0 bytes)
  # An empty file would pass -f (exists) but fail -s (no content)
  if [[ ! -s "$BUILDS_FILE" ]]; then
    portfol_warn "No builds logged yet. Run: portfol log --quick \"description\""
    return 0
  fi

  portfol_header "Your Builds"

  # Optional tag filter: `portfol list automation` → filter_tag="automation"
  # ${1:-} means "first arg, or empty string if none given"
  local filter_tag="${1:-}"
  local count=0

  # ── Read the JSONL file line by line ──────────────────────────────────
  #
  # while IFS= read -r line; do ... done < "$BUILDS_FILE"
  #
  # This is the standard bash pattern for reading a file line by line:
  #   < "$BUILDS_FILE"   → feeds the file into the loop's stdin
  #   IFS=               → don't split on whitespace (preserve the full line)
  #   read -r line        → read one line into $line (-r = no backslash tricks)
  #
  # For each line, we extract fields with jq:
  #   echo "$line" | jq -r '.id'
  #   This pipes the JSON line to jq, which extracts the "id" field.
  #   -r means raw output (no quotes around the string).
  #
  while IFS= read -r line; do
    local id=$(echo "$line" | jq -r '.id')
    local title=$(echo "$line" | jq -r '.title')
    local ts=$(echo "$line" | jq -r '.timestamp')
    local skills=$(echo "$line" | jq -r '.skills_demonstrated | join(", ")')

    # Extract just the date part from the ISO timestamp
    # ${ts%%T*} is parameter expansion:
    #   %% = remove the LONGEST match from the END
    #   T* = "T" followed by anything
    #   "2026-03-26T22:15:00Z" → "2026-03-26"
    local date_part="${ts%%T*}"

    # If a tag filter was given, skip builds that don't have that tag
    # jq -e makes jq return exit code 1 if the result is null/false
    # &>/dev/null silences the output — we only care about the exit code
    # || continue → if jq returns failure (tag not found), skip this build
    if [[ -n "$filter_tag" ]]; then
      echo "$line" | jq -e ".tags | index(\"$filter_tag\")" &>/dev/null || continue
    fi

    # Display the build summary
    echo -e "  ${CYAN}${id}${RESET}  ${date_part}  ${BOLD}${title}${RESET}"
    if [[ -n "$skills" && "$skills" != "null" ]]; then
      echo -e "         ${DIM}${skills}${RESET}"
    fi
    echo ""
    count=$((count + 1))    # Bash arithmetic: increment counter
  done < "$BUILDS_FILE"

  echo -e "  ${DIM}${count} builds total${RESET}"
}
