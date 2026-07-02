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
