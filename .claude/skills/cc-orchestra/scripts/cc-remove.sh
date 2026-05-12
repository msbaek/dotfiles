#!/usr/bin/env bash
# cc-remove.sh <proj>
# Auto-resolves active task from current tmux session, then delegates to remove.sh.
# Intended primary entrypoint for Claude Code's Bash tool inside the main pane.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat >&2 << 'USAGE'
Usage: cc-remove.sh <proj>

  <proj>  Project name to remove from the active task

Example:
  cc-remove.sh thomas
USAGE
  exit 1
}

[[ $# -ne 1 ]] && usage

TASK=$("${SCRIPT_DIR}/active-task.sh") || exit 1
exec "${SCRIPT_DIR}/remove.sh" "$TASK" "$@"
