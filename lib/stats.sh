#!/usr/bin/env bash
# ============================================================================
# stats.sh — Portfolio intelligence and analytics
# ============================================================================
#
# PURPOSE:
#   Analyzes your build log to show patterns, skill frequencies, and trends.
#   Currently basic (Phase 0) — will grow to include:
#     - Trending skills (what you're building more of lately)
#     - Stale skills (things you haven't touched in a while)
#     - Gap analysis (skills that job descriptions want but you lack)
#     - Content status (how many posts generated vs published)
#
# UNIX PHILOSOPHY IN ACTION:
#   The stats command chains small tools together with pipes:
#     jq → extracts skills from JSON
#     sort → alphabetical order
#     uniq -c → counts consecutive duplicates
#     sort -rn → sorts by count, descending
#     head -10 → top 10 only
#
#   Each tool does ONE thing well. Chaining them = powerful analysis
#   without writing complex code. This is the "Unix way."
#
# ============================================================================

portfol_stats() {
  portfol_header "Portfolio Intelligence"

  # Check if there are any builds to analyze
  if [[ ! -s "$BUILDS_FILE" ]]; then
    portfol_warn "No builds logged yet. Start with: portfol log --quick \"description\""
    return 0
  fi

  # ── Total Build Count ─────────────────────────────────────────────────
  #
  # wc -l counts lines in a file. Since JSONL has one entry per line,
  # line count = build count.
  #
  # tr -d ' ' removes whitespace padding that wc sometimes adds on macOS.
  # (macOS wc outputs "     5" instead of "5")
  #
  local total=$(wc -l < "$BUILDS_FILE" | tr -d ' ')
  echo -e "  ${BOLD}Total builds:${RESET} ${CYAN}${total}${RESET}"
  echo ""

  # ── Skill Frequency Chart ────────────────────────────────────────────
  #
  # This pipeline is worth studying — it's a classic Unix data analysis pattern:
  #
  # Step 1: jq -r '.skills_demonstrated[]?' "$BUILDS_FILE"
  #   Reads EVERY line in builds.jsonl and extracts each skill.
  #   The []? means "iterate over the array" and ? means "don't error if null"
  #   Output (one skill per line):
  #     Shell Scripting
  #     Python
  #     Shell Scripting
  #     Claude API
  #     Python
  #     Python
  #
  # Step 2: sort
  #   Alphabetically sorts the lines. This is REQUIRED for uniq to work,
  #   because uniq only removes ADJACENT duplicates.
  #   Output:
  #     Claude API
  #     Python
  #     Python
  #     Python
  #     Shell Scripting
  #     Shell Scripting
  #
  # Step 3: uniq -c
  #   Counts consecutive identical lines and prefixes with the count.
  #   Output:
  #     1 Claude API
  #     3 Python
  #     2 Shell Scripting
  #
  # Step 4: sort -rn
  #   Sorts numerically (-n) in reverse (-r) order. Highest count first.
  #   Output:
  #     3 Python
  #     2 Shell Scripting
  #     1 Claude API
  #
  # Step 5: head -10
  #   Only show the top 10 skills (keeps output manageable).
  #
  echo -e "  ${BOLD}Skills by frequency:${RESET}"
  jq -r '.skills_demonstrated[]?' "$BUILDS_FILE" 2>/dev/null \
    | sort \
    | uniq -c \
    | sort -rn \
    | head -10 \
    | while read count skill; do
        # Build a visual bar chart using Unicode block characters
        # Each █ represents one occurrence of the skill
        local bar=""
        for ((i=0; i<count; i++)); do bar+="█"; done

        # printf for aligned columns:
        #   %-25s  → left-align the skill name in a 25-char wide column
        #   %s     → the bar (variable width)
        #   %s     → the count number
        printf "    %-25s ${CYAN}%s${RESET} %s\n" "$skill" "$bar" "$count"
      done

  echo ""
  echo -e "  ${DIM}Full analytics coming in Phase 4 (trending, gaps, suggestions)${RESET}"
}
