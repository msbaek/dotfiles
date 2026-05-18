---
name: spike-and-stabilize
description: >
  Use when user explicitly triggers spike mode for uncertain problems.
  Trigger phrases (any of these signals intent): "/spike", "스파이크로 가자",
  "퀵 앤 더티로 한 번 풀어보자", "일단 끝까지 한 번 가보자", "tracer bullet",
  "학습용으로 한 번 만들어보자". Fuzzy match: phrases meaning "let's try it once
  end-to-end quickly" or "explore before building properly" also qualify.
  Apply only when domain or solution path is uncertain — NOT for simple CRUD,
  clearly-specified features, or straightforward additions.
  NEVER auto-trigger: requires explicit user signal.
  Two-phase: Phase 1 (quick & dirty E2E + acceptance test as safety net) ->
  Transition Gate (explicit user approval) -> Phase 2 (stabilize via
  superpowers:writing-plans + superpowers:executing-plans).
---

# Spike-and-Stabilize

도메인·해법 경로가 **불확실한** 작업에서 acceptance test를 안전망 삼아 빠르게 학습하고,
그 학습을 바탕으로 좋은 구조에 도달하는 **선택형 two-phase 워크플로우**.

<HARD-GATE>
다음 경우 진입 거부:
- 사용자 명시 트리거 없이 Codex 자체 판단으로 진입 — 금지
- 단순 CRUD / 명세형 / 해법 경로 명확한 작업 — 거부 후 Problem-first 정상 흐름 권장
- acceptance test를 외부 행위로 정의 불가 — brainstorming 먼저
</HARD-GATE>

---

## Phase 1: Spike (Quick & Dirty E2E)

**목표**: acceptance test 1개 green. 내부 구조는 무시.

> **TDD 1법칙 일시 유보 고지**: Phase 1은 acceptance test 수준까지만 test-first 적용.
> unit test는 Phase 2로 미룸. 이는 학습 목적의 의도된 trade-off.

### 진입 시 한 줄 선언

시작 전 반드시 범위와 예상 시간을 선언:

```
Phase 1 시작. 범위: [happy path 1개 설명]. 예상: [세션 수 / 시간]
```

시간 제한: **한 세션 / 최대 1일**. 초과 시 즉시 stop -> 작업 분해 후 재시도.

### 절차

**1. 약식 brainstorming**
- 문제 한 줄 + 승인 조건 1-3개
- 시나리오는 **happy path 1개만** 선택
- edge case · error path는 Phase 2 backlog으로

**2. Acceptance test 정의·작성** (fail 상태로 시작)
- 외부 행위만 검증: API / CLI / public 함수 호출 -> 결과 검증
- 구현 디테일 의존 없음
- 예: `confirmOrder(orderId)` -> `{status: "confirmed", stockDelta: -5}` 검증

**3. Quick pass 구현**

| 허용 | 생략 |
|---|---|
| 단일 파일에 모든 로직 | unit test |
| 하드코딩 / 인라인 / 중복 | 추상화 / 인터페이스 |
| 거친 이름 / 긴 메서드 | 에러 처리 / 로깅 |
| 임시 변수 남발 | 일반화 |

**목표**: acceptance test green 단 하나.

**4. 통과 확인**
- acceptance test green -> 5단계 진행
- red -> Phase 2 진입 차단, Phase 1 계속

**5. 학습 사항 캡처** (bullet 3-7개)
- 발견한 도메인 개념·이름 후보
- 추가 필요 시나리오 (edge case, error path, 추가 happy path)
- 구조적 결함 (계층 꼬임, 책임 혼재, 도메인 모델 오류)
- in-place refactor 가능성 직관 평가: **high / medium / low**

> _구현 단계(절차 3)는 `spike-implementer` agent로 dispatch한다. main context는 절차 1·2(약식 brainstorming, acceptance test 정의)와 절차 5 직후 Transition Gate를 책임진다._

### Phase 1 위반 신호 (즉시 중단)

- Phase 1에서 unit test 작성 -> Phase 2로 미루기
- quick pass가 한 세션 / 1일 초과 -> scope 분해 후 재시도
- 학습 사항 캡처 생략 -> Transition Gate 통과 불가

---

## Transition Gate

Phase 1 완료 후 다음 형식으로 보고하고 **사용자 OK 대기**:

```
✅ Phase 1 완료
- Acceptance test: green ([test 이름])
- 학습 사항 N개:
  • [항목 1]
  • [항목 2]
  • ...
- 구조 평가: [high(refactor 가능) / medium(refactor 가능) / low(rewrite 권장) / 판단 필요]
- 권장: [refactor / rewrite / keep] — 근거: [1-2줄]
Phase 2 진입할까요?
```

**사용자 OK 전 Phase 2 코드 변경 절대 금지.**

사용자가 거부하거나 "나중에"라고 할 경우: Phase 1 결과와 학습 사항을 보존하고 종료. 언제든 재진입 가능.

### 재작성 권장 기준

다음 중 하나라도 해당하면 `rewrite` 제안 (기본은 `refactor`):
- 도메인 모델·이름이 본질적으로 잘못 잡혀 rename·extract로 안 풀림
- 계층/의존성이 꼬여 acceptance test 외 unit test 추가 자체가 차단됨
- in-place refactor 추정 비용이 재작성 비용을 분명히 초과

기본은 in-place refactor. 위 기준 외 일반 케이스는 refactor 권장.

`keep` 선택 기준 (드묾):
- 학습·탐색이 목적이었고 production 진입이 불필요한 경우
- Phase 1 코드를 prototype으로만 보관하고 추가 개발 계획이 없는 경우

---

## Phase 2: Stabilize

경로 (`refactor` / `rewrite` / `keep`) 결정 후 진행.

`keep` 선택 시: acceptance test를 문서화하고 skill 종료. 추가 구현 없음.

**절차:**

1. **Test list 분해** — Phase 1에서 미룬 시나리오·edge case·error path 모두 나열
   (Problem-first 3단계 시나리오 분해와 동일)

2. **`superpowers:writing-plans` skill 위임**
   - Test list 기반 구현 plan 작성
   - `rewrite` 경로: plan에 "Phase 1 코드 폐기 + 새 구조 설계" 명시

3. **`superpowers:executing-plans` skill로 실행**
   - 정상 TDD 사이클 (red -> green -> refactor) 슬라이스별
   - unit test는 여기서 추가

4. **Acceptance test 항상 green 유지**
   - regression 안전망
   - 깨지면 즉시 stop -> 원인 파악 후 진행

**완료 기준**: 모든 test list 통과 + 코드 quality 정상 + acceptance test green

---

## 예시

### A — 적합 (도메인 불확실)

> "OMS에서 multi-warehouse 재고 차감 로직 짜야 하는데 처음이라 감이 안 와. **/spike**"

```
Phase 1 시작. 범위: order 1건 / warehouse 2곳 차감 happy path. 예상: 1세션.
```

- Acceptance test: `confirmOrder(orderId)` -> `{status, stockDelta}` 검증
- Quick pass: `OrderService.java` 단일 파일, warehouse 선택 hard-code
- 학습: warehouse 선택이 별도 도메인 개념 / concurrency 미고려 / partial fulfillment 누락
- Transition: `refactor (high)` -> Phase 2: `WarehouseSelectionPolicy` 추출 + test list -> writing-plans

### B — 부적합 (거부)

> "GET /users/:id 엔드포인트 추가. **/spike**"

```
단순 CRUD라 spike 모드의 가치(불확실성 학습)가 없어요.
Problem-first 정상 흐름이 더 빠릅니다.
그래도 spike로 갈 이유가 있다면 알려주세요.
```

### C — rewrite 권장 (드묾)

> Phase 1 quick pass 결과: 도메인 모델 자체가 잘못 잡혔음 (order/payment 책임 혼재, 이름이 의미와 불일치, acceptance test는 green이지만 unit test 추가 자체가 차단됨).

```
✅ Phase 1 완료
- Acceptance test: green (confirmPayment_returns_receipt)
- 학습 사항 3개:
  • Order와 Payment 책임이 OrderService 단일 클래스에 혼재
  • 도메인 이름(processOrder)이 실제 동작(charge + fulfill)을 숨김
  • 계층 꼬임으로 PaymentGateway mock 삽입 자체가 불가능
- 구조 평가: low(rewrite 권장)
- 권장: rewrite — Phase 1 코드 폐기 후 Order / Payment 분리 설계
Phase 2 진입할까요?
```
