# cw — 대기 중인 claude 세션으로 빠르게 이동 (waiting-first).
# 상태 저장소: tmux pane 옵션 @cc_state/@cc_since (cc-attention.sh 훅이 기록).

# _cw_rows: stdin(state|since|target|path|pane_id) → stdout(key\t표시\ttarget), waiting-first 정렬.
_cw_rows() {
  awk -F'|' -v now="$(date +%s)" -v idle_secs=$(( ${CW_IDLE_MINS:-30} * 60 )) '
    $1=="" { next }
    {
      state=$1; since=$2; target=$3; path=$4
      if (state=="waiting" && since!="" && (now-since) > idle_secs) state="idle"
      key=(state=="waiting")?0:(state=="running")?1:2
      sym=(state=="waiting")?"🔴":(state=="running")?"🟢":"⚪"
      n=split(path,a,"/"); repo=a[n]
      printf "%d\t%s %-20s %s\t%s\n", key, sym, repo, target, target
    }' | sort -n -k1,1
}

# _cw_wid_for_session <sess>: stdin=aerospace 'wid|app|title' 줄 → 제목에서 추출한 세션명이
# 인자와 일치하는 Ghostty 창의 window-id 출력. 제목이 깨끗한 "work" 이든 verbose
# "work:9:.. - .." 이든, 🔔 등 접두사가 붙든, 앞부분 세션명을 뽑아 비교. 없으면 빈 출력.
_cw_wid_for_session() {
  awk -F'|' -v s="$1" '
    $2=="Ghostty" {
      t=$3
      sub(/^[^A-Za-z0-9_]+/, "", t)   # 선두 🔔·공백 등 제거
      sub(/[: ].*$/, "", t)           # 첫 ":" 또는 공백부터 끝까지 제거 → 세션명
      if (t==s) { print $1; exit }
    }'
}

# _cc_goto <target>: target(session:window.pane)으로 이동.
# tmux 밖=attach, 같은 세션=tmux 전환, 다른 세션=aerospace 창 focus
# (그 세션의 ghostty 창이 없으면=detached → 새 ghostty 창에서 attach; 현재 창은 유지).
# cw·cj 공유 이동 프리미티브. 빈 target이면 no-op.
_cc_goto() {
  local target="$1"
  [ -n "$target" ] || return

  # tmux 밖에서 실행 → 그냥 attach
  if [ -z "$TMUX" ]; then tmux attach -t "$target"; return; fi

  local sess="${target%%:*}" win="${target%.*}"
  local cur; cur="$(tmux display -p '#{session_name}' 2>/dev/null)"

  # 대상 세션의 활성 window/pane 설정 (해당 ghostty 창이 대상을 보여주도록)
  tmux select-window -t "$win" 2>/dev/null
  tmux select-pane -t "$target" 2>/dev/null

  # 같은 세션(=같은 ghostty 창) → tmux 전환으로 충분
  [ "$sess" = "$cur" ] && return

  # 다른 세션 → 그 세션을 보여주는 ghostty 창을 aerospace 로 포커스 (현재 창은 후면 유지)
  local wid
  wid=$(aerospace list-windows --all --format '%{window-id}|%{app-name}|%{window-title}' 2>/dev/null | _cw_wid_for_session "$sess")
  if [ -n "$wid" ]; then
    aerospace focus --window-id "$wid" 2>/dev/null
  else
    # 열린 창 없음(detached 세션 등) → 새 ghostty 창에서 attach.
    # switch-client 는 현재 창을 대상 세션으로 덮어써(치환) '현재 창 유지' 원칙을 위반하므로 금지.
    open -na Ghostty --args -e tmux attach -t "$sess"
  fi
}

# cw: 대기 중인 claude 세션 조회 → fzf → 이동. 자기 pane(지금 보고 있는 것)은 제외.
cw() {
  local sel target self="$TMUX_PANE"
  sel=$(tmux list-panes -a -F '#{@cc_state}|#{@cc_since}|#{session_name}:#{window_index}.#{pane_index}|#{pane_current_path}|#{pane_id}' 2>/dev/null \
        | awk -F'|' -v self="$self" '$5!=self' \
        | _cw_rows \
        | fzf --ansi --delimiter=$'\t' --with-nth=2 \
              --header='🔴 대기 / 🟢 작업 / ⚪ idle │ Enter=이동' --reverse) || return
  target="${sel##*$'\t'}"
  _cc_goto "$target"
}

# _cwq_dismiss: quick terminal 을 닫는다. Ghostty 1.3.x 는 quick terminal 제어 IPC 가 없고
# autohide 가 aerospace focus 에는 걸리지 않으므로, 전역 토글 키(cmd+alt+t=key code 17)를
# osascript 로 합성한다. 합성 키가 불안정하면 hammerspoon 으로 교체(이 함수만 바꾸면 됨).
_cwq_dismiss() {
  osascript -e 'tell application "System Events" to key code 17 using {command down, option down}' 2>/dev/null
}

# _cwq_jump <target> (session:window.pane): quick terminal 전용 점프.
# _cc_goto 와 달리 attach·cur비교 없이 항상 select → dismiss → focus.
# 대상 세션의 ghostty 창이 있으면 aerospace focus, 없으면(detached) 새 ghostty 창에서 attach.
_cwq_jump() {
  local target="$1"
  [ -n "$target" ] || return
  local sess="${target%%:*}" win="${target%.*}"

  # 대상 세션의 활성 window/pane 설정 (attach 불필요, 서버측에서 동작)
  tmux select-window -t "$win" 2>/dev/null
  tmux select-pane -t "$target" 2>/dev/null

  # quick terminal 닫기 (aerospace focus 전에 오버레이를 걷어냄)
  _cwq_dismiss

  # 대상 세션의 ghostty 창을 aerospace 로 focus
  local wid
  wid=$(aerospace list-windows --all --format '%{window-id}|%{app-name}|%{window-title}' 2>/dev/null | _cw_wid_for_session "$sess")
  if [ -n "$wid" ]; then
    aerospace focus --window-id "$wid" 2>/dev/null
  else
    # 열린 창 없음(detached) → 새 ghostty 창에서 attach
    open -na Ghostty --args -e tmux attach -t "$sess"
  fi
}
