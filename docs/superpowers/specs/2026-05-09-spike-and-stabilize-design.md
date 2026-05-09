# Spike-and-Stabilize Skill — Design Spec

- **Status**: Approved (brainstorming complete, awaiting user spec review → writing-plans)
- **Date**: 2026-05-09
- **Author**: msbaek (with Claude Opus 4.7)
- **Skill location**: `~/.claude/skills/spike-and-stabilize/SKILL.md` (custom skill, user space — NOT plugin)
- **Related**: `~/.claude/CLAUDE.md` Section 2 "Problem-first workflow", `superpowers:brainstorming`, `superpowers:writing-plans`, `superpowers:executing-plans`, `superpowers:test-driven-development`

---

## 1. Goal

도메인·해법 경로가 불확실한 비자명 작업에서, **acceptance test를 안전망 삼아** 처음부터 끝까지 quick & dirty E2E를 한 번 통과시키고(Phase 1 Spike), 그 학습을 바탕으로 **in-place refactor 또는 재작성**으로 좋은 구조에 도달(Phase 2 Stabilize)한다. Phase 2는 기존 `writing-plans` / `executing-plans` 흐름으로 회귀.

### Non-Goals

- 기존 Problem-first workflow의 ④ Walking Skeleton 단계를 대체하지 않음. 별도 선택형 모드.
- 단순 명세형/CRUD 작업의 default 모드가 아님.
- Test 없이 코드만 짜는 모드가 아님 — acceptance test는 항상 필수.

## 2. Trigger

명시적 트리거에서만 발동. 자동 진입 금지.

- **Trigger phrases**: `/spike`, "스파이크로 가자", "퀵 앤 더티로 한 번 풀어보자", "일단 끝까지 한 번 가보자", "tracer bullet", "학습용으로 한 번 만들어보자"
- 트리거 phrase 외에도 의미가 같으면 자연어로 인정 (skill description의 fuzzy matching).
- Claude는 "이건 spike이 적합하다"는 자체 판단으로 진입하지 않는다 — 사용자 의도 표현이 있을 때만.

## 3. Constraints (non-negotiable)

1. **Acceptance test 필수** — Phase 1 quick pass 시작 전, 외부 행위만 검증하는 acceptance test 1개 이상 정의 (API / CLI / public 함수 호출 → 결과 검증). 구현 디테일에 의존성 없음.
2. **Phase 1에서 unit test 생략 가능** — 내부 구조 테스트는 Phase 2로 미룸. acceptance test는 작성·통과 필수.
3. **Phase 1은 시간/범위 제한** — Phase 1 진입 시 "예상 시간/범위" 한 줄 명시 후 시작. 한 세션 / 1일 초과 시 stop, 작업 분해 후 재시도.
4. **Phase 2 진입 gate** — acceptance test 1개 이상 green + Claude의 transition 메시지 + 사용자 OK 후에만 Phase 2 코드 변경 시작.
5. **Phase 2는 기존 워크플로우 호출** — `writing-plans` skill로 위임. 재발명 금지.
6. **Plugin 수정 금지** — `~/.claude/plugins/` 직접 수정 X. skill은 사용자 영역(`~/.claude/skills/spike-and-stabilize/`)에 위치.
7. **TDD 1법칙 일시 유보 명시** — Phase 1은 의도적으로 "no production code without failing test first"을 acceptance test 수준까지만 적용함을 SKILL.md에 명시 (사용자의 평소 TDD 철학과 충돌 없도록).

## 4. Phase 1 — Spike (Quick & Dirty E2E)

| 단계 | 내용 |
|---|---|
| 1. 약식 brainstorming | 문제 한 줄 + 승인 조건 1–3개. 시나리오는 **happy path 1개만** 선택. edge case·error path 무시. |
| 2. Acceptance test 정의·작성 | 외부 행위만 검증. 이 시점엔 fail 상태. |
| 3. Quick pass 구현 | *허용*: 단일 파일 / 하드코딩 / 인라인 / 중복 / 거친 이름. *생략*: unit test, 추상화, 에러 처리, 로깅, 일반화. 목표는 **acceptance test green** 단 하나. |
| 4. 통과 확인 | acceptance test green. 안 되면 Phase 2 진입 차단. |
| 5. 학습 사항 캡처 | bullet 3–7개:<br>• 발견한 도메인 개념·이름 후보<br>• 추가로 필요한 시나리오 (edge case, error path)<br>• 구조적 결함 (계층 꼬임, 책임 혼재 등)<br>• in-place refactor 가능성 직관 평가 (high / medium / low) |

## 5. Transition Gate (Phase 1 → Phase 2)

사용자에게 명시적 transition 메시지 보내고 승인 받기:

```
✅ Phase 1 완료
- Acceptance test: green ([test 이름])
- 학습 사항 N개:
  • ...
- 구조 평가: [in-place refactor 가능 / 재작성 권장 / 사용자 판단 필요]
- 권장: [refactor / rewrite / 유지] — 근거: ...
Phase 2 진입할까요?
```

사용자 OK 전엔 Phase 2 코드 변경 X.

### "재작성 권장" 판단 기준

다음 중 하나라도 해당하면 재작성 후보로 제시:
- 도메인 모델·이름이 본질적으로 잘못 잡혀 rename·extract 정도로는 안 풀림
- 계층/의존성이 너무 꼬여 acceptance test 외 추가 unit test 작성 자체가 차단됨
- in-place refactor 추정 비용이 재작성 비용을 분명히 초과

기본은 in-place refactor. 위 기준 외 일반 케이스는 refactor 권장.

## 6. Phase 2 — Stabilize

| 단계 | 내용 |
|---|---|
| 1. 경로 결정 | Transition Gate에서 권장한 경로 + 사용자 결정 (in-place refactor / 재작성 / Phase 1 유지). 기본은 in-place refactor. |
| 2. Test list 분해 | Phase 1에서 미룬 시나리오·edge case·error path 모두 나열. Problem-first ③과 동일. |
| 3. `writing-plans` skill 위임 | 위 test list 기반 구현 plan 작성. 재작성 경로면 plan 안에 "Phase 1 코드 폐기 + 새 구조 설계" 포함. |
| 4. `executing-plans` skill로 실행 | 정상 TDD 사이클 (red → green → refactor) 슬라이스별. unit test 추가는 여기서. |
| 5. Acceptance test 항상 green 유지 | regression 안전망. 깨지면 즉시 stop. |
| 6. 완료 기준 | 모든 test list 통과 + 코드 quality 정상 (이름·책임·구조 OK) + acceptance test green. |

## 7. Failure Conditions

skill이 거부하거나 중단해야 할 신호:

1. **자동 진입** — 사용자 명시 트리거 없이 Claude가 spike 모드로 진입하려 함. 금지.
2. **Acceptance test 정의 불가** — 외부 행위로 "끝났다"를 정의 못 하면 Phase 1 진입 거부 → brainstorming 더 필요.
3. **단순 CRUD/명세형 작업에 발동** — 도메인·해법 경로가 명확한 작업은 spike 가치 X. 거부 후 Problem-first 정상 흐름 권장.
4. **Phase 1 무한 확장** — quick pass가 한 세션 / 1일 초과 → "scope이 너무 컸다" 신호. Phase 1 stop, 작업 분해 후 재시도.
5. **Acceptance test red 상태로 Phase 2 진입 시도** — 차단.
6. **Phase 2에서 acceptance test 깨짐** — 즉시 stop, regression 확인 후 진행.
7. **Phase 1에서 unit test 작성** — 의도와 어긋남. Phase 2로 미룸.
8. **학습 사항 캡처 생략** — Transition Gate 통과 X. 학습 없이 단순히 "코드를 한 번 짠 것"이 되어 spike 가치 상실.

## 8. 예시 시나리오

### 예시 A — 적합한 사용 (도메인 불확실)

> 사용자: "OMS에서 multi-warehouse 재고 차감 로직 짜야 하는데 처음이라 감이 안 와. **/spike**"

- **Phase 1**
  - 승인 조건: order 1건(5 SKU) / warehouse 2곳 차감 → 가능 시 `confirmed`, 불가 시 `backorder`
  - Acceptance test: `confirmOrder(orderId)` → `status` + warehouse 재고 감소량 검증
  - Quick pass: `OrderService` 단일 파일에 모든 로직, warehouse 선택 알고리즘 hard-code, fallback 없음
  - Test green → **학습**: warehouse 선택 정책이 별도 도메인 개념 / stock concurrency 미고려 / partial fulfillment 누락 / 구조 평가 = high (refactor 가능)

- **Transition Gate**: "Phase 1 완료, in-place refactor 권장 (계층 분리만)" → 사용자 OK

- **Phase 2** (writing-plans 위임): `WarehouseSelectionPolicy` 추출 + Stock concurrency + partial fulfillment test list → executing-plans 슬라이스별 TDD → acceptance test 항상 green 유지

### 예시 B — 부적합 (skill이 거부해야 함)

> 사용자: "GET /users/:id 엔드포인트 추가. **/spike**"

- skill 응답: "단순 CRUD라 spike 모드의 가치(불확실성 학습)가 없어요. 기존 Problem-first 정상 흐름이 더 빠릅니다. 그래도 spike로 갈 이유가 있다면 알려주세요 — 없으면 정상 흐름으로 진행할게요."
- 사용자 강행 시 발동, 보통은 거절·전환.

### 예시 C — Phase 2에서 재작성 권장 (드묾)

> Phase 1 quick pass 결과: 도메인 모델 자체가 잘못 잡혔음 (예: order/payment 책임 혼재, 이름이 의미와 안 맞음, acceptance test는 green이지만 unit test 추가 자체가 차단).

- Transition Gate 메시지: "구조 평가 = low. in-place refactor 비용 > 재작성 비용. **재작성 권장.** 근거: [구체 사항 3개]. Phase 1 코드 폐기하고 새 plan으로 갈까요?"
- 사용자 OK → writing-plans 안에 "Phase 1 폐기 + 새 구조 설계" 명시.

## 9. Skill 파일 구조 (구현 시 참고)

```
~/.claude/skills/spike-and-stabilize/
└── SKILL.md            # frontmatter + Phase 1/2 절차 + Failure Conditions + 예시
```

SKILL.md frontmatter 요소:
- `name`: spike-and-stabilize
- `description`: 트리거 phrase 명시 + 적용 조건 (도메인·해법 불확실성 있는 비자명 작업)
- 본문: Phase 1 → Transition Gate → Phase 2 절차, Failure Conditions, 예시 1–2개

## 10. Open Questions / Future Work

- **세션 끊김 시 Phase 추적**: Phase 1 진행 중 세션 끊기면 어디서 재개할지. 현재는 git 상태 + 사용자 메모리로 충분하다고 판단. 필요 시 `.claude/state/spike/` 추가 검토.
- **다른 skill과의 충돌**: `superpowers:brainstorming` 트리거가 같이 발동하면? — 현재 Constraints 7번으로 "TDD 1법칙 유보 명시"만 박아둠. 실제 충돌 패턴 발견 시 SKILL.md에 우선순위 추가.
- **Acceptance test 정의 가이드**: skill 본문에 "좋은 acceptance test 패턴" 짧은 예시 포함 여부. 너무 길면 별도 reference 파일로 분리.

## 11. Implementation Plan

다음 단계: `superpowers:writing-plans` skill 호출하여 본 spec 기반 SKILL.md 작성 plan 생성.
