#!/usr/bin/env bash
# stats.sh — Portfolio intelligence and analytics

portfol_stats() {
  portfol_header "Portfolio Intelligence"

  if [[ ! -s "$BUILDS_FILE" ]]; then
    portfol_warn "No builds logged yet. Start with: portfol log --quick \"description\""
    return 0
  fi

  local total=$(wc -l < "$BUILDS_FILE" | tr -d ' ')
  echo -e "  ${BOLD}Total builds:${RESET} ${CYAN}${total}${RESET}"
  echo ""

  # Show skill frequency
  echo -e "  ${BOLD}Skills by frequency:${RESET}"
  jq -r '.skills_demonstrated[]?' "$BUILDS_FILE" 2>/dev/null | sort | uniq -c | sort -rn | head -10 | while read count skill; do
    local bar=""
    for ((i=0; i<count; i++)); do bar+="█"; done
    printf "    %-25s ${CYAN}%s${RESET} %s\n" "$skill" "$bar" "$count"
  done

  echo ""
  echo -e "  ${DIM}Full analytics coming in Phase 4 (trending, gaps, suggestions)${RESET}"
}
