#!/usr/bin/env bash
# cc-add.sh <proj> <path>
# Auto-resolves active task from current tmux session, then delegates to add.sh.
# Intended primary entrypoint for Claude Code's Bash tool inside the main pane.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat >&2 << 'USAGE'
Usage: cc-add.sh <proj> <path>

  <proj>  New project name
  <path>  Absolute path to project directory

Example:
  cc-add.sh thomas ~/git/kt4u/thomas
USAGE
  exit 1
}

[[ $# -ne 2 ]] && usage

TASK=$("${SCRIPT_DIR}/active-task.sh") || exit 1
exec "${SCRIPT_DIR}/add.sh" "$TASK" "$@"
