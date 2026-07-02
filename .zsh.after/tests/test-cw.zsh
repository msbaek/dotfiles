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

[ $fail -eq 0 ] && echo "ALL PASS"
exit $fail
