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

# cw: 조회 → fzf → 이동. 자기 pane(지금 보고 있는 것)은 제외.
cw() {
  local sel target self="$TMUX_PANE"
  sel=$(tmux list-panes -a -F '#{@cc_state}|#{@cc_since}|#{session_name}:#{window_index}.#{pane_index}|#{pane_current_path}|#{pane_id}' 2>/dev/null \
        | awk -F'|' -v self="$self" '$5!=self' \
        | _cw_rows \
        | fzf --ansi --delimiter=$'\t' --with-nth=2 \
              --header='🔴 대기 / 🟢 작업 / ⚪ idle │ Enter=이동' --reverse) || return
  target="${sel##*$'\t'}"
  [ -n "$target" ] || return
  if [ -n "$TMUX" ]; then tmux switch-client -t "$target"; else tmux attach -t "$target"; fi
}
