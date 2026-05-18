#!/usr/bin/env bash
# lib.sh — shared helpers for cc-orchestra scripts

REGISTRY_DIR="${HOME}/.cc-orchestra"

# Ensure registry directory exists
cc_init_registry() {
  mkdir -p "$REGISTRY_DIR"
}

# Returns path to task env file
cc_env_file() {
  local task="$1"
  echo "${REGISTRY_DIR}/${task}.env"
}

# Save a pane registration: cc_save_pane <task> <proj> <pane_id> <path>
cc_save_pane() {
  local task="$1" proj="$2" pane_id="$3" path="$4"
  local env_file
  env_file=$(cc_env_file "$task")
  local key
  key="PANE_$(echo "$proj" | tr '[:lower:]-' '[:upper:]_')"
  # Write or update the key in env file
  if grep -q "^${key}=" "$env_file" 2>/dev/null; then
    sed -i '' "s|^${key}=.*|${key}=${pane_id}|" "$env_file"
  else
    echo "${key}=${pane_id}" >> "$env_file"
  fi
  # Also record path for reference
  local path_key="PATH_$(echo "$proj" | tr '[:lower:]-' '[:upper:]_')"
  if grep -q "^${path_key}=" "$env_file" 2>/dev/null; then
    sed -i '' "s|^${path_key}=.*|${path_key}=${path}|" "$env_file"
  else
    echo "${path_key}=${path}" >> "$env_file"
  fi
}

# Get pane ID for a project: cc_get_pane <task> <proj>
cc_get_pane() {
  local task="$1" proj="$2"
  local env_file
  env_file=$(cc_env_file "$task")
  local key
  key="PANE_$(echo "$proj" | tr '[:lower:]-' '[:upper:]_')"
  if [[ ! -f "$env_file" ]]; then
    echo "cc-orchestra: no env file for task '${task}'" >&2
    return 1
  fi
  local pane_id
  pane_id=$(grep "^${key}=" "$env_file" | cut -d= -f2)
  if [[ -z "$pane_id" ]]; then
    echo "cc-orchestra: project '${proj}' not found in task '${task}'" >&2
    return 1
  fi
  echo "$pane_id"
}

# Remove a pane entry: cc_remove_pane <task> <proj>
cc_remove_pane() {
  local task="$1" proj="$2"
  local env_file
  env_file=$(cc_env_file "$task")
  local key
  key="PANE_$(echo "$proj" | tr '[:lower:]-' '[:upper:]_')"
  local path_key="PATH_$(echo "$proj" | tr '[:lower:]-' '[:upper:]_')"
  sed -i '' "/^${key}=/d" "$env_file" 2>/dev/null
  sed -i '' "/^${path_key}=/d" "$env_file" 2>/dev/null
}

# Save scope metadata: cc_save_scope <task> <scope> [tmux_target]
cc_save_scope() {
  local task="$1" scope="$2" target="${3:-}"
  local env_file
  env_file=$(cc_env_file "$task")
  {
    echo "CC_SCOPE=${scope}"
    echo "CC_TMUX_TARGET=${target}"
    echo "CC_CREATED=$(date '+%Y-%m-%dT%H:%M:%S')"
  } >> "$env_file"
}

# Get scope: cc_get_scope <task>
cc_get_scope() {
  local task="$1"
  local env_file
  env_file=$(cc_env_file "$task")
  grep "^CC_SCOPE=" "$env_file" 2>/dev/null | cut -d= -f2
}

# Check if a pane is alive
cc_pane_alive() {
  local pane_id="$1"
  tmux display-message -t "$pane_id" -p '#{pane_id}' 2>/dev/null | grep -q "^${pane_id}$"
}

# Enable pipe-pane logging for a pane
cc_enable_logging() {
  local pane_id="$1" task="$2" proj="$3"
  local logfile="/tmp/cc-${task}-${proj}.log"
  tmux pipe-pane -t "$pane_id" -o "cat >> ${logfile}"
  echo "  → logging to ${logfile}"
}

# Print info message (to stderr so it doesn't interfere with return values)
cc_info() { echo "cc-orchestra: $*" >&2; }
cc_error() { echo "cc-orchestra ERROR: $*" >&2; }
