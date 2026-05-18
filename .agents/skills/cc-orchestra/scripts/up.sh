#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat >&2 << 'USAGE'
Usage: up.sh [--window] <task> <main-proj> <main-path> [<sub-proj> <sub-path> ...]

  --window    Use a new window in current session instead of a new session
  <task>      Unique task name (e.g. isms184)
  <main-proj> Primary project name (e.g. enc-mask)
  <main-path> Absolute path to main project
  Remaining pairs: sub-project name + path

Examples:
  up.sh isms184 enc-mask ~/git/kt4u/enc-mask pacman ~/git/kt4u/pacman
  up.sh --window isms184 enc-mask ~/git/kt4u/enc-mask thomas ~/git/kt4u/thomas
USAGE
  exit 1
}

# --- Argument parsing ---
# Scope precedence: CLI flag > CC_ORCHESTRA_SCOPE env var > default (session)
SCOPE="${CC_ORCHESTRA_SCOPE:-session}"
if [[ "${1:-}" == "--window" ]]; then
  SCOPE="window"
  shift
elif [[ "${1:-}" == "--session" ]]; then
  SCOPE="session"
  shift
fi

[[ $# -lt 3 ]] && usage
TASK="$1"; shift
MAIN_PROJ="$1"; shift
MAIN_PATH="$1"; shift

# Collect sub-project pairs
declare -a SUB_PROJS=()
declare -a SUB_PATHS=()
while [[ $# -ge 2 ]]; do
  SUB_PROJS+=("$1")
  SUB_PATHS+=("$2")
  shift 2
done
[[ $# -ne 0 ]] && { cc_error "sub-project args must be pairs (name path)"; exit 1; }

# --- Validate paths ---
if [[ ! -d "$MAIN_PATH" ]]; then
  cc_error "main path does not exist: ${MAIN_PATH}"
  exit 1
fi
for path in "${SUB_PATHS[@]:-}"; do
  if [[ -n "$path" && ! -d "$path" ]]; then
    cc_error "sub path does not exist: ${path}"
    exit 1
  fi
done

cc_init_registry
ENV_FILE=$(cc_env_file "$TASK")

# Warn if task already exists
if [[ -f "$ENV_FILE" ]]; then
  cc_info "task '${TASK}' env already exists. Remove with: ccdown ${TASK}"
  exit 1
fi

# --- Create tmux target ---
if [[ "$SCOPE" == "session" ]]; then
  if tmux has-session -t "$TASK" 2>/dev/null; then
    cc_error "tmux session '${TASK}' already exists"
    exit 1
  fi
  # Create new session (detached), starting in main project dir
  tmux new-session -d -s "$TASK" -c "$MAIN_PATH" -x 220 -y 50
  TMUX_TARGET="${TASK}"
  cc_info "created session: ${TASK}"
else
  # Window mode: use current session
  CURRENT_SESSION=$(tmux display-message -p '#S' 2>/dev/null || echo "")
  if [[ -z "$CURRENT_SESSION" ]]; then
    cc_error "no active tmux session for --window mode"
    exit 1
  fi
  WIN=$(tmux new-window -t "$CURRENT_SESSION" -c "$MAIN_PATH" -n "$TASK" -P -F '#{window_index}')
  TMUX_TARGET="${CURRENT_SESSION}:${WIN}"
  cc_info "created window: ${TASK} in session ${CURRENT_SESSION}"
fi

# --- Capture main pane ID ---
MAIN_PANE=$(tmux display-message -t "${TMUX_TARGET}" -p '#{pane_id}')
cc_info "main pane: ${MAIN_PROJ} → ${MAIN_PANE}"

# Save scope + main pane
cc_save_scope "$TASK" "$SCOPE" "$TMUX_TARGET"
cc_save_pane "$TASK" "$MAIN_PROJ" "$MAIN_PANE" "$MAIN_PATH"
cc_enable_logging "$MAIN_PANE" "$TASK" "$MAIN_PROJ"

# --- Create sub-project panes (right side) ---
for i in "${!SUB_PROJS[@]}"; do
  PROJ="${SUB_PROJS[$i]}"
  PATH_="${SUB_PATHS[$i]}"
  # Split vertically on right side (first split: horizontal, rest: vertical)
  if [[ $i -eq 0 ]]; then
    PANE=$(tmux split-window -h -t "${TMUX_TARGET}" -c "$PATH_" -P -F '#{pane_id}')
  else
    # Stack below the previous right pane
    PANE=$(tmux split-window -v -t "${TMUX_TARGET}" -c "$PATH_" -P -F '#{pane_id}')
  fi
  cc_info "sub pane: ${PROJ} → ${PANE}"
  cc_save_pane "$TASK" "$PROJ" "$PANE" "$PATH_"
  cc_enable_logging "$PANE" "$TASK" "$PROJ"
done

# --- Apply main-vertical layout ---
tmux select-layout -t "${TMUX_TARGET}" main-vertical
tmux set-window-option -t "${TMUX_TARGET}" main-pane-width "65%"

# --- Launch claude in each pane ---
tmux send-keys -t "$MAIN_PANE" "claude" Enter
for i in "${!SUB_PROJS[@]}"; do
  PANE=$(cc_get_pane "$TASK" "${SUB_PROJS[$i]}")
  tmux send-keys -t "$PANE" "claude" Enter
done

# --- Focus main pane ---
tmux select-pane -t "$MAIN_PANE"

# --- Check main project's CLAUDE.md for Auto-Dispatch section ---
MAIN_CLAUDE_MD="${MAIN_PATH}/CLAUDE.md"
TEMPLATE_PATH="${HOME}/.claude/skills/cc-orchestra/templates/auto-dispatch.md"
if [[ -f "$MAIN_CLAUDE_MD" ]]; then
  if ! grep -q "Auto-Dispatch" "$MAIN_CLAUDE_MD"; then
    SIBLING_LIST=""
    if [[ ${#SUB_PROJS[@]} -gt 0 ]]; then
      SIBLING_LIST=$(IFS=,; echo "${SUB_PROJS[*]}")
      SIBLING_LIST="${SIBLING_LIST//,/, }"
    fi
    cc_info ""
    cc_info "ℹ️  ${MAIN_PROJ}/CLAUDE.md 에 Auto-Dispatch 섹션이 없습니다."
    cc_info "    메인 pane CC 가 자동 dispatch 룰을 인지하려면 다음 템플릿을 참조해 추가하세요:"
    cc_info "    ${TEMPLATE_PATH}"
    if [[ -n "$SIBLING_LIST" ]]; then
      cc_info "    현재 task 의 sibling: ${SIBLING_LIST}"
    fi
    cc_info ""
  fi
elif [[ -d "$MAIN_PATH" ]]; then
  cc_info ""
  cc_info "ℹ️  ${MAIN_PROJ}/CLAUDE.md 가 없습니다. 메인 CC 동작 룰 명시를 위해 생성을 고려하세요."
  cc_info "    템플릿: ${TEMPLATE_PATH}"
  cc_info ""
fi

# --- Done ---
cc_info "orchestra up: task=${TASK} scope=${SCOPE} projs=${MAIN_PROJ}$(printf ' %s' "${SUB_PROJS[@]:-}")"
if [[ "$SCOPE" == "session" ]]; then
  echo "Attach with: tmux attach-session -t ${TASK}"
fi
