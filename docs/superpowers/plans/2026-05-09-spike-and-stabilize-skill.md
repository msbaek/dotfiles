# Spike-and-Stabilize Skill — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `~/.claude/skills/spike-and-stabilize/SKILL.md`를 작성하여 사용자가 `/spike` 트리거로 two-phase spike workflow를 사용할 수 있게 한다.

**Architecture:** 단일 SKILL.md 파일. Phase 1(quick & dirty + acceptance test) → Transition Gate(사용자 승인) → Phase 2(superpowers:writing-plans / executing-plans 위임). Plugin이 아닌 user skill space(`~/.claude/skills/`)에 위치.

**Tech Stack:** Markdown (Claude Code skills system), `~/.claude/skills/` user space

---

### Task 1: SKILL.md 파일 생성

**Files:**
- Create: `~/.claude/skills/spike-and-stabilize/SKILL.md`

- [ ] **Step 1: 디렉토리 생성**

```bash
mkdir -p ~/.claude/skills/spike-and-stabilize
```

Expected: 디렉토리 생성 완료 (already exists도 OK, 오류 없음)

- [ ] **Step 2: SKILL.md 작성**

Write 도구로 `~/.claude/skills/spike-and-stabilize/SKILL.md`에 아래 내용을 그대로 작성:

```markdown
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
  Two-phase: Phase 1 (quick & dirty E2E + acceptance test as safety net) →
  Transition Gate (explicit user approval) → Phase 2 (stabilize via
  superpowers:writing-plans + superpowers:executing-plans).
---

# Spike-and-Stabilize

도메인·해법 경로가 **불확실한** 작업에서 acceptance test를 안전망 삼아 빠르게 학습하고,
그 학습을 바탕으로 좋은 구조에 도달하는 **선택형 two-phase 워크플로우**.

<HARD-GATE>
다음 경우 진입 거부:
- 사용자 명시 트리거 없이 Claude 자체 판단으로 진입 — 금지
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

시간 제한: **한 세션 / 최대 1일**. 초과 시 즉시 stop → 작업 분해 후 재시도.

### 절차

**1. 약식 brainstorming**
- 문제 한 줄 + 승인 조건 1–3개
- 시나리오는 **happy path 1개만** 선택
- edge case · error path는 Phase 2 backlog으로

**2. Acceptance test 정의·작성** (fail 상태로 시작)
- 외부 행위만 검증: API / CLI / public 함수 호출 → 결과 검증
- 구현 디테일 의존 없음
- 예: `confirmOrder(orderId)` → `{status: "confirmed", stockDelta: -5}` 검증

**3. Quick pass 구현**

| 허용 | 생략 |
|---|---|
| 단일 파일에 모든 로직 | unit test |
| 하드코딩 / 인라인 / 중복 | 추상화 / 인터페이스 |
| 거친 이름 / 긴 메서드 | 에러 처리 / 로깅 |
| 임시 변수 남발 | 일반화 |

**목표**: acceptance test green 단 하나.

**4. 통과 확인**
- acceptance test green → 5단계 진행
- red → Phase 2 진입 차단, Phase 1 계속

**5. 학습 사항 캡처** (bullet 3–7개)
- 발견한 도메인 개념·이름 후보
- 추가 필요 시나리오 (edge case, error path, 추가 happy path)
- 구조적 결함 (계층 꼬임, 책임 혼재, 도메인 모델 오류)
- in-place refactor 가능성 직관 평가: **high / medium / low**

### Phase 1 위반 신호 (즉시 중단)

- Phase 1에서 unit test 작성 → Phase 2로 미루기
- quick pass가 한 세션 / 1일 초과 → scope 분해 후 재시도
- 학습 사항 캡처 생략 → Transition Gate 통과 불가

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
- 구조 평가: [in-place refactor 가능(high/medium) / 재작성 권장(low) / 사용자 판단 필요]
- 권장: [refactor / rewrite / 유지] — 근거: [1–2줄]
Phase 2 진입할까요?
```

**사용자 OK 전 Phase 2 코드 변경 절대 금지.**

### 재작성 권장 기준

다음 중 하나라도 해당하면 `rewrite` 제안 (기본은 `refactor`):
- 도메인 모델·이름이 본질적으로 잘못 잡혀 rename·extract로 안 풀림
- 계층/의존성이 꼬여 acceptance test 외 unit test 추가 자체가 차단됨
- in-place refactor 추정 비용이 재작성 비용을 분명히 초과

---

## Phase 2: Stabilize

경로 (`refactor` / `rewrite` / `keep`) 결정 후 진행.

**절차:**

1. **Test list 분해** — Phase 1에서 미룬 시나리오·edge case·error path 모두 나열
   (Problem-first ③ 시나리오 분해와 동일)

2. **`superpowers:writing-plans` skill 위임**
   - Test list 기반 구현 plan 작성
   - `rewrite` 경로: plan에 "Phase 1 코드 폐기 + 새 구조 설계" 명시

3. **`superpowers:executing-plans` skill로 실행**
   - 정상 TDD 사이클 (red → green → refactor) 슬라이스별
   - unit test는 여기서 추가

4. **Acceptance test 항상 green 유지**
   - regression 안전망
   - 깨지면 즉시 stop → 원인 파악 후 진행

**완료 기준**: 모든 test list 통과 + 코드 quality 정상 + acceptance test green

---

## 예시

### A — 적합 (도메인 불확실)

> "OMS에서 multi-warehouse 재고 차감 로직 짜야 하는데 처음이라 감이 안 와. **/spike**"

```
Phase 1 시작. 범위: order 1건 / warehouse 2곳 차감 happy path. 예상: 1세션.
```

- Acceptance test: `confirmOrder(orderId)` → `{status, stockDelta}` 검증
- Quick pass: `OrderService.java` 단일 파일, warehouse 선택 hard-code
- 학습: warehouse 선택이 별도 도메인 개념 / concurrency 미고려 / partial fulfillment 누락
- Transition: `refactor (high)` → Phase 2: `WarehouseSelectionPolicy` 추출 + test list → writing-plans

### B — 부적합 (거부)

> "GET /users/:id 엔드포인트 추가. **/spike**"

```
단순 CRUD라 spike 모드의 가치(불확실성 학습)가 없어요.
Problem-first 정상 흐름이 더 빠릅니다.
그래도 spike로 갈 이유가 있다면 알려주세요.
```
```

- [ ] **Step 3: 파일 존재 확인**

```bash
ls -la ~/.claude/skills/spike-and-stabilize/SKILL.md
wc -l ~/.claude/skills/spike-and-stabilize/SKILL.md
```

Expected: 파일 존재, 130줄 이상

---

### Task 2: Spec 대조 검토

**Files:**
- Read: `docs/superpowers/specs/2026-05-09-spike-and-stabilize-design.md`
- Read: `~/.claude/skills/spike-and-stabilize/SKILL.md`

- [ ] **Step 1: Trigger phrases 확인**

SKILL.md frontmatter `description`에 다음 6개 모두 포함됐는지 확인:
- `/spike`
- `스파이크로 가자`
- `퀵 앤 더티로 한 번 풀어보자`
- `일단 끝까지 한 번 가보자`
- `tracer bullet`
- `학습용으로 한 번 만들어보자`

누락 시 frontmatter description에 추가.

- [ ] **Step 2: Failure Conditions 8개 반영 확인**

SKILL.md에 다음이 모두 반영됐는지 대조:

| # | Condition | 반영 위치 |
|---|---|---|
| 1 | 자동 진입 금지 | HARD-GATE + description `NEVER auto-trigger` |
| 2 | acceptance test 정의 불가 → 거부 | HARD-GATE 3번째 항목 |
| 3 | 단순 CRUD 거부 | HARD-GATE 2번째 항목 + 예시 B |
| 4 | Phase 1 무한 확장 경고 | 진입 시 한 줄 선언 + 시간 제한 |
| 5 | acceptance test red로 Phase 2 진입 차단 | 절차 4번 |
| 6 | Phase 2에서 acceptance test 깨짐 → stop | Phase 2 절차 4번 |
| 7 | Phase 1 unit test 작성 금지 | 위반 신호 첫 번째 항목 |
| 8 | 학습 사항 캡처 생략 → Gate 불통과 | 위반 신호 세 번째 항목 |

누락 항목 발견 시 해당 섹션에 추가.

- [ ] **Step 3: Transition Gate 형식 확인**

SKILL.md Transition Gate 섹션의 체크리스트 형식이 spec Section 5 템플릿과 일치하는지:
- `✅ Phase 1 완료` 헤더
- Acceptance test green 항목
- 학습 사항 N개
- 구조 평가 항목
- 권장 + 근거
- `Phase 2 진입할까요?` 마무리

불일치 시 SKILL.md에 맞게 수정.

---

### Task 3: CLAUDE.md에 spike 모드 참조 추가

**Files:**
- Modify: `~/.claude/CLAUDE.md` (Problem-first workflow 섹션)

- [ ] **Step 1: 현재 내용 확인**

`~/.claude/CLAUDE.md`에서 "Walking Skeleton" 또는 "④" 주변 텍스트 확인:

```bash
grep -n "Walking Skeleton\|④\|spike" ~/.claude/CLAUDE.md
```

- [ ] **Step 2: spike 참조 1줄 추가**

Step 1 결과에서 "Walking Skeleton" 설명 다음 줄 또는 "전체 개선" 항목 뒤에 다음 한 줄 추가:

```
_불확실성이 높은 작업은 `spike-and-stabilize` skill로 Quick Pass 후 이 흐름으로 회귀._
```

위치: "4. **Walking Skeleton**" 라인 바로 아래 `_모든 계층 연결 + 각 계층 최소 구현. 완벽주의 금지._` 뒤.

추가 후 내용:
```markdown
4. **Walking Skeleton** — 가장 단순한 시나리오를 E2E로 먼저 동작.
   _모든 계층 연결 + 각 계층 최소 구현. 완벽주의 금지._
   _도메인·해법 경로가 불확실하면 `spike-and-stabilize` skill로 Quick Pass 후 이 흐름으로 회귀._
```

---

### Task 4: Commit

**Files:**
- `~/.claude/skills/spike-and-stabilize/SKILL.md`
- `~/.claude/CLAUDE.md`

- [ ] **Step 1: 변경 파일 확인**

```bash
git -C ~ status --short ~/.claude/skills/spike-and-stabilize/ ~/.claude/CLAUDE.md
```

Expected: 새 파일 `~/.claude/skills/spike-and-stabilize/SKILL.md` + 수정 `~/.claude/CLAUDE.md`

참고: `~/.claude/` 디렉토리가 별도 git repo일 수 있음. 그 경우:
```bash
# ~/.claude/ 가 별도 repo인지 확인
git -C ~/.claude rev-parse --git-dir 2>/dev/null && echo "별도 repo" || echo "dotfiles repo"
```

별도 repo면 해당 repo에서 commit. dotfiles repo면 dotfiles에서 commit.

- [ ] **Step 2: SKILL.md commit**

Write 도구로 commit message 임시 파일 작성 후 commit (heredoc 한글 깨짐 방지):

commit message 내용:
```
feat(skills): spike-and-stabilize custom skill 추가

도메인·해법 경로가 불확실한 작업에서 acceptance test를 안전망으로
quick & dirty E2E를 한 번 통과시키고(Phase 1), in-place refactor
또는 재작성으로 좋은 구조에 도달(Phase 2)하는 선택형 spike 모드.

Trigger: /spike, "스파이크로 가자", "tracer bullet" 외 유사 표현.
Phase 2는 writing-plans / executing-plans 기존 워크플로우로 회귀.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

Write 도구로 `/tmp/spike-skill-commit.txt`에 저장 후:
```bash
# SKILL.md가 어느 repo에 속하는지에 따라 경로 조정
git -C ~/.claude add skills/spike-and-stabilize/SKILL.md 2>/dev/null || \
  git add ~/.claude/skills/spike-and-stabilize/SKILL.md
git commit -F /tmp/spike-skill-commit.txt
rm /tmp/spike-skill-commit.txt
```

- [ ] **Step 3: CLAUDE.md commit**

Write 도구로 `/tmp/claudemd-commit.txt` 작성:
```
docs(claude): spike-and-stabilize skill 참조 추가

Problem-first workflow Walking Skeleton 단계에 불확실성 높은
작업에서 spike-and-stabilize skill로 Quick Pass 후 회귀하는
경로 안내 한 줄 추가.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

```bash
git -C ~/.claude add CLAUDE.md 2>/dev/null || git add ~/.claude/CLAUDE.md
git commit -F /tmp/claudemd-commit.txt
rm /tmp/claudemd-commit.txt
```

- [ ] **Step 4: Commit 확인**

```bash
git -C ~/.claude log --oneline -3 2>/dev/null || git log --oneline -3
```

Expected: 최신 2개 commit이 위의 메시지로 나타남

---

### Task 5: 수동 Trigger 검증 (선택)

새 Claude Code 세션을 열어 다음 트리거로 skill 발동 확인.

- [ ] **Step 1: skill 인식 확인**

새 세션에서:
```
/spike
```

Expected: spike-and-stabilize skill 로드 + "Phase 1 진입 체크" 안내

- [ ] **Step 2: 거부 동작 확인**

새 세션에서:
```
GET /users/:id 추가해줘 /spike
```

Expected: "단순 CRUD, spike 가치 없음" 거부 메시지

---

## Self-Review Notes

**Spec coverage 확인:**
- ✅ Goal (Section 1) → Task 1 SKILL.md의 목표 + HARD-GATE
- ✅ Trigger (Section 2) → frontmatter description의 trigger phrases
- ✅ Constraints (Section 3) → HARD-GATE + Phase 1 TDD 유보 고지 + 시간 제한
- ✅ Phase 1 (Section 4) → SKILL.md Phase 1 절차 5단계
- ✅ Transition Gate (Section 5) → SKILL.md Transition Gate 섹션
- ✅ Phase 2 (Section 6) → SKILL.md Phase 2 절차 4단계
- ✅ Failure Conditions (Section 7) → Task 2 Step 2 대조표 + SKILL.md 위반 신호
- ✅ 예시 A/B (Section 8) → SKILL.md 예시 섹션
- ✅ Skill 파일 구조 (Section 9) → Task 1 파일 경로
- ⏭️ Open Questions (Section 10) → 의도적 미결, 구현 불필요

**Placeholder scan:** 없음. 모든 step에 실행 가능한 내용 포함.

**Type consistency:** 마크다운 파일이므로 해당 없음.
