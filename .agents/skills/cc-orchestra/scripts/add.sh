#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat >&2 << 'USAGE'
Usage: add.sh <task> <proj> <path>

  <task>  Task name
  <proj>  New project name
  <path>  Absolute path to project
USAGE
  exit 1
}

[[ $# -ne 3 ]] && usage
TASK="$1" PROJ="$2" PATH_="$3"

ENV_FILE=$(cc_env_file "$TASK")
[[ ! -f "$ENV_FILE" ]] && { cc_error "task '${TASK}' not found"; exit 1; }
[[ ! -d "$PATH_" ]] && { cc_error "path does not exist: ${PATH_}"; exit 1; }

# Duplicate check
existing=$(cc_get_pane "$TASK" "$PROJ" 2>/dev/null || echo "")
if [[ -n "$existing" ]]; then
  cc_error "project '${PROJ}' already registered in task '${TASK}' (pane: ${existing})"
  exit 1
fi

TMUX_TARGET=$(grep "^CC_TMUX_TARGET=" "$ENV_FILE" | cut -d= -f2)
[[ -z "$TMUX_TARGET" ]] && { cc_error "CC_TMUX_TARGET not set in env file"; exit 1; }

# Split a new pane on the right side (vertical stack)
PANE=$(tmux split-window -v -t "${TMUX_TARGET}" -c "$PATH_" -P -F '#{pane_id}')
cc_save_pane "$TASK" "$PROJ" "$PANE" "$PATH_"
cc_enable_logging "$PANE" "$TASK" "$PROJ"

# Re-apply layout
tmux select-layout -t "${TMUX_TARGET}" main-vertical
tmux set-window-option -t "${TMUX_TARGET}" main-pane-width "65%"

# Launch claude
tmux send-keys -t "$PANE" "claude" Enter

cc_info "added: ${PROJ} → ${PANE}"
