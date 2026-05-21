# implementation-notes 프롬프트 (SSoT)

> executing-plans 단계에서 "plan에 없던 것이 구현 중 발견되는 순간"을 캡처하는 running log.
> 출처: trq212 X 글의 implementation-notes 패턴을 superpowers 워크플로우에 맞춰 변환.

## 언제 쓰나

- **executing-plans 단계 전용.** brainstorming/writing-plans 단계에는 쓰지 않는다 — 그 단계의
  open question·design decision·tradeoff는 plan 문서(Constraints / Failure Conditions / ADR)에
  사전 박제되는 것이 정석이다.
- writing-plans로 만든 plan을 실행하는데, plan이 짧지 않거나 모호함이 남아 있을 때.
- 한 번에 끝나는 단순 수정에는 불필요.

## 붙여넣을 프롬프트

executing-plans를 시작할 때(또는 subagent-driven-development의 각 Task 프롬프트에) 아래를 추가:

---

이 plan을 실행하면서 plan 폴더에 `implementation-notes.md`를 **append-only**로 유지하라.
plan에 **명시되지 않은** 것만 기록한다 (plan에 이미 있는 design decision은 중복 금지):

- **Deviation** — plan에서 의도적으로 벗어난 곳과 그 이유.
  → 단순 기록에 그치지 말고 plan 파일도 동기 업데이트해 plan을 SSoT로 유지한다.
- **New open question** — plan을 짤 때는 안 보였다가 구현 중 드러난 모호함.
  → 노트만 하고 넘어가지 말고 추측 없이 사용자에게 escalate한다.
- **Tradeoff** — 실행 중 마주친 갈림길에서 고려한 대안과 선택 근거.
  아키텍처 수준이면 ADR로 승격을 제안한다.

각 항목은 `## YYYY-MM-DD HH:MM | <Task>` 헤더 + 2~6줄. 발견 즉시 append.

---

## 파일 위치 규약

| plan 종류 | implementation-notes 위치 |
|---|---|
| 세션 포인터 plan (`.claude/plans/YYYY-MM-DD-topic/`) | 같은 폴더 안 `implementation-notes.md` |
| git-tracked plan (`docs/superpowers/plans/`) | 같은 폴더 안 `implementation-notes.md` |

- 확장자는 `.md` (원글의 `.html` 아님 — 이 환경의 SSoT는 markdown).
- 세션 종료 시 `/session-handoff`가 이 파일을 다음 세션 context로 함께 넘긴다.

## 왜 executing 전용인가 (범주 정리)

원글의 4개 카테고리는 superpowers 단계에 분산된다:

| 카테고리 | 사전 흡수 위치 | implementation-notes 역할 |
|---|---|---|
| Open questions | brainstorming (ask-don't-guess) | 실행 중 *새로* 터진 것만 |
| Design decisions | writing-plans (Constraints) | — (plan이 SSoT, 중복 금지) |
| Tradeoffs | writing-plans → ADR | 실행 중 마주친 갈림길만 |
| Deviations | (사전 불가) | **고유 영역** — plan 대비 실제 이탈 |

핵심: implementation-notes는 사용자 escalate를 **대체하지 않고 보강**한다.
"침묵으로 우회·shortcut 금지" 원칙과 충돌하지 않도록, open question은 반드시 escalate한다.
