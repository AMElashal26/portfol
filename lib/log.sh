#!/usr/bin/env bash
# log.sh — Log a new build entry

portfol_log() {
  local quick_mode=false
  local description=""
  local from_git=false

  # Parse args
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --quick|-q)
        quick_mode=true
        shift
        if [[ $# -gt 0 ]]; then
          description="$*"
          break
        fi
        ;;
      --from-git)
        description=$(git log -1 --pretty=%B 2>/dev/null || echo "")
        quick_mode=true
        from_git=true
        shift
        ;;
      *)
        description="$*"
        quick_mode=true
        break
        ;;
    esac
  done

  if $quick_mode && [[ -n "$description" ]]; then
    _log_quick "$description"
  else
    _log_interactive
  fi
}

_log_quick() {
  local description="$1"
  local build_id=$(generate_build_id)
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Auto-detect recently modified files (last 2 hours)
  local recent_files_json="[]"
  local file_list=""
  file_list=$(find "$HOME/Developer" "$HOME/scripts" "$HOME/Claude_ref" \
    -maxdepth 3 -type f \
    -not -path "*/.git/*" \
    -not -path "*/node_modules/*" \
    -not -name ".DS_Store" \
    -not -name ".*" \
    -mmin -120 2>/dev/null | head -10 || true)

  if [[ -n "$file_list" ]]; then
    recent_files_json=$(echo "$file_list" | jq -R . | jq -s .)
  fi

  # Auto-detect skills from file extensions
  local skills=()
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    case "${f##*.}" in
      sh|bash)          skills+=("Shell Scripting") ;;
      py)               skills+=("Python") ;;
      js|ts)            skills+=("JavaScript") ;;
      jsx|tsx)          skills+=("React") ;;
      applescript|scpt) skills+=("AppleScript") ;;
      json)             skills+=("JSON/Data") ;;
      md)               skills+=("Documentation") ;;
    esac
  done <<< "$file_list"

  # Deduplicate skills
  local unique_skills_json="[]"
  if [[ ${#skills[@]} -gt 0 ]]; then
    unique_skills_json=$(printf '%s\n' "${skills[@]}" | sort -u | jq -R . | jq -s .)
  fi

  # Build JSONL entry (compact: one line per entry)
  local entry
  entry=$(jq -cn \
    --arg id "$build_id" \
    --arg ts "$timestamp" \
    --arg desc "$description" \
    --argjson files "$recent_files_json" \
    --argjson skills "$unique_skills_json" \
    '{
      id: $id,
      timestamp: $ts,
      title: $desc,
      description: $desc,
      source_files: $files,
      skills_demonstrated: $skills,
      tags: [],
      status: "active"
    }')

  echo "$entry" >> "$BUILDS_FILE"

  local file_count=$(echo "$recent_files_json" | jq 'length')
  portfol_success "Logged: ${CYAN}${build_id}${RESET}"
  portfol_success "${file_count} recent files detected"
  echo -e "  ${DIM}Run 'portfol show $build_id' to review${RESET}"
}

_log_interactive() {
  portfol_header "Log a New Build"

  read -p "  What did you build? (one line): " description
  if [[ -z "$description" ]]; then
    portfol_error "Description required."
    return 1
  fi

  _log_quick "$description"
}
