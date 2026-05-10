# cc-orchestra zsh wrapper functions
# Source this file in .zshrc:
#   source ~/.claude/skills/cc-orchestra/functions.zsh

# Source guard
[[ -n "${_CC_ORCHESTRA_LOADED:-}" ]] && return
_CC_ORCHESTRA_LOADED=1

_CC_SCRIPTS="${HOME}/.claude/skills/cc-orchestra/scripts"

# ccsend <proj> <prompt...> — dispatch to project pane
ccsend() {
  local task="${CC_ORCHESTRA_TASK:-}"
  [[ -z "$task" ]] && { echo "ccsend: CC_ORCHESTRA_TASK not set. Use: export CC_ORCHESTRA_TASK=<task>" >&2; return 1; }
  [[ $# -lt 2 ]] && { echo "Usage: ccsend <proj> <prompt>" >&2; return 1; }
  "${_CC_SCRIPTS}/send.sh" "$task" "$@"
}

# cclist — show all active tasks and panes
cclist() {
  "${_CC_SCRIPTS}/list.sh" "$@"
}
