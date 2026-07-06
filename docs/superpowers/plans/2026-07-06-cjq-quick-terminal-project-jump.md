# cjq — quick terminal 전용 project jump Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ghostty quick terminal에서 `cj` 대신 `cjq`를 실행하면, 선택한 프로젝트가 열려 있으면 `cwq`처럼 quick terminal을 닫고 그 pane으로 이동하고, 닫혀 있으면 정해진 세션(memo/work)에 새 window를 만들어 그곳으로 이동하며, 루프를 유지해 다음 quick terminal 오픈 시 곧바로 다음 선택을 받는다.

**Architecture:** `cc-projects.list`에 프로젝트별 소속 세션을 나타내는 `@memo` 인라인 태그를 추가하고, 이를 파싱하는 순수 함수 `_cj_load`를 신설해 기존 `cj()`의 목록 로딩부를 교체한다. 닫힌 프로젝트를 위한 새 window 생성은 `_cjq_new_and_jump`(신규)가 `tmux new-window -P -F`로 target을 얻어 기존 `_cwq_jump`(cw.zsh, 무수정)에 넘기는 방식으로 재사용한다. `cjq()`는 `cj()`의 목록·매칭 로직과 `cwq()`의 while-loop 구조를 그대로 조합한 오케스트레이션 함수다.

**Tech Stack:** zsh, tmux CLI, fzf, awk, GNU/BSD 공용 셸 유틸.

## Global Constraints

- 기존 `cj` 동작·테스트 불변: `.zsh.after/tests/test-cj.zsh`는 리팩터 후에도 그대로 통과해야 한다.
- 기존 `cwq` 동작·테스트 불변: `.zsh.after/cw.zsh`는 무수정, `.zsh.after/tests/test-cw.zsh`는 그대로 통과해야 한다.
- 세션 배치(어느 프로젝트가 memo/work인지)는 `cc-projects.list`의 인라인 `@memo` 태그로 고정한다 — 런타임에 tmux를 조회해 동적으로 판단하지 않는다.
- YAGNI: `cwq`의 fzf preview·Ctrl-R 재로딩 기능은 `cjq`에 가져오지 않는다(닫힘 시 새 window 생성 + dismiss + 이동 + 루프만).
- 커밋 시 `--no-verify` 사용(이 repo의 pre-commit이 unstaged stash와 충돌해 파일을 유실시키는 알려진 버그 — dotfiles CLAUDE.md에 문서화됨).

---

### Task 1: `_cj_load` — `@memo` 태그 파싱

**Files:**
- Modify: `.zsh.after/cj.zsh:1-3` (헤더 주석 뒤에 함수 삽입)
- Test: `.zsh.after/tests/test-cj.zsh` (말미에 추가)

**Interfaces:**
- Produces: `_cj_load <file>` — stdout에 한 줄당 `path<TAB>session` 출력. `session`은 줄 끝에 (공백 하나 이상 뒤) `@memo`가 있으면 `memo`, 없으면 `work`. `#` 이후 주석·빈 줄은 출력에서 제외. `~` 확장은 하지 않는다(호출자 책임).

- [ ] **Step 1: 실패하는 테스트 작성**

`.zsh.after/tests/test-cj.zsh` 파일에서 아래 블록을 찾는다:

```zsh
rm -rf "$tmproot"
[ $fail -eq 0 ] && echo "ALL PASS"
exit $fail
```

이 블록을 다음으로 교체한다(테스트를 `rm -rf "$tmproot"` 뒤, 최종 요약 앞에 삽입):

```zsh
rm -rf "$tmproot"

# --- _cj_load ---
lf=$(mktemp)
printf '%s\n' \
  '# comment line' \
  '~/git/kt4u/PRs' \
  '' \
  '~/dotfiles @memo' \
  '~/qmk_firmware   @memo   # trailing comment' \
  '~/weird@memo' > "$lf"

out=$(_cj_load "$lf")
line=$(echo "$out" | sed -n 1p)
[ "$line" = $'~/git/kt4u/PRs\twork' ] || { echo "FAIL cjload-notag: [$line]"; fail=1; }
line=$(echo "$out" | sed -n 2p)
[ "$line" = $'~/dotfiles\tmemo' ] || { echo "FAIL cjload-tag: [$line]"; fail=1; }
line=$(echo "$out" | sed -n 3p)
[ "$line" = $'~/qmk_firmware\tmemo' ] || { echo "FAIL cjload-tag-messy-spacing: [$line]"; fail=1; }
line=$(echo "$out" | sed -n 4p)
[ "$line" = $'~/weird@memo\twork' ] || { echo "FAIL cjload-no-space-before-at: [$line]"; fail=1; }
[ "$(echo "$out" | wc -l | tr -d ' ')" = "4" ] || { echo "FAIL cjload-linecount: [$out]"; fail=1; }
rm -f "$lf"

[ $fail -eq 0 ] && echo "ALL PASS"
exit $fail
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `zsh .zsh.after/tests/test-cj.zsh`
Expected: `_cj_load: command not found` 계열 에러와 함께 실패 (아직 함수가 없으므로).

- [ ] **Step 3: 최소 구현**

`.zsh.after/cj.zsh`에서 다음 두 줄:

```zsh
# cj — 설정된 claude 프로젝트로 이동. 열림→pane 점프, 닫힘→현재 pane 에서 cd.
# 이동 프리미티브 _cc_goto 는 cw.zsh 에 정의(런타임에 호출).
```

를 다음으로 교체한다:

```zsh
# cj — 설정된 claude 프로젝트로 이동. 열림→pane 점프, 닫힘→현재 pane 에서 cd.
# 이동 프리미티브 _cc_goto/_cwq_jump 는 cw.zsh 에 정의(런타임에 호출).

# _cj_load <file>: 프로젝트 목록 파일 → 'path<TAB>session' (주석/공백 제거, @memo 태그 파싱).
#   태그 없으면 session=work. ~ 확장은 호출자 책임(기존 cj() 관례 유지).
_cj_load() {
  awk '
    {
      sub(/#.*/, "")
      gsub(/^[ \t]+|[ \t]+$/, "")
    }
    /^$/ { next }
    {
      session = "work"
      if ($0 ~ /[ \t]@memo[ \t]*$/) {
        session = "memo"
        sub(/[ \t]+@memo[ \t]*$/, "")
        gsub(/[ \t]+$/, "")
      }
      print $0 "\t" session
    }
  ' "$1"
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `zsh .zsh.after/tests/test-cj.zsh`
Expected: `ALL PASS` (기존 `_cj_match`/`_cj_rows` 테스트 + 신규 `_cj_load` 테스트 전부 통과)

- [ ] **Step 5: 커밋**

```bash
git add .zsh.after/cj.zsh .zsh.after/tests/test-cj.zsh
git commit --no-verify -m "feat(cjq): _cj_load — cc-projects.list @memo 태그 파싱"
```

---

### Task 2: `cj()` 리팩터 + `cc-projects.list` 태깅

**Files:**
- Modify: `.zsh.after/cj.zsh` (`cj()` 함수의 목록 로딩부)
- Modify: `.zsh.after/cc-projects.list` (전체 재작성 — `@memo` 태그 7건 추가)

**Interfaces:**
- Consumes: `_cj_load <file>` (Task 1)
- Produces: (인터페이스 변경 없음 — `cj()`의 동작·시그니처는 그대로. 이후 Task는 `cc-projects.list`에 추가된 `@memo` 태그를 전제로 진행.)

- [ ] **Step 1: `cj()` 목록 로딩부를 `_cj_load` 사용으로 교체**

`.zsh.after/cj.zsh`에서 `cj()` 함수 내부의 다음 블록:

```zsh
  # config → 주석/공백 정리 후 배열, 선두 ~ 확장
  local -a projects
  projects=( ${(f)"$(awk 'NF{sub(/#.*/,""); gsub(/^[ \t]+|[ \t]+$/,""); if($0!="")print}' "$file")"} )
  projects=( ${projects/#\~/$HOME} )
  (( ${#projects} )) || { echo "[cj] empty list: $file"; return 1; }
```

를 다음으로 교체한다:

```zsh
  # config → _cj_load(path\tsession) 에서 path 만 취해 배열, 선두 ~ 확장
  local -a lines projects
  lines=( ${(f)"$(_cj_load "$file")"} )
  (( ${#lines} )) || { echo "[cj] empty list: $file"; return 1; }
  local line
  for line in "${lines[@]}"; do
    projects+=( "${line%%$'\t'*}" )
  done
  projects=( ${projects/#\~/$HOME} )
```

- [ ] **Step 2: 회귀 테스트 실행 (기존 동작 불변 확인)**

Run: `zsh .zsh.after/tests/test-cj.zsh && zsh .zsh.after/tests/test-cw.zsh`
Expected: 둘 다 `ALL PASS` (리팩터가 `_cj_match`/`_cj_rows`/`cw.zsh`에 영향 없음을 확인)

- [ ] **Step 3: `cc-projects.list`에 `@memo` 태그 추가**

`.zsh.after/cc-projects.list` 전체를 다음 내용으로 교체한다:

```
# cj (claude project jump) 대상 프로젝트 목록.
# 한 줄당 절대경로(또는 ~). '#' 이후·빈 줄 무시. 줄 끝 '@memo' 태그 → memo 세션 소속(없으면 work).
~/git/kt4u/PRs
~/git/kt4u/bo
~/git/kt4u/plan-docs
~/git/kt4u/isms-evidence
~/git/kt4u/datadog
~/qmk_firmware @memo
~/git/ai-agent/revfactory/webtoon-harness
~/git/msbaek-claude-plugins
~/dotfiles @memo
~/claude-config @memo
~/git/kt4u/teams @memo
~/git/presentation-designer
~/DocumentsLocal/msbaek_vault @memo
~/git/projects/daily-dashboard
~/git/vault-intelligence @memo
~/temp @memo
```

- [ ] **Step 4: 실제 파일 파싱 sanity check**

Run:
```bash
source .zsh.after/cj.zsh
_cj_load ~/.zsh.after/cc-projects.list | grep -c $'\tmemo'
```
Expected: `7` (태그된 7개 경로: qmk_firmware, dotfiles, claude-config, kt4u/teams, msbaek_vault, vault-intelligence, temp)

Run:
```bash
_cj_load ~/.zsh.after/cc-projects.list | grep 'PRs'
```
Expected: `~/git/kt4u/PRs	work` (태그 없는 항목은 work 기본값)

- [ ] **Step 5: 커밋**

```bash
git add .zsh.after/cj.zsh .zsh.after/cc-projects.list
git commit --no-verify -m "refactor(cjq): cj() 를 _cj_load 로 전환 + cc-projects.list @memo 태깅"
```

---

### Task 3: `_cjq_new_and_jump`

**Files:**
- Modify: `.zsh.after/cj.zsh` (`cj()` 함수 뒤에 추가)
- Test: `.zsh.after/tests/test-cj.zsh` (말미에 추가)

**Interfaces:**
- Consumes: `_cwq_jump <target>` (기존, `cw.zsh`에 정의 — 런타임 참조, source 불필요)
- Produces: `_cjq_new_and_jump <path> <session>` — `tmux new-window -t <session> -c <path>`로 새 window를 만들고 그 target(`session:window.pane`)으로 `_cwq_jump`를 호출한다. `new-window` 실패 시(빈 출력) `_cwq_jump ""`가 호출되며, 이는 `_cwq_jump`의 기존 빈 target 가드(`[ -n "$target" ] || return`)로 인해 no-op이다.

- [ ] **Step 1: 실패하는 테스트 작성**

`.zsh.after/tests/test-cj.zsh`에서 다음 블록(Task 1에서 추가한 부분의 끝):

```zsh
rm -f "$lf"

[ $fail -eq 0 ] && echo "ALL PASS"
exit $fail
```

를 다음으로 교체한다:

```zsh
rm -f "$lf"

# --- _cjq_new_and_jump (tmux/_cwq_jump stub, subshell 격리) ---
_cjqnew_calls() {
  local _gpath="$1" _gsession="$2" _gtmuxout="$3" log; log=$(mktemp)
  (
    tmux()      { print -r -- "tmux $*" >>"$log"; [[ "$*" == *new-window* ]] && print -r -- "$_gtmuxout"; }
    _cwq_jump() { print -r -- "_cwq_jump[$*]" >>"$log"; }
    _cjq_new_and_jump "$_gpath" "$_gsession"
  )
  cat "$log"; rm -f "$log"
}

# 성공: new-window 가 target 반환 → 그 target 으로 _cwq_jump 호출
log=$(_cjqnew_calls "/p/foo" "work" "work:5.0")
echo "$log" | grep -q 'tmux new-window -t work -c /p/foo' || { echo "FAIL cjqnew-success: new-window 인자 오류 [$log]"; fail=1; }
line=$(echo "$log" | grep '_cwq_jump')
[ "$line" = "_cwq_jump[work:5.0]" ] || { echo "FAIL cjqnew-success: _cwq_jump target 오류 [$line]"; fail=1; }

# 실패(경로 없음 등): new-window 빈 출력 → _cwq_jump 가 빈 target 으로 호출됨(가드는 _cwq_jump 자체 책임)
log=$(_cjqnew_calls "/p/ghost" "memo" "")
echo "$log" | grep -q 'tmux new-window -t memo -c /p/ghost' || { echo "FAIL cjqnew-fail: new-window 인자 오류 [$log]"; fail=1; }
line=$(echo "$log" | grep '_cwq_jump')
[ "$line" = "_cwq_jump[]" ] || { echo "FAIL cjqnew-fail: 빈 target 으로 _cwq_jump 호출 안 됨 [$line]"; fail=1; }

[ $fail -eq 0 ] && echo "ALL PASS"
exit $fail
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `zsh .zsh.after/tests/test-cj.zsh`
Expected: `_cjq_new_and_jump: command not found` 계열 에러와 함께 실패.

- [ ] **Step 3: 최소 구현**

`.zsh.after/cj.zsh` 말미(`cj()` 함수가 끝나는 `}` 다음)에 추가한다:

```zsh

# _cjq_new_and_jump <path> <session>: session 에 새 window 를 만들고 그 target 으로 _cwq_jump.
#   new-window 실패(예: 경로 없음) 시 target 빈 문자열 → _cwq_jump 의 빈 target 가드로 no-op.
_cjq_new_and_jump() {
  local path="$1" session="$2" target
  target=$(tmux new-window -t "$session" -c "$path" -P -F '#{session_name}:#{window_index}.#{pane_index}' 2>/dev/null)
  _cwq_jump "$target"
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `zsh .zsh.after/tests/test-cj.zsh`
Expected: `ALL PASS`

- [ ] **Step 5: 커밋**

```bash
git add .zsh.after/cj.zsh .zsh.after/tests/test-cj.zsh
git commit --no-verify -m "feat(cjq): _cjq_new_and_jump — 닫힌 프로젝트용 새 window 생성 + 이동"
```

---

### Task 4: `cjq()` + cheats 등록

**Files:**
- Modify: `.zsh.after/cj.zsh` (`_cjq_new_and_jump` 뒤에 `cjq()` 추가)
- Modify: `.zsh.after/msbaek.cheats` (`cwq` 항목 뒤에 `cjq` 항목 추가)

**Interfaces:**
- Consumes: `_cj_load`(Task 1), `_cjq_new_and_jump`(Task 3), `_cj_match`/`_cj_rows`(기존, `cj.zsh`), `_cwq_jump`(기존, `cw.zsh`)
- Produces: `cjq()` — quick terminal에서 실행하는 인터랙티브 루프 함수(테스트 대상 아님 — `cwq()` 자체도 직접 테스트되지 않고 하부 프리미티브만 테스트되는 기존 관례와 동일).

- [ ] **Step 1: `cjq()` 구현**

`.zsh.after/cj.zsh` 말미(`_cjq_new_and_jump` 함수가 끝나는 `}` 다음)에 추가한다:

```zsh

# cjq: quick terminal 전용 cj. 열림→_cwq_jump, 닫힘/없음→(memo/work 세션에) 새 window 생성 후 이동.
#   cwq 처럼 루프 유지 — 이동 후에도 quick terminal 재오픈 시 곧바로 다음 fzf.
#   Esc/Ctrl-C=루프 종료(취소, quick terminal 은 닫지 않음).
cjq() {
  local file="$HOME/.zsh.after/cc-projects.list"
  [[ -f "$file" ]] || { echo "[cjq] not found: $file"; return 1; }

  local -a lines
  lines=( ${(f)"$(_cj_load "$file")"} )
  (( ${#lines} )) || { echo "[cjq] empty list: $file"; return 1; }

  local -a projects
  local -A session_of
  local line p s
  for line in "${lines[@]}"; do
    p="${line%%$'\t'*}"
    p="${p/#\~/$HOME}"
    s="${line##*$'\t'}"
    projects+=( "$p" )
    session_of[$p]="$s"
  done

  local tmux_data sel state payload
  while true; do
    tmux_data="$(tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index}|#{pane_current_path}' 2>/dev/null)"

    sel=$(_cj_match "${projects[@]}" <<< "$tmux_data" \
          | _cj_rows \
          | fzf --ansi --delimiter=$'\t' --with-nth=2 \
                --header='🟢 열림 / ⚪ 닫힘(새 window) / ⚠ 없음 │ Enter=이동' --reverse) || break
    [ -n "$sel" ] || break

    state=$(printf '%s' "$sel" | cut -d$'\t' -f3)
    payload=$(printf '%s' "$sel" | cut -d$'\t' -f4)
    [ -n "$payload" ] || break

    if [[ "$state" == "open" ]]; then
      _cwq_jump "$payload"
    else
      _cjq_new_and_jump "$payload" "${session_of[$payload]:-work}"
    fi
  done
}
```

- [ ] **Step 2: 회귀 테스트 재실행**

Run: `zsh .zsh.after/tests/test-cj.zsh && zsh .zsh.after/tests/test-cw.zsh`
Expected: 둘 다 `ALL PASS` (신규 함수 추가가 기존 동작에 영향 없음을 확인)

- [ ] **Step 3: cheats 항목 추가**

```bash
awk '{print} /quick terminal agents pane/{print "f\tcjq\tquick terminal 전용 cj — 닫힘도 memo/work 세션에 새 window 후 이동\tclaude"}' \
  .zsh.after/msbaek.cheats > /tmp/cheats.new && mv /tmp/cheats.new .zsh.after/msbaek.cheats
```

검증:
```bash
grep -n 'cjq' .zsh.after/msbaek.cheats
```
Expected: `f	cjq	quick terminal 전용 cj — 닫힘도 memo/work 세션에 새 window 후 이동	claude` 한 줄이 `cwq` 항목 바로 다음에 보임.

- [ ] **Step 4: 수동 검증 (라이브 quick terminal)**

셸을 재시작하거나 `source .zsh.after/cj.zsh .zsh.after/cw.zsh`로 함수를 갱신한 뒤:

1. Ghostty quick terminal을 연다(`cmd+alt+6`).
2. `cjq`를 실행하고 이미 열려 있는 프로젝트(🟢)를 선택 → quick terminal이 닫히고 해당 pane이 있는 ghostty 창이 focus되는지 확인.
3. quick terminal을 다시 열어 `cjq`가 즉시 다음 fzf 프롬프트를 보여주는지 확인(루프 유지).
4. 닫혀 있는(⚪) 태그 없는 프로젝트(예: `kt4u/bo`)를 선택 → `work` 세션에 새 window가 생기고 그곳으로 이동하는지 확인.
5. `@memo` 태그된 프로젝트 중 하나를 tmux에서 `kill-window`로 닫은 뒤 `cjq`로 다시 선택 → `memo` 세션에 새 window가 생기는지 확인.
6. Esc로 취소 → quick terminal이 닫히지 않고 그대로인지 확인.

- [ ] **Step 5: 커밋**

```bash
git add .zsh.after/cj.zsh .zsh.after/msbaek.cheats
git commit --no-verify -m "feat(cjq): cjq — quick terminal 전용 프로젝트 점프 루프 + cheats 등록"
```
