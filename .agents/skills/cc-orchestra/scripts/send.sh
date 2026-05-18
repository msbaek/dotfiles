#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat >&2 << 'USAGE'
Usage: send.sh <task> <proj> <prompt>

  <task>    Task name (e.g. isms184)
  <proj>    Project name (e.g. pacman)
  <prompt>  Prompt text to send to the Claude instance

Example:
  send.sh isms184 pacman "implement delivery ID bulk SSN encryption"
USAGE
  exit 1
}

[[ $# -lt 3 ]] && usage

TASK="$1"; shift
PROJ="$1"; shift
PROMPT="$*"

PANE=$(cc_get_pane "$TASK" "$PROJ") || exit 1

if ! cc_pane_alive "$PANE"; then
  cc_error "pane ${PANE} for '${PROJ}' is no longer alive"
  exit 1
fi

tmux send-keys -t "$PANE" "$PROMPT" Enter
cc_info "dispatched to ${PROJ} (${PANE})"
