#!/usr/bin/env bash
# list.sh — List all logged builds

portfol_list() {
  if [[ ! -s "$BUILDS_FILE" ]]; then
    portfol_warn "No builds logged yet. Run: portfol log --quick \"description\""
    return 0
  fi

  portfol_header "Your Builds"

  local filter_tag="${1:-}"
  local count=0

  while IFS= read -r line; do
    local id=$(echo "$line" | jq -r '.id')
    local title=$(echo "$line" | jq -r '.title')
    local ts=$(echo "$line" | jq -r '.timestamp')
    local skills=$(echo "$line" | jq -r '.skills_demonstrated | join(", ")')
    local date_part="${ts%%T*}"

    if [[ -n "$filter_tag" ]]; then
      echo "$line" | jq -e ".tags | index(\"$filter_tag\")" &>/dev/null || continue
    fi

    echo -e "  ${CYAN}${id}${RESET}  ${date_part}  ${BOLD}${title}${RESET}"
    if [[ -n "$skills" && "$skills" != "null" ]]; then
      echo -e "         ${DIM}${skills}${RESET}"
    fi
    echo ""
    count=$((count + 1))
  done < "$BUILDS_FILE"

  echo -e "  ${DIM}${count} builds total${RESET}"
}
