#!/usr/bin/env bash
# Print active cc-orchestra task matching current tmux session.
# Exit 0 with task name on stdout if exactly one match.
# Exit 1 with diagnostic on stderr otherwise.
set -euo pipefail

if [[ -z "${TMUX:-}" ]]; then
  echo "active-task: not inside tmux" >&2
  exit 1
fi

SESSION=$(tmux display-message -p '#S')
REG_DIR="${HOME}/.cc-orchestra"

# CC_TMUX_TARGET is "<session>" for session mode, "<session>:<window>" for window mode.
# Match prefix-anchored to session name.
matches=()
for f in "$REG_DIR"/*.env; do
  [[ -f "$f" ]] || continue
  target=$(grep "^CC_TMUX_TARGET=" "$f" | cut -d= -f2)
  if [[ "$target" == "$SESSION" || "$target" == "${SESSION}:"* ]]; then
    matches+=("$(basename "$f" .env)")
  fi
done

case ${#matches[@]} in
  0) echo "active-task: no task matches tmux session '${SESSION}'" >&2; exit 1 ;;
  1) echo "${matches[0]}" ;;
  *) echo "active-task: multiple matches: ${matches[*]}" >&2; exit 1 ;;
esac
