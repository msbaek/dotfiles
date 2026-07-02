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

# cw: 조회 → fzf → 이동. 자기 pane(지금 보고 있는 것)은 제외.
# 대상이 다른 세션(=다른 ghostty 창)이면 aerospace 로 그 OS 창을 포커스(현재 창은 후면).
cw() {
  local sel target self="$TMUX_PANE"
  sel=$(tmux list-panes -a -F '#{@cc_state}|#{@cc_since}|#{session_name}:#{window_index}.#{pane_index}|#{pane_current_path}|#{pane_id}' 2>/dev/null \
        | awk -F'|' -v self="$self" '$5!=self' \
        | _cw_rows \
        | fzf --ansi --delimiter=$'\t' --with-nth=2 \
              --header='🔴 대기 / 🟢 작업 / ⚪ idle │ Enter=이동' --reverse) || return
  target="${sel##*$'\t'}"
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
    # 열린 창 없음(detached 세션 등) → 현재 창에서 전환 fallback
    tmux switch-client -t "$target" 2>/dev/null
  fi
}
