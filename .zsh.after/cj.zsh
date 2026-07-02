# cj — 설정된 claude 프로젝트로 이동. 열림→pane 점프, 닫힘→현재 pane 에서 cd.
# 이동 프리미티브 _cc_goto 는 cw.zsh 에 정의(런타임에 호출).

# _cj_match <expanded_path...>: 프로젝트 경로들(위치인자) + tmux 'target|path'(stdin)
#   → 프로젝트당 'state|target|path|name' (state∈open/closed/missing).
#   양쪽 ${:A} 정규화 후 exact 매칭. 같은 경로 여러 pane 이면 tmux 나열 첫 매치.
_cj_match() {
  local -A pane_by_norm
  local target path norm
  while IFS='|' read -r target path; do
    [ -n "$path" ] || continue
    norm="${path:A}"
    [ -n "${pane_by_norm[$norm]}" ] || pane_by_norm[$norm]="$target"
  done

  local p name tgt pnorm
  for p in "$@"; do
    name="${p:t}"
    if [[ ! -d "$p" ]]; then
      print -r -- "missing||$p|$name"
      continue
    fi
    pnorm="${p:A}"
    tgt="${pane_by_norm[$pnorm]}"
    if [ -n "$tgt" ]; then
      print -r -- "open|$tgt|$p|$name"
    else
      print -r -- "closed||$p|$name"
    fi
  done
}

# _cj_rows: stdin 'state|target|path|name' → 'sortkey\tdisplay\tstate\tpayload'.
#   open🟢(0) → closed⚪(1) → missing⚠(2) 정렬. payload=open?target:path.
_cj_rows() {
  awk -F'|' '
    {
      state=$1; target=$2; path=$3; name=$4
      if (state=="open")        { key=0; sym="🟢"; loc="  ("target")" }
      else if (state=="closed") { key=1; sym="⚪"; loc="" }
      else                      { key=2; sym="⚠"; loc="  (missing)" }
      payload=(state=="open")?target:path
      printf "%d\t%s %-26s%s\t%s\t%s\n", key, sym, name, loc, state, payload
    }' | sort -s -n -k1,1
}

# cj [query]: 프로젝트 fzf → 열림이면 그 pane 으로 점프, 닫힘이면 현재 pane 에서 cd.
cj() {
  local file="$HOME/.zsh.after/cc-projects.list"
  [[ -f "$file" ]] || { echo "[cj] not found: $file"; return 1; }

  # config → 주석/공백 정리 후 배열, 선두 ~ 확장
  local -a projects
  projects=( ${(f)"$(awk 'NF{sub(/#.*/,""); gsub(/^[ \t]+|[ \t]+$/,""); if($0!="")print}' "$file")"} )
  projects=( ${projects/#\~/$HOME} )
  (( ${#projects} )) || { echo "[cj] empty list: $file"; return 1; }

  # 열린 pane 경로 수집 (tmux 서버 없으면 빈 문자열 → 전부 closed)
  local tmux_data
  tmux_data="$(tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index}|#{pane_current_path}' 2>/dev/null)"

  local sel
  sel=$(_cj_match "${projects[@]}" <<< "$tmux_data" \
        | _cj_rows \
        | fzf --ansi --delimiter=$'\t' --with-nth=2 --query="${1:-}" \
              --header='🟢 열림 / ⚪ 닫힘 / ⚠ 없음 │ Enter=이동 or cd' --reverse) || return
  [ -n "$sel" ] || return

  local state payload
  state=$(printf '%s' "$sel" | cut -d$'\t' -f3)
  payload=$(printf '%s' "$sel" | cut -d$'\t' -f4)
  [ -n "$payload" ] || return

  if [[ "$state" == "open" ]]; then
    _cc_goto "$payload"
  else
    cd "$payload"
  fi
}
