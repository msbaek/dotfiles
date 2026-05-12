#!/usr/bin/env bash
# cc-dispatch.sh <proj> "<prompt>"
# Auto-resolves active task from current tmux session, then delegates to send.sh.
# Intended primary entrypoint for Claude Code's Bash tool inside the main pane.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat >&2 << 'USAGE'
Usage: cc-dispatch.sh <proj> <prompt>

  <proj>    Project name (e.g. pacman)
  <prompt>  Prompt text to send to the Claude instance in that pane

Example:
  cc-dispatch.sh pacman "implement delivery ID bulk SSN encryption"
USAGE
  exit 1
}

[[ $# -lt 2 ]] && usage

TASK=$("${SCRIPT_DIR}/active-task.sh") || exit 1
exec "${SCRIPT_DIR}/send.sh" "$TASK" "$@"
