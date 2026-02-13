# Plan Folder Isolation Design

## Problem

`.claude/plans/` 폴더가 단일 구조(flat)여서 동시 세션 또는 순차 세션에서 plan과 INDEX.md가 충돌할 수 있음.

## Solution: 날짜 폴더 + 2단계 INDEX.md

### 폴더 구조

```
.claude/plans/
├── INDEX.md                              # 글로벌 (폴더 목록, 참고용)
├── (기존 랜덤 이름 파일들 유지)
├── 2026-02-14-plan-isolation/
│   ├── INDEX.md                          # 작업별 상태/resume point
│   └── plan.md
└── 2026-02-14-sketchybar-refactor/
    ├── INDEX.md
    └── plan.md
```

### 폴더명 규칙

- 형식: `YYYY-MM-DD-kebab-case-topic`
- Claude가 작업 내용에서 3~5단어 kebab-case 이름 자동 생성
- 같은 날짜 + 다른 topic으로 동시 세션 구분

### 글로벌 INDEX.md

폴더 목록 + 한줄 요약만 관리. 세션 시작 시 참고용.

```markdown
# Plans Index
Last updated: YYYY-MM-DD

## Active
- [YYYY-MM-DD-topic/](YYYY-MM-DD-topic/) — 요약

## Completed
- [YYYY-MM-DD-topic/](YYYY-MM-DD-topic/) — 요약 | completed: YYYY-MM-DD

## Paused
- [YYYY-MM-DD-topic/](YYYY-MM-DD-topic/) — 요약 | reason
```

### 폴더별 INDEX.md

해당 작업의 실제 상태 관리. 세션 시작 시 이 파일로 resume.

```markdown
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

### CLAUDE.md 변경 범위

1. `when starting a new session` — 날짜 폴더 탐색 우선, 기존 파일 fallback
2. `work_patterns` — 폴더 생성 규칙, 2단계 INDEX.md 구조
3. `verification-before-completion` — 폴더별 + 글로벌 INDEX.md 업데이트

### 세션 흐름

**시작**: 날짜 폴더 탐색 → active 폴더의 INDEX.md에서 resume
**새 작업**: 폴더 생성 → 폴더별 INDEX.md + plan 작성 → 글로벌 INDEX.md 등록
**완료**: 폴더별 INDEX.md status → completed, 글로벌 INDEX.md 이동

### 하위 호환

- 기존 루트의 랜덤 이름 plan 파일은 그대로 유지
- 날짜 폴더가 없으면 기존 방식으로 fallback
