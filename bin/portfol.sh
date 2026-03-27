#!/usr/bin/env bash
# ============================================================================
# portfol — Build in public without trying to
# ============================================================================
#
# WHAT THIS FILE IS:
#   The "front door" of the portfol CLI. When you type `portfol <command>`,
#   this script runs. It figures out which command you want, loads the right
#   library file, and calls the right function.
#
# THIS IS CALLED A "DISPATCHER" PATTERN:
#   Instead of putting ALL the code in one huge file, we split each command
#   into its own file (lib/log.sh, lib/list.sh, etc.) and this dispatcher
#   just routes to the right one. Benefits:
#     - Each file is small and focused (easier to understand)
#     - You can work on one command without touching others
#     - New commands = new file + one case statement line here
#
# HOW IT RUNS:
#   1. Your ~/.zshrc has: alias portfol="$HOME/Developer/portfol/bin/portfol.sh"
#   2. You type: portfol log --quick "Built a thing"
#   3. Bash resolves the alias and runs: ~/Developer/portfol/bin/portfol.sh log --quick "Built a thing"
#   4. This script:
#      a. Sources utils.sh (loads colors, paths, helpers)
#      b. Calls ensure_dirs() (makes sure ~/.portfol/ exists)
#      c. Reads $1 ("log") as the command
#      d. Sources lib/log.sh (loads the log functions)
#      e. Calls portfol_log with remaining args ("--quick" "Built a thing")
#
# ============================================================================

# ── Safety Flags ────────────────────────────────────────────────────────────
#
# set -euo pipefail is the "strict mode" for bash scripts.
# It catches bugs early instead of letting them silently cascade.
#
#   -e  → Exit immediately if ANY command fails (non-zero exit code)
#         Without this, bash happily continues after errors, which can
#         cause weird behavior 10 lines later that's hard to debug.
#
#   -u  → Treat unset variables as errors
#         Without this, $TYPO_VAR silently becomes "" (empty string).
#         With this, bash yells "unbound variable" so you catch the typo.
#
#   -o pipefail → If any command in a pipe fails, the whole pipe fails
#         Without this: `failing_cmd | good_cmd` returns success (0)
#         With this: it returns the failure exit code
#
set -euo pipefail

# ── Locate Ourselves ───────────────────────────────────────────────────────
#
# We need to know where the repo lives on disk so we can find lib/ and
# templates/. This line figures that out regardless of WHERE you call
# portfol from (your home dir, a project dir, etc.).
#
# Step by step:
#   ${BASH_SOURCE[0]}  → "/Users/ali/Developer/portfol/bin/portfol.sh"
#   dirname            → "/Users/ali/Developer/portfol/bin"
#   cd ... && pwd      → resolves symlinks to a real absolute path
#   /..                → go up one level: "/Users/ali/Developer/portfol"
#
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load the shared toolbox (colors, paths, helper functions)
# `source` runs utils.sh in THIS shell, so all its variables and functions
# become available here. It's like `import` in Python.
source "$SCRIPT_DIR/lib/utils.sh"

VERSION="0.1.0"

# ── Help Text ──────────────────────────────────────────────────────────────
#
# Displayed when you run `portfol`, `portfol help`, or `portfol --help`.
# Uses the color variables from utils.sh to make it scannable.
#
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

# ── Main Dispatcher ────────────────────────────────────────────────────────
#
# This is the core routing logic. It uses a `case` statement, which is
# bash's version of a switch/match statement:
#
#   case "$variable" in
#     pattern1) do_something ;;    ← the ;; is like "break"
#     pattern2) do_other ;;
#     *)        default_action ;;  ← * matches anything (catch-all)
#   esac                           ← "case" spelled backwards (closes the block)
#
# LAZY LOADING with `source`:
#   We only load a lib file when its command is actually called.
#   If you run `portfol stats`, we don't waste time loading log.sh.
#   This is called "lazy loading" — load what you need, when you need it.
#
main() {
  # Make sure ~/.portfol/ and its subdirectories exist
  ensure_dirs

  # Grab the first argument as the command name
  # ${1:-} means "use $1, but if it's empty, use empty string instead of crashing"
  # (the :- is called a "default value" — it prevents the -u flag from erroring)
  local cmd="${1:-}"

  # shift removes $1 from the argument list, so $2 becomes $1, $3 becomes $2, etc.
  # This lets us pass "$@" (all remaining args) cleanly to the subcommand.
  # 2>/dev/null suppresses the error if there's nothing to shift.
  # || true prevents set -e from killing us if shift fails.
  shift 2>/dev/null || true

  case "$cmd" in
    log)
      source "$SCRIPT_DIR/lib/log.sh"    # Load the log command
      portfol_log "$@"                   # Run it with remaining args
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
      # Opens config.json in your default editor.
      # ${EDITOR:-nano} means "use $EDITOR if set, otherwise use nano"
      # Most devs set $EDITOR in their shell profile (code, vim, nano, etc.)
      ${EDITOR:-nano} "$CONFIG_FILE"
      ;;
    init)
      portfol_init
      ;;
    version|--version|-v)
      # The | means "or" — matches any of these three patterns
      echo "portfol v${VERSION}"
      ;;
    help|--help|-h|"")
      # "" matches when no command is given (just `portfol` by itself)
      usage
      ;;
    *)
      # Catch-all: anything we don't recognize
      portfol_error "Unknown command: $cmd"
      usage
      exit 1    # Exit with error code (non-zero = failure)
      ;;
  esac
}

# ── First-Time Setup ───────────────────────────────────────────────────────
#
# Run with: portfol init
#
# Copies the example config to ~/.portfol/config.json so you have a
# starting point. The example config has your name, target roles, and
# tone preferences pre-filled (you can edit them with `portfol config`).
#
# The =~ operator is a REGEX MATCH in bash:
#   [[ "$overwrite" =~ ^[Yy]$ ]]
#   This matches: "Y", "y" (and nothing else)
#   ^ = start of string, [Yy] = Y or y, $ = end of string
#
portfol_init() {
  portfol_header "First-Time Setup"

  # Check if config already exists (don't accidentally overwrite)
  if [[ -f "$CONFIG_FILE" ]]; then
    portfol_warn "Config already exists at $CONFIG_FILE"
    read -p "  Overwrite? [y/N]: " overwrite
    [[ "$overwrite" =~ ^[Yy]$ ]] || return 0   # If not y/Y, just return
  fi

  # Copy the template config to the user data directory
  cp "$SCRIPT_DIR/config/config.example.json" "$CONFIG_FILE"
  portfol_success "Config created at $CONFIG_FILE"
  portfol_print "$YELLOW" "  Edit it with: portfol config"
  echo ""
  portfol_success "Data directory ready at $PORTFOL_DIR"
  portfol_success "You're all set! Try: portfol log --quick \"My first build\""
}

# ── Entry Point ────────────────────────────────────────────────────────────
#
# "$@" passes ALL command-line arguments to main(), preserving spaces.
# This is different from $* which can break arguments with spaces.
#
# Example: portfol log --quick "Built a cool thing"
#   "$@" → "log" "--quick" "Built a cool thing"  (3 args, correct)
#   $*   → "log" "--quick" "Built" "a" "cool" "thing"  (6 args, broken!)
#
main "$@"
