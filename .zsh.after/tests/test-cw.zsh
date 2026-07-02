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
[ $fail -eq 0 ] && echo "ALL PASS"
exit $fail
