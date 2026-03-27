#!/usr/bin/env bash
# ============================================================================
# utils.sh — Shared helpers for the portfol CLI
# ============================================================================
#
# PURPOSE:
#   This file is the "toolbox" that every other portfol script imports.
#   It defines colors, file paths, and small utility functions that get
#   reused everywhere. By keeping them here, we follow the DRY principle
#   (Don't Repeat Yourself) — if we need to change a path or a color,
#   we change it in ONE place.
#
# HOW IT GETS LOADED:
#   Every script does `source "$SCRIPT_DIR/lib/utils.sh"` near the top.
#   `source` (or `.`) runs this file in the CURRENT shell, so all the
#   variables and functions defined here become available to the caller.
#   This is different from running a script with `bash script.sh`, which
#   would create a NEW shell (subprocess) where the variables would die.
#
# ============================================================================


# ── ANSI Color Codes ────────────────────────────────────────────────────────
#
# These are "escape sequences" that tell the terminal to change text color.
# '\033[' starts the escape, then a number picks the style, and 'm' ends it.
#
# HOW THEY WORK:
#   echo -e "${RED}this is red${RESET}"
#   - The -e flag tells echo to interpret escape sequences
#   - ${RED} starts red coloring
#   - ${RESET} turns off all coloring (back to default)
#
# WHY WE USE THEM:
#   Colored output makes the CLI feel polished and scannable.
#   Green ✓ = success, Red ✗ = error, Yellow ⚠ = warning — universal signals.
#
RED='\033[0;31m'       # Errors, failures
GREEN='\033[0;32m'     # Success messages, checkmarks
YELLOW='\033[0;33m'    # Warnings, things to note
CYAN='\033[0;36m'      # Highlights, build IDs, emphasis
MAGENTA='\033[0;35m'   # Accent color (used sparingly)
BOLD='\033[1m'         # Bold text for headers and titles
DIM='\033[2m'          # Dimmed text for hints and secondary info
RESET='\033[0m'        # Turns off ALL formatting — always end with this!


# ── File Paths ──────────────────────────────────────────────────────────────
#
# ARCHITECTURE NOTE — Two separate locations:
#
# 1. REPO (~/Developer/portfol/) — the CODE lives here
#    - This is what's on GitHub, version-controlled
#    - Contains: scripts, templates, config examples
#
# 2. USER DATA (~/.portfol/) — YOUR DATA lives here
#    - This is private, NOT on GitHub (in .gitignore)
#    - Contains: your builds.jsonl, generated outputs, your config.json
#
# WHY SEPARATE?
#   - You can `git push` without exposing personal data
#   - You can reinstall/update the tool without losing your builds
#   - It follows the XDG convention (code vs. user data separation)
#
PORTFOL_DIR="$HOME/.portfol"                 # Root of your personal data
BUILDS_FILE="$PORTFOL_DIR/builds.jsonl"       # The master build log (one JSON per line)
CONFIG_FILE="$PORTFOL_DIR/config.json"        # Your profile, tone, target roles
OUTPUTS_DIR="$PORTFOL_DIR/outputs"            # Where generated content lands
#
# SCRIPT_DIR figures out where THIS script lives on disk, then goes up one
# level to the repo root. This lets the tool work no matter where you call
# it from. Here's how each piece works:
#
#   ${BASH_SOURCE[0]}  → the file path of THIS script (utils.sh)
#   dirname            → strips the filename, gives us the directory (lib/)
#   cd ... && pwd      → resolves any symlinks and gives an absolute path
#   /..                → goes up one level from lib/ to the repo root
#
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"         # Prompt templates for AI generation


# ── Display Helpers ─────────────────────────────────────────────────────────
#
# These functions standardize how portfol talks to you in the terminal.
# Using consistent formatting makes the tool feel professional and
# makes output scannable at a glance.
#

# portfol_print — Print text in any color
# Usage: portfol_print "$CYAN" "Hello world"
#
# The `shift` command is like popping from a stack:
#   Before shift: $1="$CYAN"  $2="Hello"  $3="world"
#   After shift:  $1="Hello"  $2="world"
#   $* grabs all remaining args as one string: "Hello world"
#
portfol_print() {
  local color="$1"; shift  # Grab first arg (color), then shift it off
  echo -e "${color}${*}${RESET}"
}

# portfol_header — Print a boxed section header
# Usage: portfol_header "Your Builds"
# Output:
#   ╭─────────────────────────────────────────────────╮
#   │  Your Builds
#   ╰─────────────────────────────────────────────────╯
#
# The Unicode box-drawing characters (╭╮╰╯│─) create
# a visual container. These work in most modern terminals.
#
portfol_header() {
  echo ""
  echo -e "${CYAN}╭─────────────────────────────────────────────────╮${RESET}"
  echo -e "${CYAN}│${RESET}  ${BOLD}$1${RESET}"
  echo -e "${CYAN}╰─────────────────────────────────────────────────╯${RESET}"
  echo ""
}

# portfol_success — Green checkmark + message
# Usage: portfol_success "Config saved"
# Output:   ✓ Config saved
portfol_success() {
  echo -e "  ${GREEN}✓${RESET} $1"
}

# portfol_warn — Yellow warning + message
# Usage: portfol_warn "Config already exists"
# Output:   ⚠ Config already exists
portfol_warn() {
  echo -e "  ${YELLOW}⚠${RESET} $1"
}

# portfol_error — Red X + message, sent to stderr
# Usage: portfol_error "File not found"
# Output:   ✗ File not found
#
# NOTE: >&2 redirects to stderr (file descriptor 2).
# This matters because errors should go to stderr, not stdout.
# Why? If someone pipes portfol output (portfol list | grep algo),
# errors won't pollute the piped data.
#
portfol_error() {
  echo -e "  ${RED}✗${RESET} $1" >&2
}


# ── Build ID Generator ─────────────────────────────────────────────────────
#
# Creates unique IDs like: b_20260326_001, b_20260326_002, etc.
#
# FORMAT: b_YYYYMMDD_NNN
#   b_         → prefix (easy to grep for)
#   YYYYMMDD   → date (for chronological sorting)
#   NNN        → zero-padded counter (allows 999 builds per day)
#
# HOW IT COUNTS:
#   1. Gets today's date as YYYYMMDD
#   2. Searches builds.jsonl for any entries with today's date
#   3. Counts how many there are (grep -c)
#   4. Adds 1 to get the next number
#
# WHY GREP, NOT JQ?
#   grep -c is much faster than jq for simple counting.
#   On a file with 1000 entries, grep takes ~1ms, jq takes ~50ms.
#   For a CLI tool that should feel instant, this matters.
#
generate_build_id() {
  local today=$(date +%Y%m%d)
  local count=1

  # -f checks if file exists, -s checks if it has content (size > 0)
  if [[ -f "$BUILDS_FILE" && -s "$BUILDS_FILE" ]]; then
    local today_count
    # grep -c returns the COUNT of matching lines
    # The `|| today_count=0` handles the case where grep finds NO matches
    # (grep returns exit code 1 when nothing matches, which would crash
    # our script because of `set -e` in the main dispatcher)
    today_count=$(grep -c "b_${today}_" "$BUILDS_FILE" 2>/dev/null) || today_count=0
    count=$((today_count + 1))
  fi

  # printf pads the number with zeros: 1 → 001, 12 → 012, 123 → 123
  # %03d means: print as decimal (d), at least 3 digits wide, pad with 0s
  printf "b_%s_%03d" "$today" "$count"
}


# ── Config Reader ───────────────────────────────────────────────────────────
#
# Reads a value from your ~/.portfol/config.json file.
#
# Usage: config_get "name"          → "Ali Ahmed"
#        config_get "target_roles"  → ["AI Automation Consultant", ...]
#
# HOW IT WORKS:
#   jq is a command-line JSON processor (like grep but for JSON).
#   -r means "raw output" (no quotes around strings).
#   ".$key" navigates into the JSON: .name → the "name" field
#   "// empty" means "if the key doesn't exist, return nothing"
#   (without this, jq would return "null" as a string)
#
config_get() {
  local key="$1"
  if [[ -f "$CONFIG_FILE" ]]; then
    jq -r ".$key // empty" "$CONFIG_FILE"
  fi
}


# ── Dependency Checker ──────────────────────────────────────────────────────
#
# Verifies that required tools are installed before running.
#
# HOW IT WORKS:
#   `command -v <tool>` checks if a command exists in your PATH.
#   It's more reliable than `which` (which behaves differently on some systems).
#   &>/dev/null silences the output — we only care about the exit code.
#
#   The () around missing creates a BASH ARRAY — like a list in Python.
#   += appends to the array. ${#missing[@]} gives the array length.
#   ${missing[*]} expands the array to a space-separated string.
#
check_deps() {
  local missing=()    # Start with an empty array
  command -v jq &>/dev/null || missing+=("jq")
  command -v claude &>/dev/null || missing+=("claude")

  if [[ ${#missing[@]} -gt 0 ]]; then    # If array has any items
    portfol_error "Missing dependencies: ${missing[*]}"
    portfol_error "Install with: brew install ${missing[*]}"
    return 1    # Non-zero return = failure (like raising an exception)
  fi
}


# ── Directory Bootstrapper ──────────────────────────────────────────────────
#
# Creates all the data directories if they don't exist yet.
# Called at the start of every portfol command (in the main dispatcher).
#
# mkdir -p is "make directory, including parents":
#   mkdir -p a/b/c creates 'a', then 'a/b', then 'a/b/c'
#   If any already exist, it silently skips them (no error).
#
# touch creates a file if it doesn't exist, or updates its timestamp if it does.
# We touch builds.jsonl so that other commands can safely check its size
# without worrying about "file not found" errors.
#
ensure_dirs() {
  mkdir -p "$PORTFOL_DIR" \
    "$OUTPUTS_DIR/linkedin-posts" \
    "$OUTPUTS_DIR/resume-bullets" \
    "$OUTPUTS_DIR/upwork-gigs" \
    "$OUTPUTS_DIR/reverse-projects" \
    "$PORTFOL_DIR/job-descriptions"
  touch "$BUILDS_FILE"
}
