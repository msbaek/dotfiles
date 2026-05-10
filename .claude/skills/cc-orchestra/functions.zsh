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

# ccdown <task> — tear down task environment
ccdown() {
  [[ $# -ne 1 ]] && { echo "Usage: ccdown <task>" >&2; return 1; }
  "${_CC_SCRIPTS}/down.sh" "$1"
}

# ccadd <proj> <path> — add pane to current task (requires CC_ORCHESTRA_TASK)
ccadd() {
  local task="${CC_ORCHESTRA_TASK:-}"
  [[ -z "$task" ]] && { echo "ccadd: set CC_ORCHESTRA_TASK first" >&2; return 1; }
  [[ $# -ne 2 ]] && { echo "Usage: ccadd <proj> <path>" >&2; return 1; }
  "${_CC_SCRIPTS}/add.sh" "$task" "$@"
}

# ccrm <proj> — remove pane from current task (requires CC_ORCHESTRA_TASK)
ccrm() {
  local task="${CC_ORCHESTRA_TASK:-}"
  [[ -z "$task" ]] && { echo "ccrm: set CC_ORCHESTRA_TASK first" >&2; return 1; }
  [[ $# -ne 1 ]] && { echo "Usage: ccrm <proj>" >&2; return 1; }
  "${_CC_SCRIPTS}/remove.sh" "$task" "$1"
}

# ccup [--window|--session] <task> <main> <main-path> [sub sub-path ...]
# Auto-sets CC_ORCHESTRA_TASK on success
ccup() {
  local scope_flag=""
  if [[ "${1:-}" == "--window" || "${1:-}" == "--session" ]]; then
    scope_flag="$1"
  fi
  local offset=0
  [[ -n "$scope_flag" ]] && offset=1
  local task="${@:$((offset + 1)):1}"
  "${_CC_SCRIPTS}/up.sh" "$@"
  if [[ $? -eq 0 && -n "${task:-}" ]]; then
    export CC_ORCHESTRA_TASK="$task"
    [[ -n "$scope_flag" ]] && export CC_ORCHESTRA_SCOPE="${scope_flag#--}" || true
    echo "cc-orchestra: CC_ORCHESTRA_TASK=${task}"
  fi
}
