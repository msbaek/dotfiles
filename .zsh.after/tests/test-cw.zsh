#!/usr/bin/env zsh
source ~/.zsh.after/cw.zsh
fail=0
now=$(date +%s); fresh=$((now-10)); old=$((now-4000))   # old > 30분 → stale
out=$(printf '%s\n' \
  "running|$fresh|work:1.0|/a/repoRun|%1" \
  "waiting|$fresh|work:2.0|/a/repoWait|%2" \
  "waiting|$old|work:3.0|/a/repoStale|%3" | _cw_rows)

echo "$out" | head -1 | grep -q 'repoWait' || { echo "FAIL: waiting 최상단 아님"; fail=1; }
echo "$out" | grep 'repoStale' | grep -q '⚪' || { echo "FAIL: stale waiting → idle 파생 실패"; fail=1; }
echo "$out" | grep 'repoRun'  | grep -q '🟢' || { echo "FAIL: running 기호 오류"; fail=1; }
# running-vs-idle 상대 순서 (2번째 행 = running) — Task3 리뷰 minor 보강
echo "$out" | sed -n 2p | grep -q 'repoRun' || { echo "FAIL: 2번째 행이 running 아님(순서)"; fail=1; }

# _cw_wid_for_session: aerospace 'wid|app|title' 에서 제목 끝 토큰=세션명인 Ghostty 창 id
awin=$(printf '%s\n' '7051|Ghostty|work' '7052|Ghostty|🔔 memo' '9999|Finder|memo' | _cw_wid_for_session memo)
[ "$awin" = "7052" ] || { echo "FAIL: wid memo=[$awin] (기대 7052 — 🔔접두사·非Ghostty 무시)"; fail=1; }
awin=$(printf '%s\n' '7051|Ghostty|work' '7052|Ghostty|🔔 memo' | _cw_wid_for_session work)
[ "$awin" = "7051" ] || { echo "FAIL: wid work=[$awin] (기대 7051)"; fail=1; }
awin=$(printf '%s\n' '7051|Ghostty|work' | _cw_wid_for_session nope)
[ -z "$awin" ] || { echo "FAIL: wid nope=[$awin] (기대 빈값)"; fail=1; }
# verbose 제목(플러그인/기본 set-titles)도 세션명 추출
awin=$(printf '%s\n' '7051|Ghostty|work:9:2_1_198 - "msmac1" 5#,8#' '7052|Ghostty|🔔 memo:2:x - "y"' | _cw_wid_for_session memo)
[ "$awin" = "7052" ] || { echo "FAIL: verbose memo=[$awin] (기대 7052)"; fail=1; }
awin=$(printf '%s\n' '7051|Ghostty|work:9:2_1_198 - "msmac1" 5#,8#' | _cw_wid_for_session work)
[ "$awin" = "7051" ] || { echo "FAIL: verbose work=[$awin] (기대 7051)"; fail=1; }

# --- _cc_goto: 이동 프리미티브 (tmux/aerospace/open 을 stub 으로 가로채 호출만 검증) ---
# _goto_calls <target> <cur_session> <aerospace_windows>: stub 환경에서 _cc_goto 실행 →
#   실제로 불린 tmux/aerospace/open 명령 로그를 stdout 으로. subshell 로 stub 격리.
_goto_calls() {
  # 변수는 _g* prefix — _cc_goto 의 local(cur/sess/win/target)과 dynamic-scope 충돌 방지
  local _gtarget="$1" _gcur="$2" _gwins="$3" log; log=$(mktemp)
  (
    export TMUX="dummy"   # tmux-내부 경로 진입용(값 무의미 — 모든 tmux 호출은 stub 이 가로챔)
    tmux()      { print -r -- "tmux $*" >>"$log"; [[ "$*" == *display* ]] && print -r -- "$_gcur"; }
    aerospace() { print -r -- "aerospace $*" >>"$log"; [[ "$*" == *list-windows* ]] && print -r -- "$_gwins"; }
    open()      { print -r -- "open $*" >>"$log"; }
    _cc_goto "$_gtarget"
  )
  cat "$log"; rm -f "$log"
}

# 케이스1(회귀 핵심): 다른 세션인데 그 세션의 ghostty 창이 없음(detached)
#   → 현재 창을 덮는 switch-client 금지, 새 ghostty 창(open)으로 열어야 함
log=$(_goto_calls "memo:3.0" "cj" "342|Ghostty|work")
echo "$log" | grep -q 'open .*attach -t memo' || { echo "FAIL goto-detached: 새 창에서 memo 에 attach 안 함 [$log]"; fail=1; }
echo "$log" | grep -q 'switch-client'         && { echo "FAIL goto-detached: switch-client 로 현재 창 치환됨 [$log]"; fail=1; }

# 케이스2: 다른 세션 + 그 세션 ghostty 창 있음 → aerospace focus, open/switch 없음
log=$(_goto_calls "memo:3.0" "cj" "343|Ghostty|memo")
echo "$log" | grep -q 'aerospace focus' || { echo "FAIL goto-otherwin: aerospace focus 미호출 [$log]"; fail=1; }
echo "$log" | grep -q '^open '          && { echo "FAIL goto-otherwin: 창 있는데 open 호출됨 [$log]"; fail=1; }
echo "$log" | grep -q 'switch-client'   && { echo "FAIL goto-otherwin: switch-client 호출됨 [$log]"; fail=1; }

# 케이스3: 같은 세션 → select 만 하고 early return (focus/open/switch 없음)
log=$(_goto_calls "cj:1.0" "cj" "343|Ghostty|memo")
echo "$log" | grep -q 'aerospace focus' && { echo "FAIL goto-same: 같은 세션인데 focus 호출 [$log]"; fail=1; }
echo "$log" | grep -q '^open '          && { echo "FAIL goto-same: 같은 세션인데 open 호출 [$log]"; fail=1; }
echo "$log" | grep -q 'switch-client'   && { echo "FAIL goto-same: 같은 세션인데 switch-client 호출 [$log]"; fail=1; }

[ $fail -eq 0 ] && echo "ALL PASS"
exit $fail
