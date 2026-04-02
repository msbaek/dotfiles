# QMD Auto-Index on Search

**Date:** 2026-03-30
**Status:** Approved

## Goal

`qmd`로 세션을 검색할 때 색인이 최신이 아니면 자동으로 색인을 갱신한 뒤 검색을 실행한다.

**성공 기준:** `qmd-search "쿼리"`를 실행하면, 새로운 세션 파일이 있을 경우 자동으로 `qmd update && qmd embed` 후 검색 결과를 반환한다.

## Constraints

- freshness 로직은 `qmd-search` 스크립트 한 곳에만 존재 (Single Source of Truth)
- 갱신 실패가 검색을 차단하지 않음 (best-effort)
- AI 텍스트 해석에 의존하지 않는 결정적(deterministic) 방식

## Failure Conditions

- `qmd-search`를 실행했는데 새 파일이 있음에도 색인이 갱신되지 않으면 실패
- 갱신 실패 시 검색 자체가 막히면 실패
- 스킬 파일에 freshness 체크 로직이 중복으로 남아있으면 실패

## Architecture

### 1. `qmd-search` Wrapper Script

**위치:** `bin/qmd-search` (stow로 `~/bin/qmd-search`에 배포)

**동작 흐름:**
```
1. 인자 검증 (검색어 필수)
2. --skip-update 플래그 확인
3. claude-sessions 디렉토리의 실제 .md 파일 수 카운트
4. qmd 인덱스의 파일 수 조회
5. 실제 > 인덱스이면 → qmd update && qmd embed
6. qmd query "$@" 실행
```

**Staleness 판단:**
- 실제 파일 수: `fd -e md . ~/git/claude-sessions/ | wc -l`
- 인덱스 파일 수: `qmd collection list 2>/dev/null | grep "Files:" | awk '{print $2}'`
- 실제 > 인덱스 → 새 파일 존재 → 갱신 필요

**인터페이스:**
```bash
qmd-search "TDD 리팩토링"          # freshness 체크 + 검색
qmd-search --skip-update "쿼리"    # 갱신 스킵, 바로 검색
```

### 2. Skill File Changes

| 파일 | 변경 |
|------|------|
| `.claude/skills/agf/SKILL.md` | `qmd query` → `qmd-search` 교체. freshness 체크 텍스트 블록 제거 |
| `.claude/skills/recall/SKILL.md` | "수동 갱신" 설명 → "qmd-search가 자동 처리" 로 변경 |
| `.claude/skills/recall/workflows/recall.md` | Step 2B.0 전체 제거. Step 2B.1에서 `qmd query` → `qmd-search` 교체 |

### 3. Error Handling

| 상황 | 처리 |
|------|------|
| `qmd` 바이너리 없음 | stderr 에러 + exit 1 |
| `~/git/claude-sessions/` 없음 | stderr 경고, 갱신 스킵, 기존 인덱스로 검색 |
| `qmd update` 실패 | stderr 경고, 기존 인덱스로 검색 계속 |
| `qmd embed` 실패 | stderr 경고, 기존 인덱스로 검색 계속 |
| 검색어 미입력 | usage 출력 + exit 1 |
| `--skip-update` | freshness 체크 전체 스킵 |

## Files to Create/Modify

- **Create:** `bin/qmd-search`
- **Modify:** `.claude/skills/agf/SKILL.md`
- **Modify:** `.claude/skills/recall/SKILL.md`
- **Modify:** `.claude/skills/recall/workflows/recall.md`
