#!/usr/bin/env zsh
source ~/.zsh.after/cj.zsh
fail=0

# 실제 디렉토리 + 심링크로 :A 정규화를 정직하게 검증
tmproot=$(mktemp -d)
mkdir -p "$tmproot/real/PRs" "$tmproot/real/bo"
ln -s "$tmproot/real" "$tmproot/link"   # link → real (symlink dir)

# --- _cj_match ---
# open (exact): tmux 경로와 프로젝트 경로 동일
out=$(printf '%s\n' "work:1.0|$tmproot/real/PRs" | _cj_match "$tmproot/real/PRs")
[ "$out" = "open|work:1.0|$tmproot/real/PRs|PRs" ] || { echo "FAIL exact-open: [$out]"; fail=1; }

# open (symlink): 프로젝트는 link 경로, tmux 는 real 경로 → :A 로 동일 판정
out=$(printf '%s\n' "work:1.0|$tmproot/real/PRs" | _cj_match "$tmproot/link/PRs")
echo "$out" | grep -q '^open|work:1.0|' || { echo "FAIL symlink-open: [$out]"; fail=1; }

# open (trailing slash): 프로젝트 경로 끝에 / → :A 로 제거되어 매칭
out=$(printf '%s\n' "work:1.0|$tmproot/real/PRs" | _cj_match "$tmproot/real/PRs/")
echo "$out" | grep -q '^open|work:1.0|' || { echo "FAIL slash-open: [$out]"; fail=1; }

# closed: tmux 에 해당 경로 없음
out=$(printf '%s\n' "work:1.0|$tmproot/real/PRs" | _cj_match "$tmproot/real/bo")
[ "$out" = "closed||$tmproot/real/bo|bo" ] || { echo "FAIL closed: [$out]"; fail=1; }

# first match: 같은 프로젝트에 pane 2개 → 첫 target
out=$(printf '%s\n' "work:1.0|$tmproot/real/PRs" "work:2.0|$tmproot/real/PRs" | _cj_match "$tmproot/real/PRs")
[ "$out" = "open|work:1.0|$tmproot/real/PRs|PRs" ] || { echo "FAIL first-match: [$out]"; fail=1; }

# missing: 실존하지 않는 경로
out=$(printf '%s\n' "work:1.0|$tmproot/real/PRs" | _cj_match "$tmproot/real/ghost")
[ "$out" = "missing||$tmproot/real/ghost|ghost" ] || { echo "FAIL missing: [$out]"; fail=1; }

# 여러 프로젝트 한 번에 (순서 보존)
out=$(printf '%s\n' "work:1.0|$tmproot/real/PRs" | _cj_match "$tmproot/real/PRs" "$tmproot/real/bo")
[ "$(echo "$out" | wc -l | tr -d ' ')" = "2" ] || { echo "FAIL multi-count: [$out]"; fail=1; }

rm -rf "$tmproot"
[ $fail -eq 0 ] && echo "ALL PASS"
exit $fail
