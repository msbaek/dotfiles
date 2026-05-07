---
name: session-handoff
description: 세션 종료 시 plan/INDEX/메모리/저널을 업데이트하고 다음 세션 재개 프롬프트 제공
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash(printf:*)
  - Bash(cat:*)
  - Bash(ls:*)
when_to_use: >
  Use when the user explicitly asks to wrap up, hand off, or save session state.
  Examples: '/session-handoff', '세션 정리해줘', '마무리해줘', '다음 세션 이어갈 수 있게 정리해줘',
  '작업 내역 반영해줘', 'save progress', 'wrap up'
---

# Session Handoff

## 실행 모델 (필수)

**~/.claude/templates/delegation.md 변형 A 적용** — 단, `subagent_type`은 `general-purpose` 대신 **`session-handoff-runner`** 사용 (전용 sub-agent).
(model="sonnet", run_in_background=false, args=skill 호출 인자, 옵션=없음)

main context에서 직접 실행 금지.

세션에서 수행한 작업 내역을 plan, INDEX, 메모리, 저널에 반영하고, 다음 세션에서 즉시 재개할 수 있는 프롬프트를 제공한다.

## Goal

세션 종료 시 모든 진행 상태를 영속화하여, 다음 세션에서 컨텍스트 손실 없이 작업을 이어갈 수 있도록 한다.

## Steps

### 1. 세션 컨텍스트 수집

대화 내역을 분석하여 다음을 파악한다:
- 이번 세션에서 완료한 작업 목록
- 수정/생성한 파일들
- 사용자의 피드백이나 교정 사항
- 다음에 해야 할 작업

**Success criteria**: 완료 항목, 변경 파일, 피드백, 다음 작업이 명확히 정리됨.

### 2. Plan 문서 체크박스 업데이트

- `docs/superpowers/plans/` 또는 프로젝트의 plan 문서에서 완료된 step의 `- [ ]`를 `- [x]`로 변경
- 관련 plan 문서가 없으면 스킵

**Success criteria**: 완료된 모든 step이 `[x]`로 표시됨. Plan이 없으면 스킵했음을 명시.

### 3. 세션 INDEX.md 업데이트

- `.claude/plans/` 하위의 활성 폴더에서 `INDEX.md`를 찾아 업데이트:
  - `Resume Point`: 다음 세션에서 즉시 작업을 재개할 수 있을 만큼 구체적으로 기술
  - `Progress`: 완료 항목 `[x]` 체크, 다음 작업 항목에 `← 다음` 표시
- Global INDEX.md (`.claude/plans/INDEX.md`)도 상태 업데이트
- INDEX가 없으면 스킵

**Success criteria**: Resume Point가 다음 세션에서 바로 시작할 수 있을 만큼 구체적. Progress가 최신 상태.

### 4. 프로젝트 메모리 업데이트

- 기존 프로젝트 메모리 파일을 읽고 현재 상태로 업데이트 (날짜, 완료 항목, 다음 작업)
- MEMORY.md 인덱스도 함께 업데이트
- 프로젝트 메모리가 없으면 세션 작업이 충분히 중요한 경우에만 새로 생성

**Success criteria**: 프로젝트 메모리가 현재 상태를 정확히 반영.

### 5. 피드백 메모리 저장 (조건부)

- 세션 중 사용자가 교정하거나 피드백을 준 내용이 있으면 feedback 타입 메모리로 저장
- 규칙 + **Why** + **How to apply** 구조로 작성
- 피드백이 없었으면 스킵

**Success criteria**: 사용자 교정 사항이 향후 세션에서 반복되지 않도록 기록됨. 없으면 스킵.

### 6. 저널 기록

- `~/.claude/journals/YYYY-MM.journal.md`에 세션 엔트리 append
- 형식: `## YYYY-MM-DD HH:MM | [project] | [context]` + 2-10줄 요약
- bash `printf >>` 로 append (동시성 안전)

**Rules**:
- 반드시 시스템 시계 기준 타임스탬프 사용
- 기존 엔트리 수정 금지, append only

**Success criteria**: 저널에 세션 기록이 추가됨.

### 7. 다음 세션 재개 프롬프트 안내

사용자에게 다음 세션에서 복사해서 사용할 수 있는 구체적인 프롬프트를 제시한다:
- 프로젝트 이름
- 어떤 작업을 이어서 할지
- 참고할 문서나 컨텍스트

```
[프로젝트]에서 [다음 작업]을 시작하자.
[참고 문서/컨텍스트]를 참고해서 [구체적 방법]으로 진행해줘.
```

**Success criteria**: 사용자가 다음 세션에서 이 프롬프트만 입력하면 바로 작업을 이어갈 수 있음.
