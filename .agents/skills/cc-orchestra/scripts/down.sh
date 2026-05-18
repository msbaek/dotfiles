#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

usage() {
  echo "Usage: down.sh <task>" >&2
  exit 1
}

[[ $# -ne 1 ]] && usage
TASK="$1"

ENV_FILE=$(cc_env_file "$TASK")
if [[ ! -f "$ENV_FILE" ]]; then
  cc_error "task '${TASK}' not found"
  exit 1
fi

SCOPE=$(cc_get_scope "$TASK")
TMUX_TARGET=$(grep "^CC_TMUX_TARGET=" "$ENV_FILE" 2>/dev/null | cut -d= -f2)

if [[ "$SCOPE" == "session" ]]; then
  if tmux has-session -t "$TASK" 2>/dev/null; then
    tmux kill-session -t "$TASK"
    cc_info "killed session: ${TASK}"
  else
    cc_info "session '${TASK}' not found (may be already gone)"
  fi
elif [[ "$SCOPE" == "window" ]]; then
  if [[ -n "$TMUX_TARGET" ]] && tmux display-message -t "$TMUX_TARGET" -p '' 2>/dev/null; then
    tmux kill-window -t "$TMUX_TARGET"
    cc_info "killed window: ${TMUX_TARGET}"
  else
    cc_info "window '${TMUX_TARGET}' not found"
  fi
fi

# Clean up env file
rm -f "$ENV_FILE"
cc_info "removed registry: ${ENV_FILE}"
