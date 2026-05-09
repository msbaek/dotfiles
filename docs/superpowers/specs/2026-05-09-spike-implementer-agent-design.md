# spike-implementer Agent — Design Spec

- **Status**: Approved (brainstorming complete, awaiting user spec review → writing-plans)
- **Date**: 2026-05-09
- **Author**: msbaek (with Claude Opus 4.7)
- **Agent location**: `~/.claude/agents/spike-implementer.md`
- **Related skill**: `~/.claude/skills/spike-and-stabilize/SKILL.md`
- **Related spec**: `docs/superpowers/specs/2026-05-09-spike-and-stabilize-design.md`

---

## 1. Goal

`spike-and-stabilize` skill의 **Phase 1(Quick Pass)**을 전담하는 sub-agent를 만든다. main context는 적합성 판단·brainstorming·acceptance test 정의·Transition Gate 사용자 대화에 집중하고, agent는 quick & dirty 구현 + 학습 캡처에 집중하여 **책임 분리 + main context 토큰 절약**을 달성한다.

### Non-Goals

- Phase 2(Stabilize) 처리 — Phase 2는 main context에서 `superpowers:writing-plans` skill로 직접 진행
- Acceptance test 정의·작성 — agent가 받기 전에 main context에서 사용자와 대화하며 정의
- 적합성 판단(spike 모드 발동 여부) — main context의 SKILL.md HARD-GATE에서 처리
- 사용자 대화 — sub-agent는 isolated context이므로 사용자와 직접 상호작용 불가

## 2. 배경 — 왜 sub-agent로 분리하는가

| 이유 | 효과 |
|---|---|
| Phase 1 구현은 main context에 무관한 mechanical 작업 | main context 토큰 절약 |
| Quick & dirty 구현 시 일시적으로 "허용된 나쁜 코드"가 컨텍스트를 오염시킴 | 학습 후 isolated 컨텍스트로 정리 |
| 학습 캡처를 일관된 출력 형식으로 강제 | Transition Gate 메시지를 main context가 그대로 사용 |
| Phase 1 진행 중 main context는 다른 사고에 집중 가능 | 비동기 협업 가능성 (현재는 동기 위임) |

## 3. Agent 명세

### 3.1 이름·위치

- **이름**: `spike-implementer`
- **위치**: `~/.claude/agents/spike-implementer.md`

### 3.2 Frontmatter

```yaml
---
name: spike-implementer
description: >
  Use when spike-and-stabilize skill needs to execute Phase 1 (Quick & Dirty E2E).
  Receives a defined acceptance test from main context, implements minimal code
  to make it green, captures learning bullets, and recommends Phase 2 path
  (refactor / rewrite / keep). Does NOT define acceptance tests, does NOT decide
  spike mode appropriateness, does NOT interact with user — those belong in
  main context. Always returns structured output for Transition Gate.
model: sonnet
tools: Read, Write, Edit, Bash, Grep, Glob, TodoWrite
---
```

### 3.3 Tool 선택 근거

| Tool | 용도 | 포함? |
|---|---|---|
| Read, Write, Edit | 코드 파일 작성·수정 | ✅ |
| Bash | acceptance test 실행, git status/diff | ✅ |
| Grep, Glob | 코드베이스 탐색 | ✅ |
| TodoWrite | Phase 1 5단계 진행 추적 | ✅ |
| Agent | 중첩 dispatch (단순화 위해 금지) | ❌ |
| Task* | 메타 task 도구, agent 본분 외 | ❌ |
| 외부 MCP (Serena, github, …) | 보통 불필요, 필요시 명시적 추가 검토 | ❌ |

### 3.4 Model 근거

`sonnet` (Sonnet 4.6):
- Phase 1은 acceptance test green 만들기 = mechanical implementation → sonnet 적합
- 학습 캡처(구조 평가·도메인 개념 발견)에는 약간의 판단력 필요 → haiku보다 sonnet
- opus는 과잉 (비용·속도 trade-off 부적합)

## 4. Interface

### 4.1 입력 (main context → agent dispatch 시 prompt에 포함)

main context는 다음 5개 요소를 prompt에 명시해 dispatch:

1. **문제 설명** — 1줄
2. **승인 조건** — 1–3 bullet, brainstorming에서 합의된 것
3. **Acceptance test 코드** — 이미 작성된 fail 상태의 외부 행위 검증 코드 (또는 명확한 정의)
4. **작업 디렉토리 + 관련 파일 경로** — agent가 어디를 수정해야 하는지
5. **범위/시간 제한** — 예: "happy path 1개, 한 세션 내, 1일 최대"

### 4.2 출력 (agent → main context 리턴, 형식 고정)

agent는 작업 완료 후 정확히 다음 형식으로 응답:

```
## Phase 1 결과

**진입 선언:** Phase 1 시작. 범위: [범위]. 예상: [시간/세션 수]

**Acceptance test:** [test 이름 또는 path] — [green | red]

**수정 파일:**
- [경로 1]
- [경로 2]
- ...

### 학습 사항 (3–7개)
- [발견한 도메인 개념·이름 후보]
- [추가 필요 시나리오: edge case, error path, 추가 happy path]
- [구조적 결함: 계층 꼬임, 책임 혼재, 도메인 모델 오류]
- [in-place refactor 가능성: high / medium / low]

### 권장 경로
- 권장: [refactor / rewrite / keep]
- 근거: [1–2줄]

STATUS: DONE | DONE_WITH_CONCERNS [설명] | BLOCKED [사유]
```

main context는 이 출력을 받아 **Transition Gate 메시지** (SKILL.md 정의 형식)를 사용자에게 그대로 보여주고 OK 대기.

### 4.3 STATUS 의미

- `DONE`: acceptance test green + 학습 사항 캡처 완료 → Transition Gate 진행
- `DONE_WITH_CONCERNS`: 완료했지만 우려 사항 있음 (예: scope 모호, 추가 가정) → main context가 검토 후 Gate 진행 또는 추가 질문
- `BLOCKED`: 진입 차단 사유 (예: acceptance test 정의 불충분, 코드베이스 접근 불가) → main context가 보강

## 5. SKILL.md 변경

`~/.claude/skills/spike-and-stabilize/SKILL.md` Phase 1 섹션 말미에 한 줄 추가:

> _구현 단계(절차 3)는 `spike-implementer` agent로 dispatch한다. main context는 절차 1·2(약식 brainstorming, acceptance test 정의)와 절차 5 직후 Transition Gate를 책임진다._

위치: Phase 1 절차의 "5. 학습 사항 캡처" 다음, "Phase 1 위반 신호" 직전.

## 6. 흐름

```
사용자: /spike → spike-and-stabilize skill 발동
  ↓
main context:
  • HARD-GATE 통과 확인 (적합성)
  • 진입 시 한 줄 선언 출력
  • 약식 brainstorming (사용자 대화)
  • Acceptance test 정의·작성 (사용자 대화 + 코드 작성)
  ↓
main context → spike-implementer agent dispatch
  • 입력: 문제, 승인 조건, acceptance test 코드, 파일 경로, 시간 제한
  ↓
spike-implementer agent (isolated context):
  • Quick pass 구현 (단일 파일 / 하드코딩 / unit test 생략)
  • acceptance test 실행 → green 확인
  • 학습 사항 bullet 캡처 (3–7개)
  • 구조 평가 + 경로 권장
  • 형식화된 출력 + STATUS 리턴
  ↓
main context:
  • agent 출력을 Transition Gate 메시지로 변환
  • 사용자에게 보여주고 OK 대기
  ↓
사용자 OK → Phase 2 (writing-plans skill 호출)
사용자 거부/나중 → Phase 1 결과 보존, skill 종료
```

## 7. Failure Conditions

agent가 거부하거나 BLOCKED을 리턴해야 할 신호:

1. **Acceptance test 코드 누락 또는 모호** — main context에서 충분히 정의되지 않은 경우 BLOCKED
2. **승인 조건이 외부 행위로 표현되지 않음** — 내부 구조 의존 → BLOCKED
3. **작업 디렉토리·파일 경로 부재** — 어디를 수정해야 하는지 불명 → BLOCKED
4. **시간 제한 초과 임박** — Phase 1 무한 확장 위험 → DONE_WITH_CONCERNS로 중간 상태 리턴
5. **agent 안에서 사용자 대화 시도** — sub-agent 제약 위반, 즉시 중단 + BLOCKED
6. **Phase 1에서 unit test 작성** — skill 의도와 충돌, 학습 캡처에 명시 후 제외
7. **acceptance test green 미달성 + 시간 제한 초과** — BLOCKED, main context가 scope 분해 결정

## 8. 예시 시나리오

### 예시 A — 정상 흐름 (예시 A from skill spec 재사용)

main context dispatch prompt (요약):
```
문제: OMS multi-warehouse 재고 차감 로직.
승인 조건:
  - order 1건(5 SKU) / warehouse 2곳 차감 → confirmed
  - 재고 부족 시 → backorder
Acceptance test (fail 상태):
  src/test/java/.../OrderConfirmAcceptanceTest.java
  ::test_confirmOrder_with_two_warehouses
작업 디렉토리: /Users/me/oms
관련 파일: src/main/java/.../OrderService.java (현재 빈 메서드)
범위: happy path 1개. 예상: 1세션.
```

agent 리턴:
```
## Phase 1 결과

**진입 선언:** Phase 1 시작. 범위: order 1건 / warehouse 2곳 차감 happy path. 예상: 1세션.

**Acceptance test:** OrderConfirmAcceptanceTest::test_confirmOrder_with_two_warehouses — green

**수정 파일:**
- src/main/java/.../OrderService.java
- src/main/java/.../WarehouseStock.java (신규, 단일 파일)

### 학습 사항 (4개)
- warehouse 선택 알고리즘이 별도 도메인 개념(WarehouseSelectionPolicy)
- stock 차감 시 concurrency(낙관적 락) 미고려
- partial fulfillment 시나리오 누락 (order 절반만 충족)
- 구조 평가: high (refactor 가능)

### 권장 경로
- 권장: refactor
- 근거: 계층은 OK, WarehouseSelectionPolicy 추출과 stock 도메인 정리만 필요

STATUS: DONE
```

main context: 이 출력을 SKILL.md Transition Gate 형식으로 변환 → 사용자에게 보여주고 OK 대기.

### 예시 B — BLOCKED 케이스

main context dispatch prompt (불충분):
```
문제: 결제 시스템 만들기.
승인 조건: 잘 동작해야 함.
Acceptance test: (없음, "테스트는 알아서 만들어줘")
```

agent 리턴:
```
STATUS: BLOCKED
사유: Acceptance test 정의 부재 + 승인 조건이 외부 행위로 명시되지 않음.
main context에서 brainstorming 추가 후 재dispatch 필요.

권장 acceptance test 후보:
- charge(orderId, amount) → returns Receipt with status=success
- (외부 행위로 검증 가능한 다른 진입점)
```

## 9. Open Questions / Future Work

- **Acceptance test 작성을 agent에 일부 위임**: 현재는 main context 책임이지만, 단순한 외부 행위(예: 단일 함수 호출 + 결과 비교)는 agent가 작성해도 무방. 사용 패턴 보고 추후 결정.
- **여러 acceptance test**: 현재 spec은 1개 가정. 2–3개로 늘어나면 prompt 형식 확장 필요.
- **agent 실패 시 자동 재시도**: BLOCKED → main context 보강 → 재dispatch가 수동. 자주 BLOCKED되면 자동 재시도 루프 검토.
- **다른 skill에서 재사용**: spike-implementer는 spike-and-stabilize 전용으로 설계됐지만, 비슷한 "fail 상태 test → quick pass" 패턴이 있으면 재사용 가능. 발견 시 description 일반화 검토.

## 10. Implementation Plan

다음 단계: `superpowers:writing-plans` skill 호출하여 본 spec 기반 구현 plan 작성.

예상 task:
1. `spike-implementer.md` 파일 작성
2. `SKILL.md` 수정 (Phase 1 절차에 dispatch 안내 한 줄 추가)
3. Spec 대조 검토
4. Commit
