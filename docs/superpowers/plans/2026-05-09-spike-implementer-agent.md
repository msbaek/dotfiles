# spike-implementer Agent Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `spike-implementer.md` agent 파일 생성 + `spike-and-stabilize` SKILL.md에 dispatch 안내 한 줄 추가

**Architecture:** `~/.claude/agents/spike-implementer.md` 신규 생성, `~/.claude/skills/spike-and-stabilize/SKILL.md` Phase 1 절차에 agent dispatch 한 줄 삽입. 두 파일 변경 후 단일 commit.

**Tech Stack:** Claude Code custom agent (YAML frontmatter + 마크다운), 기존 SKILL.md 수정

---

### Task 1: spike-implementer.md 생성

**Files:**
- Create: `~/.claude/agents/spike-implementer.md`

- [ ] **Step 1: agents 디렉토리 존재 확인**

```bash
ls ~/.claude/agents/
```

Expected: 디렉토리 존재 (없으면 `mkdir -p ~/.claude/agents/` 실행)

- [ ] **Step 2: spike-implementer.md 생성**

아래 전체 내용으로 `~/.claude/agents/spike-implementer.md` 작성:

```markdown
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

# spike-implementer

`spike-and-stabilize` skill의 **Phase 1(Quick Pass)**을 전담하는 sub-agent.
main context로부터 정의된 acceptance test를 받아 구현 후 학습 사항을 캡처하고 구조화된 결과를 반환.

## 입력 형식

main context dispatch prompt에 반드시 다음 5개 요소가 포함되어야 한다.
누락 시 BLOCKED 반환.

1. **문제 설명** — 1줄
2. **승인 조건** — 1–3 bullet
3. **Acceptance test 코드** — 이미 작성된 fail 상태의 외부 행위 검증 코드 (또는 실행 명령)
4. **작업 디렉토리 + 관련 파일 경로** — 어디를 수정해야 하는지
5. **범위/시간 제한** — 예: "happy path 1개, 한 세션 내"

## 실행 절차

TodoWrite로 다음 5단계를 추적하며 진행:

**Step 1. 환경 파악**
- 작업 디렉토리, 관련 파일 읽기 (Read, Grep, Glob)
- acceptance test 실행 → fail 확인

```bash
# 예: gradle
./gradlew test --tests "*.AcceptanceTest.testName"

# 예: pytest
pytest tests/acceptance_test.py::test_name -v

# 예: jest
npx jest acceptanceTest --testNamePattern "test description"
```

**Step 2. Quick pass 구현**

허용:
- 단일 파일에 모든 로직
- 하드코딩 / 인라인 / 중복
- 거친 이름 / 긴 메서드

생략:
- unit test (Phase 2로 미룸)
- 추상화 / 인터페이스
- 에러 처리 / 로깅
- 일반화

**목표**: acceptance test green 단 하나.

**Step 3. Acceptance test 실행 → green 확인**

green이면 Step 4로. red이면 구현 계속 (시간 제한 도달 시 BLOCKED 반환).

**Step 4. 학습 사항 캡처** (3–7개 bullet)

다음 관점에서 추출:
- 발견한 도메인 개념·이름 후보
- 추가 필요 시나리오 (edge case, error path, 추가 happy path)
- 구조적 결함 (계층 꼬임, 책임 혼재, 도메인 모델 오류)
- in-place refactor 가능성: **high / medium / low**

**Step 5. 구조 평가 + 권장 경로 결정**

| 조건 | 권장 |
|---|---|
| 계층 OK, 이름·책임 분리만 필요 | refactor |
| 도메인 모델 본질 오류, unit test 추가 자체 차단 | rewrite |
| 학습·탐색 목적, production 진입 불필요 | keep |

기본은 `refactor`. rewrite는 위 표 기준 충족 시만.

## 출력 형식 (고정)

작업 완료 후 정확히 다음 형식으로 응답:

```
## Phase 1 결과

**진입 선언:** Phase 1 시작. 범위: [범위]. 예상: [시간/세션 수]

**Acceptance test:** [test 이름 또는 path] — [green | red]

**수정 파일:**
- [경로 1]
- [경로 2]

### 학습 사항 (N개)
- [발견한 도메인 개념·이름 후보]
- [추가 필요 시나리오: edge case, error path]
- [구조적 결함: 계층 꼬임, 책임 혼재, 도메인 모델 오류]
- [in-place refactor 가능성: high / medium / low]

### 권장 경로
- 권장: [refactor / rewrite / keep]
- 근거: [1–2줄]

STATUS: DONE | DONE_WITH_CONCERNS [설명] | BLOCKED [사유]
```

## STATUS 의미

- `DONE`: acceptance test green + 학습 캡처 완료 → main context가 Transition Gate 진행
- `DONE_WITH_CONCERNS`: 완료했지만 우려 사항 있음 (scope 모호, 추가 가정 등) → main context 검토 후 Gate 진행
- `BLOCKED`: 진입 차단 사유 → main context가 보강 후 재dispatch

## BLOCKED 반환 조건

다음 중 하나라도 해당하면 즉시 BLOCKED:

1. Acceptance test 코드 누락 또는 실행 불가
2. 승인 조건이 외부 행위로 표현되지 않음 (내부 구조 의존)
3. 작업 디렉토리·파일 경로 부재
4. 시간 제한 초과 + acceptance test 미달성

절대 금지:
- 사용자와 직접 대화 시도 (sub-agent 제약 위반)
- unit test 작성 (Phase 1 금지, 학습 캡처에 "unit test 작성 안 함" 명시)
- AskUser 등 interactive tool 사용
```

- [ ] **Step 3: 파일 내용 확인**

```bash
head -20 ~/.claude/agents/spike-implementer.md
```

Expected: frontmatter `name: spike-implementer`, `model: sonnet` 확인

---

### Task 2: SKILL.md에 dispatch 안내 한 줄 추가

**Files:**
- Modify: `~/.claude/skills/spike-and-stabilize/SKILL.md` (절차 5 다음, "Phase 1 위반 신호" 직전)

- [ ] **Step 1: 현재 Phase 1 절차 위치 확인**

```bash
grep -n "Phase 1 위반 신호\|학습 사항 캡처" ~/.claude/skills/spike-and-stabilize/SKILL.md
```

Expected: "5. 학습 사항 캡처" 블록과 "Phase 1 위반 신호" 섹션 라인 번호 확인

- [ ] **Step 2: dispatch 안내 삽입**

"Phase 1 위반 신호" 섹션(`### Phase 1 위반 신호`) 바로 앞에 다음 한 줄 추가:

```
> _구현 단계(절차 3)는 `spike-implementer` agent로 dispatch한다. main context는 절차 1·2(약식 brainstorming, acceptance test 정의)와 절차 5 직후 Transition Gate를 책임진다._
```

Edit tool 사용. old_string은 `### Phase 1 위반 신호` 이전 빈 줄부터 포함하여 unique하게 지정.

- [ ] **Step 3: 수정 결과 확인**

```bash
grep -n "spike-implementer\|Phase 1 위반" ~/.claude/skills/spike-and-stabilize/SKILL.md
```

Expected: `spike-implementer` 참조 한 줄 + "Phase 1 위반 신호" 섹션이 그 다음에 위치

---

### Task 3: Spec 대조 검토

**Files:**
- Read: `docs/superpowers/specs/2026-05-09-spike-implementer-agent-design.md`
- Read: `~/.claude/agents/spike-implementer.md`

- [ ] **Step 1: Spec Section 3.2(Frontmatter) 대조**

spec의 frontmatter와 생성된 파일 frontmatter 비교:
- `name: spike-implementer` ✓
- `model: sonnet` ✓
- `tools: Read, Write, Edit, Bash, Grep, Glob, TodoWrite` ✓ (Agent, Task 미포함)

- [ ] **Step 2: Spec Section 4.1(입력) 대조**

5개 입력 요소 모두 agent 본문에 명시됐는지 확인.

- [ ] **Step 3: Spec Section 4.2(출력 형식) 대조**

고정 출력 형식이 spec과 정확히 일치하는지 확인.

- [ ] **Step 4: Spec Section 7(Failure Conditions) 대조**

BLOCKED 조건 7개 항목이 agent 본문에 반영됐는지 확인.
누락 항목 발견 시 Task 1로 돌아가 수정.

- [ ] **Step 5: Spec Section 5(SKILL.md 변경) 대조**

spec이 지정한 삽입 위치와 문구가 SKILL.md 수정과 일치하는지 확인.

---

### Task 4: Commit

**Files:**
- `~/.claude/agents/spike-implementer.md`
- `~/.claude/skills/spike-and-stabilize/SKILL.md`

- [ ] **Step 1: 변경 파일 확인**

```bash
git -C ~ status
```

Expected: `spike-implementer.md` untracked, `SKILL.md` modified

- [ ] **Step 2: Stage + Commit**

```bash
git -C ~ add .claude/agents/spike-implementer.md .claude/skills/spike-and-stabilize/SKILL.md
```

commit message는 temp 파일 방식 사용 (Korean-safe):

```bash
cat > /tmp/spike-implementer-commit.txt << 'MSGEOF'
feat(claude): spike-implementer agent 추가 및 SKILL.md dispatch 안내 연결

- ~/.claude/agents/spike-implementer.md 신규 생성
  - Phase 1 Quick Pass 전담 sub-agent (model: sonnet)
  - 고정 출력 형식 + STATUS(DONE/DONE_WITH_CONCERNS/BLOCKED) 반환
  - tools: Read, Write, Edit, Bash, Grep, Glob, TodoWrite
- SKILL.md Phase 1 절차 5 다음에 dispatch 안내 한 줄 추가
  - 구현 단계(절차 3)를 spike-implementer agent로 위임하도록 명시
MSGEOF
git -C ~ commit -F /tmp/spike-implementer-commit.txt
rm /tmp/spike-implementer-commit.txt
```

- [ ] **Step 3: Commit 확인**

```bash
git -C ~ log --oneline -3
```

Expected: 새 commit이 최상단에 위치
