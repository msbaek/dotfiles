#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

usage() {
  echo "Usage: remove.sh <task> <proj>" >&2
  exit 1
}

[[ $# -ne 2 ]] && usage
TASK="$1" PROJ="$2"

PANE=$(cc_get_pane "$TASK" "$PROJ") || exit 1

if cc_pane_alive "$PANE" 2>/dev/null; then
  tmux kill-pane -t "$PANE"
  cc_info "killed pane ${PANE} (${PROJ})"
else
  cc_info "pane ${PANE} already dead, removing from registry"
fi

cc_remove_pane "$TASK" "$PROJ"
cc_info "removed: ${PROJ} from task '${TASK}'"
