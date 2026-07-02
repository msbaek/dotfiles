# Claude 세션 Attention Router Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 여러 repo의 claude 세션 중 "내 응답을 기다리는" 것을 즉시 식별해 최소 마찰로 이동/복귀하여 상호 대기 시간을 줄인다.

**Architecture:** Claude Code 훅이 각 세션의 상태(`running`/`waiting`/`idle`)를 **tmux pane 옵션**(`@cc_state`/`@cc_since`)에 기록한다(별도 파일 없음 → 동시성 안전). `cw` fzf 함수가 이 옵션을 읽어 waiting-first로 정렬·이동하고, tmux 키바인드로 hub(abtop)에 복귀한다.

**Tech Stack:** POSIX sh(훅), zsh(`cw`), tmux options/format, fzf, awk.

## Global Constraints

- **진행 중 세션 유지**: running claude를 자동 종료·kill하지 않는다.
- **저장소 = tmux 옵션만**: 상태를 공유 파일에 쓰지 않는다 (동시 write race 방지).
- **`SubagentStop` 제외**: teammate subagent는 상태로 잡지 않는다.
- **훅은 항상 `exit 0`**: 훅 실패가 claude 동작을 막지 않게 한다.
- **tmux 밖 세션 = no-op**: `$TMUX` 비면 훅은 아무것도 하지 않는다.
- **stow 매핑**: 훅·`settings.json` → `~/claude-config` repo(`~/.claude/` 경유). `cw`·tmux·ghostty·mshelp → `~/dotfiles` repo.
- **모든 커밋은 `--no-verify`**: pre-commit 프레임워크가 커밋 중 unstaged 변경을 stash했다가 Brewfile 자동수정과 충돌해 롤백하며 unstaged 파일(ghostty 등)을 유실시킴. 반드시 `git commit --no-verify` 사용(사용자 `cc-commit-only` 패턴). 커밋 대상 파일만 정확히 `git add`.
- **검증된 사실(2026-07-02)**: 훅 환경에 `$TMUX_PANE`·`$TMUX` 존재. `tmux set -p @cc_*` 쓰기 + `tmux list-panes -a -F '#{@cc_*}'` 읽기 동작.
- **Caveat**: `Stop`은 매 턴 발화 → 지금 보고 있는 pane도 waiting으로 뜸 → `cw`에서 자기 pane 제외. `cld`(`--dangerously-skip-permissions`) 사용 시 permission Notification 거의 없음 → waiting 신호는 사실상 Stop 단독.

---

### Task 0: 브랜치 준비 (두 repo)

**Files:** (없음 — git 브랜치만)

- [ ] **Step 1: 두 repo 현재 브랜치 확인**

Run:
```bash
git -C ~/claude-config branch --show-current
git -C ~/dotfiles branch --show-current
```

- [ ] **Step 2: main/master이면 feature 브랜치 생성**

각 repo가 기본 브랜치(main/master)면 아래 실행. 이미 작업 브랜치면 skip.
```bash
git -C ~/claude-config switch -c feat/cc-attention-router
git -C ~/dotfiles switch -c feat/cc-attention-router
```

Expected: 두 repo가 `feat/cc-attention-router`(또는 기존 작업 브랜치)에 위치.

---

### Task 1: 훅 디스패처 `cc-attention.sh`

세션 상태를 tmux pane 옵션에 기록하는 POSIX sh 스크립트. 이벤트명을 인자로 받는다.

**Files:**
- Create: `~/.claude/hooks/cc-attention.sh` (stow → `~/claude-config/.claude/hooks/cc-attention.sh`)
- Test: `~/.claude/hooks/tests/test-cc-attention.sh`

**Interfaces:**
- Consumes: env `$TMUX`, `$TMUX_PANE`; 인자 `$1` = 훅 이벤트명(`Stop`/`Notification`/`UserPromptSubmit`/`SessionStart`/`SessionEnd`/기타).
- Produces: tmux pane 옵션 `@cc_state` ∈ {`running`,`waiting`,`idle`}, `@cc_since`(epoch). Task 3(`cw`)가 이 옵션을 읽는다.

- [ ] **Step 1: 실패 테스트 작성**

`~/.claude/hooks/tests/test-cc-attention.sh`:
```sh
#!/usr/bin/env zsh
set -u
HOOK="$HOME/.claude/hooks/cc-attention.sh"
fail=0
assert_eq() { [ "$1" = "$2" ] || { echo "FAIL[$3]: expected [$2] got [$1]"; fail=1; }; }

tmux new-session -d -s cctest -x 80 -y 24
pane=$(tmux list-panes -t cctest -F '#{pane_id}' | head -1)
# 유효한 $TMUX 생성: 훅 내부 tmux 가 올바른 서버에 접속하려면 $TMUX 가 실제
# 소켓을 가리켜야 함 (literal "dummy" 는 소켓 해석 실패로 set 이 무시됨).
sock=$(tmux display-message -pt cctest '#{socket_path}')
TM="$sock,0,0"

# $TMUX 는 non-empty 여야 훅이 동작 (게이트). 타겟팅은 $TMUX_PANE 로.
TMUX="$TM" TMUX_PANE="$pane" "$HOOK" Stop
assert_eq "$(tmux show -p -t "$pane" -v @cc_state)" "waiting" "Stop→waiting"

TMUX="$TM" TMUX_PANE="$pane" "$HOOK" UserPromptSubmit
assert_eq "$(tmux show -p -t "$pane" -v @cc_state)" "running" "UPS→running"

# SubagentStop 은 무시 → running 유지
TMUX="$TM" TMUX_PANE="$pane" "$HOOK" SubagentStop
assert_eq "$(tmux show -p -t "$pane" -v @cc_state)" "running" "SubagentStop 무시"

# SessionEnd → 제거
TMUX="$TM" TMUX_PANE="$pane" "$HOOK" SessionEnd
assert_eq "$(tmux show -p -t "$pane" -v @cc_state)" "" "SessionEnd 제거"

# tmux 밖(게이트) → no-op, exit 0
TMUX= TMUX_PANE= "$HOOK" Stop; assert_eq "$?" "0" "tmux 밖 exit 0"

tmux kill-session -t cctest
[ $fail -eq 0 ] && echo "ALL PASS"
exit $fail
```

- [ ] **Step 2: 테스트 실행 → 실패 확인**

Run: `mkdir -p ~/.claude/hooks/tests && zsh ~/.claude/hooks/tests/test-cc-attention.sh`
Expected: FAIL (HOOK 파일 없음 → 상태가 빈 값)

- [ ] **Step 3: 훅 스크립트 작성**

`~/.claude/hooks/cc-attention.sh`:
```sh
#!/bin/sh
# cc-attention.sh — Claude Code 세션 상태를 tmux pane 옵션에 기록.
# 사용(settings.json): "$HOME/.claude/hooks/cc-attention.sh" <EventName>
# 저장소: tmux pane 옵션 @cc_state / @cc_since (별도 파일 없음 → 동시성 안전).
# claude 동작을 막지 않도록 항상 exit 0.
event="$1"
[ -n "$TMUX" ] || exit 0          # tmux 밖이면 no-op
[ -n "$TMUX_PANE" ] || exit 0

set_state() {
  tmux set -p -t "$TMUX_PANE" @cc_state "$1" 2>/dev/null
  tmux set -p -t "$TMUX_PANE" @cc_since "$(date +%s)" 2>/dev/null
}

case "$event" in
  UserPromptSubmit)  set_state running ;;
  Stop|Notification) set_state waiting ;;
  SessionStart)      set_state idle ;;
  SessionEnd)
    tmux set -pu -t "$TMUX_PANE" @cc_state 2>/dev/null
    tmux set -pu -t "$TMUX_PANE" @cc_since 2>/dev/null ;;
  *) : ;;                          # SubagentStop 등 → 무시
esac
exit 0
```

- [ ] **Step 4: 실행 권한 + 테스트 통과 확인**

Run: `chmod +x ~/.claude/hooks/cc-attention.sh && zsh ~/.claude/hooks/tests/test-cc-attention.sh`
Expected: `ALL PASS`

- [ ] **Step 5: 커밋 (claude-config)**

```bash
git -C ~/claude-config add .claude/hooks/cc-attention.sh .claude/hooks/tests/test-cc-attention.sh
git -C ~/claude-config commit --no-verify -m "feat(hooks): claude 세션 상태를 tmux pane 옵션에 기록"
```

---

### Task 2: `settings.json`에 훅 등록

디스패처를 5개 이벤트에 등록한다. **`SubagentStop`에는 등록하지 않는다.** 기존 훅을 보존하며 추가한다.

**Files:**
- Modify: `~/.claude/settings.json` (stow → claude-config)
- Test: `~/.claude/hooks/tests/test-settings-registration.sh`

**Interfaces:**
- Consumes: Task 1의 `~/.claude/hooks/cc-attention.sh`.
- Produces: 5개 이벤트(`Stop`/`Notification`/`UserPromptSubmit`/`SessionStart`/`SessionEnd`) 발화 시 디스패처 실행.

- [ ] **Step 1: 실패 테스트 작성**

`~/.claude/hooks/tests/test-settings-registration.sh`:
```sh
#!/usr/bin/env zsh
python3 - "$HOME/.claude/settings.json" <<'PY'
import json,sys
d=json.load(open(sys.argv[1])); h=d.get("hooks",{})
def has(ev):
    return any("cc-attention.sh" in hk.get("command","")
               for grp in h.get(ev,[]) for hk in grp.get("hooks",[]))
need=["Stop","Notification","UserPromptSubmit","SessionStart","SessionEnd"]
bad=[e for e in need if not has(e)]
assert not bad, f"미등록 이벤트: {bad}"
assert not has("SubagentStop"), "SubagentStop 에 등록되면 안 됨"
print("ALL PASS")
PY
```

- [ ] **Step 2: 테스트 실행 → 실패 확인**

Run: `zsh ~/.claude/hooks/tests/test-settings-registration.sh`
Expected: FAIL (`AssertionError: 미등록 이벤트: [...]`)

- [ ] **Step 3: 각 이벤트에 훅 그룹 추가 (포맷 보존, 타겟 Edit)**

**전체 재직렬화 금지** — `json.dump`로 파일을 통째로 다시 쓰면 무관한 배열까지
모두 재포맷되어 diff가 폭발한다. 대신 기존 구조를 읽고 **각 이벤트 배열의 마지막
그룹 뒤에 새 그룹 하나만** 삽입한다.

1. `~/.claude/settings.json`을 읽는다. 5개 이벤트(`Stop`/`Notification`/
   `UserPromptSubmit`/`SessionStart`/`SessionEnd`)의 배열은 이미 존재한다.
2. 각 이벤트 배열의 마지막 원소 뒤에, 기존 들여쓰기를 맞춰 아래 그룹을 Edit로 추가:
   ```json
   {
     "hooks": [
       { "type": "command", "command": "$HOME/.claude/hooks/cc-attention.sh Stop" }
     ]
   }
   ```
   (각 이벤트마다 커맨드 끝의 `Stop`을 해당 이벤트명으로 교체. 이미 `cc-attention.sh`가
   있으면 그 이벤트는 skip — 멱등.)
3. **`SubagentStop` 배열은 건드리지 않는다.**

- [ ] **Step 4: JSON 유효성 + 테스트 통과 확인**

Run:
```bash
python3 -c "import json;json.load(open('$HOME/.claude/settings.json'))" && echo "JSON OK"
zsh ~/.claude/hooks/tests/test-settings-registration.sh
```
Expected: `JSON OK` 그리고 `ALL PASS`

- [ ] **Step 5: 커밋 (claude-config)**

```bash
git -C ~/claude-config add .claude/settings.json .claude/hooks/tests/test-settings-registration.sh
git -C ~/claude-config commit --no-verify -m "feat(hooks): cc-attention 디스패처를 5개 이벤트에 등록(SubagentStop 제외)"
```

---

### Task 3: `cw` — waiting-first 조회·이동 함수

tmux 옵션을 읽어 상태 파생(`idle`은 시간 기반) + waiting-first 정렬 + fzf 이동.

**Files:**
- Create: `~/.zsh.after/cw.zsh` (dotfiles)
- Test: `~/.zsh.after/tests/test-cw.zsh`

**Interfaces:**
- Consumes: tmux pane 옵션 `@cc_state`/`@cc_since` (Task 1).
- Produces: 함수 `_cw_rows`(stdin: `state|since|target|path|pane_id` 라인 → stdout: `key\t디스플레이\ttarget` 정렬행), 함수 `cw`(fzf 선택 → `tmux switch-client -t <target>`). env `CW_IDLE_MINS`(기본 30) 로 idle 임계 조정.

- [ ] **Step 1: 실패 테스트 작성**

`~/.zsh.after/tests/test-cw.zsh`:
```zsh
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
```

- [ ] **Step 2: 테스트 실행 → 실패 확인**

Run: `mkdir -p ~/.zsh.after/tests && zsh ~/.zsh.after/tests/test-cw.zsh`
Expected: FAIL (`cw.zsh` 없음 → `_cw_rows` 미정의)

- [ ] **Step 3: `cw.zsh` 작성**

`~/.zsh.after/cw.zsh`:
```zsh
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
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `zsh ~/.zsh.after/tests/test-cw.zsh`
Expected: `ALL PASS`

- [ ] **Step 5: 자동 로드 확인 (새 셸에서 `cw` 정의 여부)**

Run: `zsh -ic 'typeset -f cw >/dev/null && echo LOADED || echo NOT-LOADED'`
Expected: `LOADED`. `NOT-LOADED`면 `~/.zshrc`에 `source ~/.zsh.after/cw.zsh` 한 줄 추가 후 재확인.

- [ ] **Step 6: 커밋 (dotfiles)**

```bash
git -C ~/dotfiles add .zsh.after/cw.zsh .zsh.after/tests/test-cw.zsh
git -C ~/dotfiles commit --no-verify -m "feat(zsh): cw — 대기 중 claude 세션 waiting-first 이동"
```

---

### Task 4: abtop 복귀 키바인드 (tmux)

어느 세션에 있든 한 키로 hub(abtop 세션)에 복귀.

**Files:**
- Modify: `~/.tmux.conf` (dotfiles)

**Interfaces:**
- Consumes: 기존 tmux `abtop` 세션(hub).
- Produces: `prefix + a` → `switch-client -t abtop`.

- [ ] **Step 1: 실패 테스트 작성 (grep 기반)**

Run: `grep -q 'switch-client -t abtop' ~/.tmux.conf && echo FOUND || echo MISSING`
Expected: `MISSING`

- [ ] **Step 2: 키바인드 추가**

`~/.tmux.conf` 끝에 추가:
```tmux
# cc-attention: hub(abtop) 로 즉시 복귀
bind a switch-client -t abtop
```

- [ ] **Step 3: 반영 + 바인딩 확인**

Run:
```bash
tmux source-file ~/.tmux.conf
tmux list-keys | grep -q 'switch-client -t abtop' && echo BOUND || echo FAIL
```
Expected: `BOUND`

- [ ] **Step 4: 커밋 (dotfiles)**

```bash
git -C ~/dotfiles add .tmux.conf
git -C ~/dotfiles commit --no-verify -m "feat(tmux): prefix+a 로 abtop hub 복귀"
```

---

### Task 5: `mshelp` cheats 등록 (발견성)

**Files:**
- Modify: `~/.zsh.after/msbaek.cheats` (dotfiles)

- [ ] **Step 1: cheats 라인 추가**

`msbaek.cheats`의 `# ─── Claude Code ───` 섹션 아래에 (탭 구분):
```
f	cw	대기 중 claude 세션 fzf 이동 (waiting-first)	claude
```

- [ ] **Step 2: 등록 확인**

Run: `grep -qP '^f\tcw\t' ~/.zsh.after/msbaek.cheats && echo OK || echo FAIL`
Expected: `OK`

- [ ] **Step 3: 커밋 (dotfiles)**

```bash
git -C ~/dotfiles add .zsh.after/msbaek.cheats
git -C ~/dotfiles commit --no-verify -m "docs(cheats): cw 를 mshelp 에 등록"
```

---

### Task 6: E2E walking-skeleton 수동 검증

**Files:** (없음 — 검증만)

- [ ] **Step 1: 두 repo에서 claude 실행 (tmux 창 2개)**

`work` 세션에 창 2개를 만들고 각각 다른 repo에서 `claude` 실행. 한쪽에 질문을 던져 응답이 끝나 **Stop**이 발화되게 함(그 세션이 waiting이 되어야 함).

- [ ] **Step 2: 상태 기록 확인**

Run: `tmux list-panes -a -F '#{@cc_state} #{session_name}:#{window_index} #{pane_current_path}' | grep -v '^ '`
Expected: 방금 턴을 마친 세션이 `waiting`, 작업 중인 세션이 `running` 으로 표시.

- [ ] **Step 3: `cw` 로 이동**

hub(또는 다른 pane)에서 `cw` 실행 → 목록 최상단에 waiting 세션 → Enter → 해당 pane으로 이동 확인.

- [ ] **Step 4: 복귀**

`prefix + a` → abtop hub로 복귀 확인.

- [ ] **Step 5: 최종 확인 & spec Status 갱신**

승인 조건 §2의 1~6 항목을 하나씩 눈으로 확인. spec 파일 `Status: draft` → `Status: v1 구현 완료`로 갱신 후 dotfiles에 커밋.

---

## Phase 2 — 이후 Layer (YAGNI: 필요할 때 개별 계획)

walking skeleton 동작 확인 후, 원하는 것부터 별도 task로:

- **tmux 상태줄 마커**: `window-status-format`에 `@cc_state` 기호 반영 → 상시 시각화.
- **macOS push 알림**: `Stop`/`Notification` 훅에서 detached 세션일 때 `osascript`/소리 → claude 대기까지 최소화. (attached 세션 제외 로직 필요)
- **idle `cct` 연동**: 오래된 idle 세션을 `cct` 정리 후보로 넘겨 자원 회수.
- **quick-terminal 최종화**: ghostty `global:` keybind + 손쉬운 사용 권한, hub를 quick-terminal에 배치, 점프 시 메인 client 타겟(`switch-client -c <main> -t <target>`)으로 복귀 = `⌘⌥T`. (ghostty config의 TRIAL 블록 정리)

---

## Self-Review

- **Spec 커버리지**: §2 승인조건 1~6 → Task 1(상태전이)·Task 3(cw waiting-first/이동)·Task 4(복귀)·Task 1(SubagentStop 제외)·Global Constraints(no-kill)로 모두 커버. §7 저장소=tmux 옵션 → Task 1. §9 표시 → Task 3(상태줄 마커는 Phase 2). §11 산출물 매핑 → 각 task 커밋 대상 repo 명시.
- **Placeholder 스캔**: 모든 코드 step에 실제 코드/명령/기대출력 포함. "적절한 에러처리" 류 없음.
- **타입/이름 일관성**: `@cc_state`/`@cc_since`(Task1 write ↔ Task3 read), `_cw_rows` 입력 `state|since|target|path|pane_id`(cw의 list-panes 포맷과 필드 순서 일치), `cc-attention.sh`(Task1 생성 ↔ Task2 등록 커맨드) 일치 확인.
- **알려진 한계**: `_cw_rows` 입력 구분자 `|` → `pane_current_path`에 `|` 포함 시 파싱 실패(개발 머신에선 사실상 없음). Task 3 자기 pane 제외는 "cw 실행 pane"만 — 여러 client로 다른 pane을 보는 경우의 정밀 제외는 Phase 2.
