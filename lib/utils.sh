#!/usr/bin/env bash
# utils.sh — Shared helpers for portfol CLI

# ── Colors ──────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ── Paths ───────────────────────────────────────
PORTFOL_DIR="$HOME/.portfol"
BUILDS_FILE="$PORTFOL_DIR/builds.jsonl"
CONFIG_FILE="$PORTFOL_DIR/config.json"
OUTPUTS_DIR="$PORTFOL_DIR/outputs"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

# ── Helpers ─────────────────────────────────────
portfol_print() {
  local color="$1"; shift
  echo -e "${color}${*}${RESET}"
}

portfol_header() {
  echo ""
  echo -e "${CYAN}╭─────────────────────────────────────────────────╮${RESET}"
  echo -e "${CYAN}│${RESET}  ${BOLD}$1${RESET}"
  echo -e "${CYAN}╰─────────────────────────────────────────────────╯${RESET}"
  echo ""
}

portfol_success() {
  echo -e "  ${GREEN}✓${RESET} $1"
}

portfol_warn() {
  echo -e "  ${YELLOW}⚠${RESET} $1"
}

portfol_error() {
  echo -e "  ${RED}✗${RESET} $1" >&2
}

# Generate a build ID: b_YYYYMMDD_NNN
generate_build_id() {
  local today=$(date +%Y%m%d)
  local count=1
  if [[ -f "$BUILDS_FILE" ]]; then
    local today_count=$(grep -c "\"b_${today}_" "$BUILDS_FILE" 2>/dev/null || echo 0)
    count=$((today_count + 1))
  fi
  printf "b_%s_%03d" "$today" "$count"
}

# Load config value
config_get() {
  local key="$1"
  if [[ -f "$CONFIG_FILE" ]]; then
    jq -r ".$key // empty" "$CONFIG_FILE"
  fi
}

# Check dependencies
check_deps() {
  local missing=()
  command -v jq &>/dev/null || missing+=("jq")
  command -v claude &>/dev/null || missing+=("claude")

  if [[ ${#missing[@]} -gt 0 ]]; then
    portfol_error "Missing dependencies: ${missing[*]}"
    portfol_error "Install with: brew install ${missing[*]}"
    return 1
  fi
}

# Ensure data directories exist
ensure_dirs() {
  mkdir -p "$PORTFOL_DIR" \
    "$OUTPUTS_DIR/linkedin-posts" \
    "$OUTPUTS_DIR/resume-bullets" \
    "$OUTPUTS_DIR/upwork-gigs" \
    "$OUTPUTS_DIR/reverse-projects" \
    "$PORTFOL_DIR/job-descriptions"
  touch "$BUILDS_FILE"
}
