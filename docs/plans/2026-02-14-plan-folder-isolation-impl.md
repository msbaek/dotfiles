# Plan Folder Isolation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** `~/.claude/CLAUDE.md`의 plan 관련 지시를 날짜 폴더 기반 2단계 INDEX.md 구조로 변경하여 동시/순차 세션 간 충돌을 방지한다.

**Architecture:** 단일 파일(`~/.claude/CLAUDE.md`) 내 3개 섹션을 수정. 기존 plan 파일과의 하위 호환성 유지.

**Tech Stack:** Markdown (CLAUDE.md 설정 파일)

**Design Doc:** `docs/plans/2026-02-14-plan-folder-isolation-design.md`

---

### Task 1: `when starting a new session` 섹션 수정

**Files:**
- Modify: `~/.claude/CLAUDE.md:5-9`

**Step 1: 현재 내용 확인**

현재 내용 (lines 5-9):
```markdown
<when-starting-a-new-session>
1. If `PROJECT_ROOT/.claude/plans/INDEX.md` exists, read it first and resume from the "resume point" of the active entry.
2. Otherwise, read plan files in the plans directory to determine progress.
3. Report overall progress and next steps to the user.
</when-starting-a-new-session>
```

**Step 2: 새 내용으로 교체**

```markdown
<when-starting-a-new-session>
1. `PROJECT_ROOT/.claude/plans/` 하위에 날짜 폴더(`YYYY-MM-DD-*`)가 있는지 탐색한다.
2. 날짜 폴더가 있으면:
   a. 각 폴더의 `INDEX.md`에서 `Status: active`인 항목을 찾는다.
   b. Active 폴더의 resume point에서 작업을 재개한다.
   c. 글로벌 `INDEX.md`가 있으면 참고하되, 폴더별 `INDEX.md`를 우선한다.
3. 날짜 폴더가 없으면 루트의 기존 plan 파일들로 fallback한다.
4. 사용자에게 현재 상태와 다음 단계를 보고한다.
</when-starting-a-new-session>
```

**Step 3: 변경 검증**

Run: `grep -A 10 'when-starting-a-new-session' ~/.claude/CLAUDE.md`
Expected: 새 내용이 정상 출력

**Step 4: 커밋**

```
feat(claude): plan 세션 시작 로직을 날짜 폴더 탐색으로 변경
```

---

### Task 2: `work_patterns` 섹션 수정

**Files:**
- Modify: `~/.claude/CLAUDE.md:158-183`

**Step 1: 현재 내용 확인**

현재 내용 (lines 158-183): plan 저장 경로와 단일 INDEX.md 구조

**Step 2: 새 내용으로 교체**

```markdown
<work_patterns>

- Always start in plan mode before working on any project
- When using APIs, SDKs, or libraries, use CONTEXT7 MCP tool to verify correct usage before proceeding

Plan Folder Structure:
- 새 작업 시작 시 `PROJECT_ROOT/.claude/plans/YYYY-MM-DD-kebab-case-topic/` 폴더를 생성한다.
  - 날짜: 작업 시작일
  - topic: Claude가 작업 내용에서 3~5단어 kebab-case 이름을 자동 생성
  - 예: `.claude/plans/2026-02-14-plan-folder-isolation/`
- 폴더 안에 plan 파일과 `INDEX.md`를 저장한다.
- Update the plan as work progresses.

폴더별 INDEX.md:
- 해당 작업의 상태를 관리하는 파일. 세션 시작 시 이 파일로 resume.
- Structure:
  ```
  # Plan: 작업 제목
  Created: YYYY-MM-DD
  Status: active|completed|paused

  ## Progress
  - [x] 완료된 작업
  - [ ] 미완료 작업

  ## Resume Point
  구체적인 재개 지점 (파일명, 단계 번호, 남은 작업)

  ## Files
  - plan-file.md — 설명
  ```
- "resume point" must be specific enough to continue immediately in a new session

글로벌 INDEX.md (`PROJECT_ROOT/.claude/plans/INDEX.md`):
- 폴더 목록과 한줄 요약만 관리 (참고용)
- Structure:
  ```
  # Plans Index
  Last updated: YYYY-MM-DD

  ## Active
  - [YYYY-MM-DD-topic/](YYYY-MM-DD-topic/) — 요약

  ## Completed
  - [YYYY-MM-DD-topic/](YYYY-MM-DD-topic/) — 요약 | completed: YYYY-MM-DD

  ## Paused
  - [YYYY-MM-DD-topic/](YYYY-MM-DD-topic/) — 요약 | reason
  ```
- Update whenever a plan folder is created, completed, or paused

하위 호환:
- 기존 루트의 랜덤 이름 plan 파일(.claude/plans/*.md)은 그대로 유지
- 날짜 폴더가 없는 프로젝트에서는 기존 방식으로 동작
</work_patterns>
```

**Step 3: 변경 검증**

Run: `grep -A 5 'Plan Folder Structure' ~/.claude/CLAUDE.md`
Expected: 새 폴더 구조 규칙이 정상 출력

**Step 4: 커밋**

```
feat(claude): work_patterns를 날짜 폴더 + 2단계 INDEX.md 구조로 변경
```

---

### Task 3: `verification-before-completion` 섹션 수정

**Files:**
- Modify: `~/.claude/CLAUDE.md:302-313`

**Step 1: 현재 내용 확인**

현재 내용 (line 306):
```markdown
- [ ] Update INDEX.md progress (resume point, task counts) if it exists
```

**Step 2: 새 내용으로 교체**

```markdown
- [ ] Update 폴더별 INDEX.md progress (resume point, status, task counts)
- [ ] Update 글로벌 INDEX.md 상태 (active/completed/paused) if it exists
```

**Step 3: 변경 검증**

Run: `grep -A 8 'verification-before-completion' ~/.claude/CLAUDE.md`
Expected: 2단계 INDEX.md 업데이트 체크리스트가 정상 출력

**Step 4: 커밋**

```
feat(claude): verification 체크리스트에 2단계 INDEX.md 반영
```

---

### Task 4: 전체 통합 검증

**Step 1: CLAUDE.md 전체 문법 확인**

Run: `cat ~/.claude/CLAUDE.md | wc -l`
Expected: 파일이 정상적으로 읽히고 줄 수가 합리적 (기존 313줄 대비 약 350줄 내외)

**Step 2: 태그 짝 확인**

Run: `grep -c '<work_patterns>' ~/.claude/CLAUDE.md && grep -c '</work_patterns>' ~/.claude/CLAUDE.md`
Expected: 각각 1

**Step 3: 기존 섹션 영향 없음 확인**

Run: `grep -c '<git_commit_messages>' ~/.claude/CLAUDE.md`
Expected: 1 (변경되지 않음)

**Step 4: 최종 커밋 (필요 시 squash)**

모든 태스크가 개별 커밋되었으므로 별도 작업 불필요. 설계 문서 상태를 completed로 업데이트.
