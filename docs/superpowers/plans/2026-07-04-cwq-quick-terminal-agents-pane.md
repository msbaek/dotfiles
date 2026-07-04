# cwq — Quick Terminal Agents Pane Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** herdr의 "agents pane" 한 기능을 이관 없이 tmux 환경에 이식 — Ghostty quick terminal에서 Claude 세션 상태(🔴대기/🟢작업/⚪idle) 목록을 보고, 선택하면 해당 tmux session/window/pane으로 점프하며 quick terminal이 자동으로 닫힌다.

**Architecture:** cc-attention.sh가 이미 각 pane에 기록하는 `@cc_state`/`@cc_since`를 데이터 소스로 재사용한다(새 상태 수집 없음). `cw`의 `_cw_rows`(상태 포맷·waiting-first 정렬)와 `_cw_wid_for_session`(세션명→ghostty 창 id 매핑)을 재사용하고, quick terminal 전용 점프 프리미티브 `_cwq_jump`와 fzf 루프 `cwq`를 `cw.zsh`에 추가한다. Ghostty 1.3.x에는 quick terminal을 제어하는 CLI/IPC가 없고 autohide가 aerospace focus에는 걸리지 않으므로, dismiss는 전역 토글 키(`cmd+alt+t`)를 `osascript`로 합성한다(`_cwq_dismiss`, 교체 가능하게 분리).

**Tech Stack:** zsh functions, tmux CLI(`select-window`/`select-pane`/`list-panes`), fzf, aerospace CLI, osascript(System Events), Ghostty quick terminal.

## Global Constraints

- 기존 `cw` / `cj` / `_cc_goto` / `.tmux.conf` / aerospace 설정을 **변경하지 않는다** — 추가만 한다.
- `_cwq_jump`는 **절대** `tmux attach`(현재 터미널) · `switch-client` · `cur` 세션 비교를 하지 않는다. 항상 `select-window` + `select-pane` + dismiss + aerospace focus(대상 세션 창 있음) 또는 `open` 새 창(detached).
- 커밋은 `git commit --no-verify` (pre-commit stash로 인한 unstaged 유실 버그 회피 — 이 repo 규약).
- alias/function 추가 시 `.zsh.after/msbaek.cheats`도 함께 갱신(mshelp는 cheats만 읽음).
- 테스트 하네스는 기존 `test-cw.zsh` 패턴을 따른다: 외부 명령(`tmux`/`aerospace`/`open`/`osascript`)을 zsh function으로 stub 처리해 호출 로그를 grep으로 검증, subshell로 격리.
- 데이터 소스는 기존 pane 옵션 `@cc_state`/`@cc_since`뿐 — 새 훅·상태 수집 로직 추가 금지.

---

## File Structure

- **Modify** `.zsh.after/cw.zsh` — 함수 3개 추가: `_cwq_dismiss`(quick terminal 닫기), `_cwq_jump`(quick terminal 전용 점프), `cwq`(fzf agents pane 루프). 기존 `_cw_rows`·`_cw_wid_for_session` 재사용.
- **Modify** `.zsh.after/tests/test-cw.zsh` — `_cwq_jump` stub 테스트(창 있음/detached/빈 target) 추가.
- **Modify** `.zsh.after/msbaek.cheats` — `cwq` 항목 1줄 추가.

범위 밖(v2, 이번 plan 아님): fzf `--preview`로 에이전트 최근 출력 표시, quick terminal 자동 시작, live reload. Walking skeleton(목록+상태+점프+dismiss) 확정 후 별도 plan.

---

## Task 1: `_cwq_jump` + `_cwq_dismiss` — quick terminal 전용 점프 프리미티브

핵심 신규 로직. `_cc_goto`를 재사용하지 못하는 이유: 그건 tmux 밖에서 `tmux attach`로 빠지고(quick terminal 안에서 attach됨), `cur=$(tmux display …)` 비교가 밖에서는 임의 세션을 반환해 `[ "$sess" = "$cur" ] && return`이 focus를 건너뛴다. quick terminal 점프는 "같은 세션" 개념이 없으므로 항상 select+dismiss+focus로 직행해야 한다.

**Files:**
- Modify: `.zsh.after/cw.zsh` (파일 끝에 추가)
- Test: `.zsh.after/tests/test-cw.zsh` (`ALL PASS` 라인 앞에 추가)

**Interfaces:**
- Consumes: `_cw_wid_for_session <sess>` (기존, cw.zsh) — aerospace `wid|app|title` 줄들을 stdin으로 받아 세션명이 일치하는 Ghostty 창 id 출력.
- Produces:
  - `_cwq_dismiss()` — 인자 없음. quick terminal을 닫음(전역 토글 키 합성).
  - `_cwq_jump <target>` — `target` = `session:window.pane`. 빈 값이면 no-op.

- [ ] **Step 1: `_cwq_jump` 실패 테스트 작성**

`.zsh.after/tests/test-cw.zsh`의 `[ $fail -eq 0 ] && echo "ALL PASS"` 라인 **바로 앞**에 추가:

```zsh
# --- _cwq_jump: quick terminal 전용 점프 (tmux/aerospace/open/osascript stub) ---
# _cwqjump_calls <target> <aerospace_windows>: stub 환경에서 _cwq_jump 실행 → 호출 로그 stdout.
# _goto_calls 와 달리 TMUX 를 세팅하지 않는다(_cwq_jump 는 $TMUX 를 검사하지 않음).
_cwqjump_calls() {
  local _gtarget="$1" _gwins="$2" log; log=$(mktemp)
  (
    tmux()      { print -r -- "tmux $*" >>"$log"; }
    aerospace() { print -r -- "aerospace $*" >>"$log"; [[ "$*" == *list-windows* ]] && print -r -- "$_gwins"; }
    open()      { print -r -- "open $*" >>"$log"; }
    osascript() { print -r -- "osascript $*" >>"$log"; }
    _cwq_jump "$_gtarget"
  )
  cat "$log"; rm -f "$log"
}

# 케이스A: 대상 세션의 ghostty 창 있음 → select-window/pane + dismiss(osascript) + aerospace focus.
#   attach/switch-client/open 은 없어야 함.
log=$(_cwqjump_calls "memo:3.0" "343|Ghostty|memo")
echo "$log" | grep -q 'tmux select-window -t memo:3'  || { echo "FAIL cwqjump-A: select-window 미호출 [$log]"; fail=1; }
echo "$log" | grep -q 'tmux select-pane -t memo:3.0'  || { echo "FAIL cwqjump-A: select-pane 미호출 [$log]"; fail=1; }
echo "$log" | grep -q 'osascript'                     || { echo "FAIL cwqjump-A: dismiss(osascript) 미호출 [$log]"; fail=1; }
echo "$log" | grep -q 'aerospace focus'               || { echo "FAIL cwqjump-A: aerospace focus 미호출 [$log]"; fail=1; }
echo "$log" | grep -qE 'tmux attach|switch-client|^open ' && { echo "FAIL cwqjump-A: attach/switch/open 호출됨 [$log]"; fail=1; }

# 케이스B: detached(그 세션 창 없음) → select + dismiss + open 새 창. aerospace focus 없음.
log=$(_cwqjump_calls "memo:3.0" "342|Ghostty|work")
echo "$log" | grep -q 'open .*attach -t memo' || { echo "FAIL cwqjump-B: 새 창 open 미호출 [$log]"; fail=1; }
echo "$log" | grep -q 'aerospace focus'       && { echo "FAIL cwqjump-B: 창 없는데 focus 호출 [$log]"; fail=1; }
echo "$log" | grep -q 'osascript'             || { echo "FAIL cwqjump-B: dismiss 미호출 [$log]"; fail=1; }

# 케이스C: 빈 target → no-op(아무 호출 없음)
log=$(_cwqjump_calls "" "343|Ghostty|memo")
[ -z "$log" ] || { echo "FAIL cwqjump-empty: 빈 target인데 호출됨 [$log]"; fail=1; }
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `zsh ~/dotfiles/.zsh.after/tests/test-cw.zsh`
Expected: FAIL (예: `FAIL cwqjump-A: select-window 미호출` — `_cwq_jump` 미정의로 아무 호출도 로그되지 않음)

- [ ] **Step 3: `_cwq_dismiss` + `_cwq_jump` 구현**

`.zsh.after/cw.zsh` 파일 **끝**에 추가:

```zsh
# _cwq_dismiss: quick terminal 을 닫는다. Ghostty 1.3.x 는 quick terminal 제어 IPC 가 없고
# autohide 가 aerospace focus 에는 걸리지 않으므로, 전역 토글 키(cmd+alt+t=key code 17)를
# osascript 로 합성한다. 합성 키가 불안정하면 hammerspoon 으로 교체(이 함수만 바꾸면 됨).
_cwq_dismiss() {
  osascript -e 'tell application "System Events" to key code 17 using {command down, option down}' 2>/dev/null
}

# _cwq_jump <target> (session:window.pane): quick terminal 전용 점프.
# _cc_goto 와 달리 attach·cur비교 없이 항상 select → dismiss → focus.
# 대상 세션의 ghostty 창이 있으면 aerospace focus, 없으면(detached) 새 ghostty 창에서 attach.
_cwq_jump() {
  local target="$1"
  [ -n "$target" ] || return
  local sess="${target%%:*}" win="${target%.*}"

  # 대상 세션의 활성 window/pane 설정 (attach 불필요, 서버측에서 동작)
  tmux select-window -t "$win" 2>/dev/null
  tmux select-pane -t "$target" 2>/dev/null

  # quick terminal 닫기 (aerospace focus 전에 오버레이를 걷어냄)
  _cwq_dismiss

  # 대상 세션의 ghostty 창을 aerospace 로 focus
  local wid
  wid=$(aerospace list-windows --all --format '%{window-id}|%{app-name}|%{window-title}' 2>/dev/null | _cw_wid_for_session "$sess")
  if [ -n "$wid" ]; then
    aerospace focus --window-id "$wid" 2>/dev/null
  else
    # 열린 창 없음(detached) → 새 ghostty 창에서 attach
    open -na Ghostty --args -e tmux attach -t "$sess"
  fi
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `zsh ~/dotfiles/.zsh.after/tests/test-cw.zsh`
Expected: PASS (`ALL PASS`) — 기존 `_cw_rows`/`_cw_wid_for_session`/`_cc_goto` 테스트 + 신규 `_cwq_jump` 3케이스 모두 통과

- [ ] **Step 5: 커밋**

```bash
cd ~/dotfiles
git add .zsh.after/cw.zsh .zsh.after/tests/test-cw.zsh
git commit --no-verify -m "feat(cwq): quick terminal 전용 점프 프리미티브 _cwq_jump/_cwq_dismiss"
```

---

## Task 2: `cwq` fzf 루프 + cheats + walking skeleton E2E 검증

fzf 루프는 대화형이라 단위 테스트 대상이 아니다(목록 생성은 Task 1 이전의 `_cw_rows` 테스트가 이미 커버, 점프는 Task 1이 커버). 이 Task의 검증은 **수동 walking skeleton E2E** — 특히 osascript dismiss가 실제로 quick terminal을 닫는지(유일한 미검증 가정)를 확인한다.

**Files:**
- Modify: `.zsh.after/cw.zsh` (`_cwq_jump` 아래에 `cwq` 추가)
- Modify: `.zsh.after/msbaek.cheats`

**Interfaces:**
- Consumes: `_cw_rows`(기존), `_cwq_jump`(Task 1).
- Produces: `cwq()` — 인자 없음. quick terminal에서 실행하는 무한 루프 agents pane(Esc/Ctrl-C로 종료).

- [ ] **Step 1: `cwq` 함수 구현**

`.zsh.after/cw.zsh`의 `_cwq_jump` 정의 **아래**에 추가:

```zsh
# cwq: quick terminal 에서 실행하는 agents pane. @cc_state 기반 대기(🔴)/작업(🟢)/idle(⚪)
# 목록(waiting-first) → 선택 시 해당 세션으로 점프 + quick terminal 자동 닫힘. Esc/Ctrl-C 로 종료.
# cw 와 달리 tmux 밖(quick terminal)에서 도므로 self-pane 제외가 없다.
cwq() {
  local sel target
  while true; do
    sel=$(tmux list-panes -a -F '#{@cc_state}|#{@cc_since}|#{session_name}:#{window_index}.#{pane_index}|#{pane_current_path}|#{pane_id}' 2>/dev/null \
          | _cw_rows \
          | fzf --ansi --delimiter=$'\t' --with-nth=2 \
                --header='🔴 대기 / 🟢 작업 / ⚪ idle │ Enter=이동 · Esc=닫기' --reverse) || break
    target="${sel##*$'\t'}"
    _cwq_jump "$target"
  done
}
```

- [ ] **Step 2: 함수 로드 스모크 확인**

Run: `zsh -c 'source ~/.zsh.after/cw.zsh; type cwq _cwq_jump _cwq_dismiss'`
Expected: 셋 다 `... is a shell function`으로 출력(구문 오류 없이 로드됨)

- [ ] **Step 3: cheats 항목 추가**

`.zsh.after/msbaek.cheats`에서 `cj` 항목(`f\tcj\t...\tclaude`) **바로 아래**에 추가(탭 구분):

```
f	cwq	quick terminal agents pane — 상태 목록→점프+자동 닫힘	claude
```

확인: `grep -P '^f\tcwq\t' ~/dotfiles/.zsh.after/msbaek.cheats` → 1줄 출력

- [ ] **Step 4: walking skeleton E2E 수동 검증 (핵심 — dismiss 가정 확인)**

새 셸에서 설정 로드: `exec zsh` (또는 `source ~/.zsh.after/cw.zsh`).
전제: Claude 세션이 도는 tmux pane이 최소 1개 있어(`@cc_state` 존재), aerospace로 창 매핑이 됨.

1. quick terminal 열기: `cmd+alt+t`
2. quick terminal 안에서 `cwq` 실행 → 🔴/🟢/⚪ 목록이 뜨는지 확인
3. 대상 세션 하나를 Enter로 선택
4. **확인 사항**:
   - (a) 대상 세션의 ghostty 창이 앞으로 오는가(aerospace focus)?
   - (b) **quick terminal이 자동으로 닫히는가(osascript dismiss)?** ← 유일한 미검증 가정
   - (c) 대상 pane이 그 세션의 활성 window/pane으로 맞춰졌는가(select-window/pane)?

**판정:**
- (a)(b)(c) 모두 OK → walking skeleton 완성. Step 5로.
- (b)만 실패(창은 갔는데 quick terminal이 안 닫힘) → osascript 합성이 이 환경에서 안 통함. **Fallback**: `_cwq_dismiss`를 hammerspoon 호출로 교체(별도 follow-up Task). 점프 자체는 동작하므로 walking skeleton은 "dismiss 미완"으로 기록하고 진행 여부는 사용자와 상의.
- (a)/(c) 실패 → `_cwq_jump`/aerospace 매핑 문제 → Task 1 테스트/`_cw_wid_for_session` 재점검.

- [ ] **Step 5: 커밋**

```bash
cd ~/dotfiles
git add .zsh.after/cw.zsh .zsh.after/msbaek.cheats
git commit --no-verify -m "feat(cwq): quick terminal agents pane 루프 + cheats 등록"
```

---

## Self-Review

**1. Spec coverage** — 설계 요구사항 대비:
- 목록+상태(🔴🟢⚪, waiting-first): `cwq`가 `_cw_rows` 재사용(Task 2) ✓
- 선택 시 tmux session/window/pane 이동: `_cwq_jump`의 select-window/select-pane + aerospace focus(Task 1) ✓
- quick terminal 자동 닫힘: `_cwq_dismiss`(Task 1) + E2E 검증(Task 2 Step 4) ✓
- 기존 cw/cj/_cc_goto 불변: 추가만, 기존 함수 미수정 ✓
- 데이터 소스 재사용(@cc_state): `cwq`의 list-panes -F(Task 2) ✓

**2. Placeholder scan** — TBD/TODO/"적절히 처리" 없음. 모든 코드 step에 실제 코드·명령·기대 출력 포함 ✓. Task 2 Step 4의 fallback은 조건부 분기(placeholder 아님, YAGNI로 hammerspoon 경로는 실패 시에만 구축) ✓.

**3. Type consistency** — 함수/인자 시그니처 일관성:
- `_cwq_jump <target=session:window.pane>` — Task 1 정의, Task 2 `cwq`에서 `_cwq_jump "$target"`로 호출(동일) ✓
- `_cwq_dismiss`(무인자) — Task 1 정의, `_cwq_jump`에서 호출 ✓
- `_cw_wid_for_session <sess>` — 기존 cw.zsh 시그니처 그대로 소비 ✓
- 테스트 stub 변수 `_g*` prefix — 기존 `_goto_calls` 관례와 동일(dynamic-scope 충돌 방지) ✓
