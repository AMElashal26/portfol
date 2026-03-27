#!/usr/bin/env bash
# portfol — Build in public without trying to
# Main CLI dispatcher

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"

VERSION="0.1.0"

usage() {
  echo ""
  echo -e "${BOLD}portfol${RESET} v${VERSION} — Build in public without trying to"
  echo ""
  echo -e "${CYAN}USAGE:${RESET}"
  echo "  portfol <command> [options]"
  echo ""
  echo -e "${CYAN}COMMANDS:${RESET}"
  echo -e "  ${GREEN}log${RESET}           Log a new build (interactive)"
  echo -e "  ${GREEN}log --quick${RESET}   Log a build with one-liner description"
  echo -e "  ${GREEN}generate${RESET}      Generate content from a build"
  echo -e "  ${GREEN}reverse${RESET}       Reverse-engineer a job description"
  echo -e "  ${GREEN}list${RESET}          List all logged builds"
  echo -e "  ${GREEN}show${RESET}          Show details of a specific build"
  echo -e "  ${GREEN}stats${RESET}         Portfolio intelligence & analytics"
  echo -e "  ${GREEN}config${RESET}        Edit your profile configuration"
  echo -e "  ${GREEN}init${RESET}          First-time setup wizard"
  echo ""
  echo -e "${CYAN}ALIASES:${RESET} plog (quick log), prev (reverse), pstats (stats)"
  echo ""
}

# ── Main ────────────────────────────────────────
main() {
  ensure_dirs

  local cmd="${1:-}"
  shift 2>/dev/null || true

  case "$cmd" in
    log)
      source "$SCRIPT_DIR/lib/log.sh"
      portfol_log "$@"
      ;;
    generate)
      source "$SCRIPT_DIR/lib/generate.sh"
      portfol_generate "$@"
      ;;
    reverse)
      source "$SCRIPT_DIR/lib/reverse.sh"
      portfol_reverse "$@"
      ;;
    list)
      source "$SCRIPT_DIR/lib/list.sh"
      portfol_list "$@"
      ;;
    show)
      source "$SCRIPT_DIR/lib/show.sh"
      portfol_show "$@"
      ;;
    stats)
      source "$SCRIPT_DIR/lib/stats.sh"
      portfol_stats "$@"
      ;;
    config)
      ${EDITOR:-nano} "$CONFIG_FILE"
      ;;
    init)
      portfol_init
      ;;
    version|--version|-v)
      echo "portfol v${VERSION}"
      ;;
    help|--help|-h|"")
      usage
      ;;
    *)
      portfol_error "Unknown command: $cmd"
      usage
      exit 1
      ;;
  esac
}

portfol_init() {
  portfol_header "First-Time Setup"

  if [[ -f "$CONFIG_FILE" ]]; then
    portfol_warn "Config already exists at $CONFIG_FILE"
    read -p "  Overwrite? [y/N]: " overwrite
    [[ "$overwrite" =~ ^[Yy]$ ]] || return 0
  fi

  cp "$SCRIPT_DIR/config/config.example.json" "$CONFIG_FILE"
  portfol_success "Config created at $CONFIG_FILE"
  portfol_print "$YELLOW" "  Edit it with: portfol config"
  echo ""
  portfol_success "Data directory ready at $PORTFOL_DIR"
  portfol_success "You're all set! Try: portfol log --quick \"My first build\""
}

main "$@"
