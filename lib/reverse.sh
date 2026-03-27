#!/usr/bin/env bash
# reverse.sh — Reverse-engineer job descriptions into proof projects

portfol_reverse() {
  portfol_header "Reverse Engineering Mode"
  portfol_warn "Coming in Phase 3. This will:"
  echo -e "    ${CYAN}1.${RESET} Read a job description (clipboard, file, or screenshot)"
  echo -e "    ${CYAN}2.${RESET} Match requirements against your logged builds"
  echo -e "    ${CYAN}3.${RESET} Identify skill gaps and suggest projects to fill them"
  echo -e "    ${CYAN}4.${RESET} Generate tailored resume, cover letter, and proposal"
  echo ""
  echo -e "  ${DIM}Usage: portfol reverse [--file path] [--screenshot path]${RESET}"
}
