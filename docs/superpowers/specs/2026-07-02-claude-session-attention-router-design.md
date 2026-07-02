# Claude 세션 Attention Router — 설계

- **날짜**: 2026-07-02
- **Status**: draft (사용자 리뷰 대기)
- **재사용 도구**: tmux, Claude Code hooks, abtop, ghostty quick-terminal, fzf, mshelp, cct
- **관련**: 이 작업은 stow repo 2개(`dotfiles`, `claude-config`)에 걸침 — §11 산출물 매핑 참조

---

## 1. 문제 정의

여러 repo(현재 8개 내외)에서 claude code를 동시에 돌린다. 지금 이 순간에도 claude
프로세스가 10개 실행 중이다. 문제는 **"어느 repo의 claude가 지금 내 응답을
기다리는지"를 한눈에 알 수 없다**는 것. 그래서:

- claude가 응답을 기다리는데 내가 모르고 방치 → **claude가 논다**.
- 나는 어디를 봐야 할지 몰라 이 창 저 창 뒤진다 → **내가 논다**.

기존 `abtop`(AI 코딩 에이전트 작업 관리자 TUI)이 세션 목록·토큰·rate-limit은 잘
보여주지만, **`idle / running / waiting(내 응답 대기)` 3-상태를 명확히 구분하지
못한다**. 또한 abtop에서 세션을 선택해 점프하면 **abtop이 있던 창/pane으로
돌아오기가 어렵다**.

## 2. 목표 & 승인 조건 (Acceptance Criteria)

**목표**: 여러 claude 세션 중 "내 응답을 기다리는" 것을 즉시 식별하고, 최소
마찰로 그 세션으로 이동하며, 돌아올 수 있게 하여 **claude와 나의 상호 대기 시간을
최소화**한다.

승인 조건(테스트 가능):

1. 임의 claude 세션이 턴을 마치면(Stop) 해당 세션이 **`waiting`으로 표시**된다.
2. 내가 그 세션에 프롬프트를 주면(UserPromptSubmit) **`running`으로 전이**된다.
3. `cw` 실행 시 **`waiting` 세션이 목록 최상단**에 오고, 선택하면 해당 tmux
   pane으로 **이동**한다.
4. 이동 후 **한 번의 키/단축키로 abtop(또는 hub)으로 복귀**한다.
5. teammate subagent(`SubagentStop`)는 목록에 **뜨지 않는다**.
6. **진행 중(running) 세션은 다른 repo로 이동해도 계속 실행**된다 (종료·kill 없음).

## 3. 제약 (non-negotiable)

- **진행 중 세션 유지**: running claude는 절대 자동 종료하지 않는다. (초기 "kill 후
  `--resume`" 방향은 **폐기** — §12)
- **abtop 존치**: abtop을 대체하지 않는다. 3-상태 명확화 + 복귀만 보강한다.
- **동시성 안전**: 10+ 세션이 동시에 훅을 쏴도 상태 저장이 깨지지 않아야 한다.
- **stow 규칙 준수**: 훅은 `claude-config`, 셸/tmux/ghostty는 `dotfiles`. (§11)
- **YAGNI**: walking skeleton부터. push 알림·상태줄·정리연동은 이후 layer.

## 4. 실패 조건 (Failure Conditions)

- 공유 JSON 파일에 상태를 쓰다가 동시 write race로 파일이 깨져 `cw`가 조용히
  빈 목록을 낸다.
- `SubagentStop`을 waiting으로 잡아 목록이 teammate로 도배된다.
- 지금 attach해서 보고 있는 세션까지 매 턴 `waiting`으로 떠서 소음이 된다.
- idle을 훅 이벤트로 만들려다 "타이머 훅 없음"에 막힌다.

## 5. 설계 개요

`abtop`은 그대로 두고, **"3-상태를 명확히 보여주는 얇은 레이어"를 Claude Code
훅으로 만든다.** 상태 저장소는 **별도 파일 없이 tmux 옵션**을 쓴다(동시성 안전 +
표시 마커와 저장소 일원화). 표시는 두 표면(온디맨드 `cw` fzf, 상시 tmux 상태줄),
복귀는 키바인드/quick-terminal로 해결한다.

```
[claude 훅]  --set tmux option-->  [tmux (pane 옵션 = 상태 저장소)]
   Stop/Notification → waiting                       |
   UserPromptSubmit  → running          read via `tmux list-panes -a`
   SessionStart      → idle                          |
   SubagentStop      → (무시)              [cw fzf]  [tmux 상태줄]
                                              |            |
                                        선택→ tmux switch-client (점프)
                                              |
                                        [prefix+a / ⌘⌥T] → abtop 복귀
```

## 6. 상태 모델

| 상태 | 의미 | 액션 |
|------|------|------|
| 🟢 `running` | claude 작업 중 (지시 → 처리 중) | 놔둠 |
| 🔴 `waiting` | **내 응답 대기** (Stop / Notification) | **여기로 이동** |
| ⚪ `idle` | 작업도 대기도 아님 (시작만 했거나, waiting이 오래 방치됨) | 정리 후보(`cct`) |

**전이 (훅 이벤트 → 상태)**:

- `SessionStart` → `idle`
- `UserPromptSubmit` → `running`
- `Stop` → `waiting`
- `Notification` → `waiting` (긴급; 단 §13 caveat 참조)
- `SessionEnd` → 상태 제거
- `SubagentStop` → **무시** (teammate subagent는 내가 답할 대상이 아님)

**idle은 훅이 set할 수 없다 → 읽는 시점에 시간으로 파생.** Stop 이후엔 내가 프롬프트를
줄 때까지 어떤 훅도 발화하지 않으므로(타이머 훅 없음) "waiting인데 오래 방치 = idle"을
이벤트로 만들 수단이 없다. 해법: 상태와 함께 **`@cc_since`(epoch)** 를 저장하고,
`cw`/상태줄이 읽는 순간 `now - since > N분`이면 idle로 렌더한다. **idle은 파생
상태이지 훅 상태가 아니다.**

## 7. 상태 저장소 — tmux 옵션 (핵심 아키텍처 결정)

공유 JSON 파일은 10+ 동시 write에서 race로 깨진다. 대신 **tmux 옵션을 유일한
저장소로** 쓴다.

- **쓰기(훅)**: pane 안에서 실행되므로 `$TMUX`/`$TMUX_PANE`가 상속됨(§13 검증됨).
  ```sh
  tmux set -p -t "$TMUX_PANE" @cc_state waiting
  tmux set -p -t "$TMUX_PANE" @cc_since "$(date +%s)"
  ```
  (`-p` = pane 스코프, 정확한 pane 타겟. 한 창에 claude가 하나면 `-w` 창 스코프도
  무방 — 구현 때 택1. pane 스코프가 다중 pane에 안전.)
- **읽기(`cw`/상태줄)**:
  ```sh
  tmux list-panes -a -F '#{@cc_state}	#{@cc_since}	#{session_name}:#{window_index}.#{pane_index}	#{pane_current_path}	#{pane_id}'
  ```
- **tmux 밖 세션**: `$TMUX`가 비면 훅은 **no-op**. (어차피 점프 대상도 아니므로
  scope가 자연히 깔끔해짐)
- 파일 0개 → 동시성 문제 소멸, 마커·저장소 일원화.

## 8. 훅

- 단일 디스패처 스크립트(예: `cc-attention.sh`)가 `hook_event_name`으로 분기.
- 입력: stdin JSON(`session_id`, `cwd`, `hook_event_name` 등) + env(`$TMUX_PANE`).
- `settings.json`에 `Stop`, `Notification`, `UserPromptSubmit`, `SessionStart`,
  `SessionEnd` 이벤트로 등록 (모두 **이미 등록되어 있음** — 디스패처만 추가).
- **`SubagentStop` 미등록** (도배 방지).
- 실패해도 claude 동작을 막지 않도록 방어적으로(빠른 exit 0).

## 9. 표시 표면

1. **`cw` fzf (온디맨드 점프)** — `tmux list-panes -a`를 읽어 상태별 기호/색으로
   렌더, **waiting-first 정렬**. Enter → `tmux switch-client -t <target>`.
   - **현재 attach해서 보고 있는 pane은 제외/디엠퍼시스** (§13 caveat).
   - `ts`(기존 fzf tmux picker)를 씨앗으로 확장.
2. **tmux 상태줄 마커 (상시, layer)** — 창 이름/상태줄에 `🔴/🟢/⚪ repo`. abtop을
   안 켜도 "누가 나를 기다리나"가 상시 보임. (v1.5)

## 10. 네비게이션 (G2 — 복귀)

- **기본**: tmux 키바인드 `bind a switch-client -t abtop` (또는 hub 세션) — 어느
  세션이든 한 키로 hub 복귀.
- **선택(quick-terminal)**: `cw`/abtop을 ghostty quick-terminal에 올리면 복귀 =
  `⌘⌥T`. 이때 점프는 *메인 창의 tmux client*를 타겟해야 hub가 안 사라짐:
  `tmux switch-client -c <main-client> -t <target>`. 그러면 `⌘⌥T`로 hub↔작업 토글.
  → **구현 때 client 타겟팅 검증** (fallback: 기본 키바인드).

## 11. 산출물 → repo 매핑 (stow 2개)

| 산출물 | repo | 경로 |
|--------|------|------|
| 훅 디스패처(`cc-attention.sh`) | `claude-config` | `~/.claude/hooks/` |
| `settings.json` 훅 등록 | `claude-config` | `~/.claude/settings.json` |
| `cw` 함수 | `dotfiles` | `~/.zsh.after/msbaek.zsh` |
| tmux 상태줄·키바인드 | `dotfiles` | `~/.tmux.conf` |
| ghostty quick-terminal keybind | `dotfiles` | `~/.config/ghostty/config` |
| `mshelp` cheats 등록 | `dotfiles` | `~/.zsh.after/msbaek.cheats` |

## 12. Walking Skeleton & 이후 Layer

**v1 (walking skeleton)** — E2E로 "waiting 감지 → 점프 → 복귀"만:

1. 훅 디스패처가 pane 옵션(`@cc_state`, `@cc_since`) 기록 (Stop/Notification/
   UserPromptSubmit/SessionStart/SessionEnd, SubagentStop 제외)
2. `cw` fzf: waiting-first → tmux 점프 (attached pane 제외)
3. abtop 복귀 키바인드 1개

**이후 layer** (원할 때 하나씩):

- tmux 상태줄 마커 (상시 시각화)
- macOS 알림/소리 push — waiting 진입 시 → **claude 대기까지 최소화**
- idle 세션 `cct` 연동 (자원 회수)
- `mshelp` cheats 등록 (발견성)
- quick-terminal client-타겟 복귀

## 13. 검증된 가정 & Caveats

**검증됨 (2026-07-02)**:

- 훅 환경에 `$TMUX_PANE`(`%44`), `$TMUX` 존재 — Bash 도구=훅과 동일한 claude
  자식 프로세스로 확인.
- `tmux set @cc_*` 쓰기 + `tmux list-panes -a -F '#{@cc_*}'` 읽기 동작.

**Caveats (구현 시 반영)**:

- **Stop은 매 턴 끝마다 발화** → 지금 attach해서 보고 있는 세션도 매 턴 waiting으로
  뜬다(이미 아는 세션 = 소음). `cw`/상태줄에서 **현재 attached pane 제외/디엠퍼시스**.
- **`cld` = `--dangerously-skip-permissions`** 주력 사용 → permission Notification이
  거의 안 뜬다. 즉 waiting 신호는 사실상 **Stop 단독**, Notification은 보너스.
- pane 옵션 vs 창 옵션 스코프: 한 창에 claude 여럿이면 pane(`-p`) 스코프 필요.

## 14. Out of Scope (YAGNI)

- 세션 자동 종료/kill, `--resume` 기반 kill-relaunch (제약 §3에 반함 — 폐기).
- 비-claude 프로세스 관리.
- abtop 자체 개조/대체.
