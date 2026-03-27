#!/usr/bin/env bash
# show.sh — Show details of a specific build

portfol_show() {
  local build_id="${1:-}"

  if [[ -z "$build_id" ]]; then
    portfol_error "Usage: portfol show <build_id>"
    return 1
  fi

  if [[ ! -f "$BUILDS_FILE" ]]; then
    portfol_error "No builds logged yet."
    return 1
  fi

  local entry=$(grep "\"$build_id\"" "$BUILDS_FILE" | head -1)

  if [[ -z "$entry" ]]; then
    portfol_error "Build not found: $build_id"
    return 1
  fi

  portfol_header "Build: $build_id"
  echo "$entry" | jq '.'

  # Show generated outputs if they exist
  local has_outputs=false
  for dir in linkedin-posts resume-bullets upwork-gigs; do
    local outfile="$OUTPUTS_DIR/$dir/${build_id}.md"
    if [[ -f "$outfile" ]]; then
      if ! $has_outputs; then
        echo ""
        echo -e "  ${BOLD}Generated Content:${RESET}"
        has_outputs=true
      fi
      portfol_success "$dir → $outfile"
    fi
  done

  if ! $has_outputs; then
    echo ""
    echo -e "  ${DIM}No content generated yet. Run: portfol generate resume-bullet --build $build_id${RESET}"
  fi
}
