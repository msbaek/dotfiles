---
name: claude-code-release-tracker
description: |
  @claudecodelog X 계정의 릴리스 노트를 수집하여 Obsidian 문서로 정리.
  매일 morning-auto.sh에서 자동 호출되거나, 수동으로 /claude-code-release-tracker 실행.
  --backfill 인자 시 3개월 소급 처리.
---

# Claude Code Release Tracker

## 실행 모델 (필수)

**~/.claude/templates/delegation.md 변형 A 적용** — 단, `subagent_type`은 `general-purpose` 대신 **`claude-code-release-fetcher`** 사용 (전용 sub-agent).
(model="sonnet", run_in_background=false, args=skill 호출 인자, 옵션=--backfill)

main context에서 직접 실행 금지.

## 개요

X(@claudecodelog)에서 Claude Code 릴리스 노트를 수집하여 한글로 번역/구조화하고
Obsidian vault에 월별 파일로 저장한다.

## 인수

| 인수 | 설명 | 기본값 |
|------|------|--------|
| --backfill | 3개월치 소급 수집 | false (최근 미수집분만) |

## 필수 도구

이 skill은 Playwright MCP 도구를 사용한다. 도구명은 반드시 `mcp__playwright__` 접두사를 붙여야 한다:
- `mcp__playwright__browser_navigate` — URL로 이동
- `mcp__playwright__browser_snapshot` — 현재 페이지의 접근성 스냅샷 (텍스트 추출)
- `mcp__playwright__browser_click` — 요소 클릭
- `mcp__playwright__browser_close` — 브라우저 닫기

**주의: `browser_navigate`, `browser_snapshot` 등 접두사 없는 이름은 사용할 수 없다. 반드시 `mcp__playwright__` 접두사를 사용해야 한다.**

스크롤이 필요하면 `mcp__playwright__browser_click`으로 페이지 하단 요소를 클릭하거나, `mcp__playwright__browser_navigate`로 JavaScript를 실행한다:
- 스크롤 다운: `mcp__playwright__browser_click`에서 "Show more" 또는 타임라인 하단의 트윗을 클릭

## 실행 절차

### Phase 1: 상태 파일 읽기

1. Read 도구로 `~/DocumentsLocal/msbaek_vault/scripts/claude-release-tracker-state.json` 읽기
2. `lastChecked` 날짜 확인 (null이면 backfill 모드와 동일하게 처리)
3. `releases` 배열에서 이미 수집된 트윗 URL 목록 추출 → `collectedUrls` 집합으로 보관

### Phase 2: X 타임라인 수집

1. `mcp__playwright__browser_navigate` 사용
   - URL: `https://x.com/claudecodelog`
   - storage state는 Playwright MCP 설정에서 자동 적용됨
2. 페이지 로드 후 `mcp__playwright__browser_snapshot` 으로 현재 보이는 트윗 목록 확인
3. 로그인 필요 화면이 감지되면:
   - "X 로그인 세션 만료. Chrome에서 x.com에 로그인 후 재실행 필요" 출력
   - 즉시 종료
4. 각 트윗에서 추출할 정보:
   - 트윗 텍스트 (릴리스 내용)
   - 트윗 날짜
   - 트윗 URL (permalink) — 트윗 내 링크에서 `/status/` 포함된 URL
   - 버전 번호 (텍스트에서 패턴 매칭: vX.Y.Z 또는 X.Y.Z)
5. `collectedUrls`에 이미 있는 트윗 URL은 스킵
6. lastChecked 이후 트윗만 수집 (backfill 또는 lastChecked가 null이면 3개월 전까지)
7. 더 오래된 트윗이 필요하면 `mcp__playwright__browser_click`으로 타임라인 하단 트윗 클릭 후 `mcp__playwright__browser_snapshot` 반복
   - 최대 스크롤 횟수: 일반 모드 5회, backfill 모드 30회
   - 새로운 트윗이 더 이상 나타나지 않으면 중단

### Phase 3: 버전별 그룹핑

1. 수집된 트윗을 버전 번호로 그룹핑
   - 버전 번호가 있는 트윗: 해당 버전 그룹에 포함
   - 버전 번호가 없는 트윗: 날짜를 기준으로 가장 가까운 버전에 포함
   - 어떤 버전에도 속하지 않으면 "misc-YYYY-MM-DD" 로 분류
2. 각 버전에 대해 트윗 내용을 카테고리별로 분류:
   - 새로운 기능 (New Features)
   - 개선사항 (Improvements)
   - 버그 수정 (Bug Fixes)
   - 기타 (Other)

### Phase 4: Obsidian 문서 생성/업데이트

1. `groupBy` 설정 확인 (기본: "monthly")
2. 대상 파일 경로 결정: `~/DocumentsLocal/msbaek_vault/001-INBOX/claude-code-releases-YYYY-MM.md`
3. 기존 파일이 있으면 Read 도구로 읽기
4. 새 버전 섹션을 기존 내용에 추가 (날짜 역순 — 최신이 위, frontmatter 바로 다음)
5. 기존 파일이 없으면 프론트매터 포함하여 새로 생성

**문서 템플릿:**

```
---
tags:
  - claude-code
  - release-note
period: YYYY-MM
source: https://x.com/claudecodelog
---

# Claude Code 릴리스 노트 — YYYY년 M월

## vX.Y.Z (YYYY-MM-DD)

### 새로운 기능
- **기능명**: 한글 설명

### 개선사항
- **항목**: 한글 설명

### 버그 수정
- **항목**: 한글 설명

### 원문
- [트윗](https://x.com/claudecodelog/status/xxx)

---
```

- 카테고리에 해당 항목이 없으면 해당 섹션을 생략한다
- Write 도구로 파일 저장

### Phase 5: 상태 파일 업데이트

1. 새로 수집한 릴리스 정보를 `releases` 배열에 추가:
   ```json
   {
     "version": "X.Y.Z",
     "date": "YYYY-MM-DD",
     "tweets": ["https://x.com/claudecodelog/status/xxx"],
     "processed": true
   }
   ```
2. `lastChecked`를 오늘 날짜(YYYY-MM-DD)로 업데이트
3. Write 도구로 상태 파일 저장

### Phase 6: 결과 보고

수집 결과를 요약하여 출력:
- 새로 수집된 릴리스 수
- 생성/업데이트된 파일 목록
- 새 트윗이 없었으면 "새로운 릴리스 노트 없음"

## 에러 처리

- Playwright 페이지 로드 실패 → "X 접속 실패" 로그 출력 후 종료
- 로그인 필요 화면 감지 → "X 로그인 세션 만료. Chrome에서 x.com 로그인 후 재실행 필요" 출력 후 종료
- 트윗 파싱 실패 → 원문 텍스트 그대로 "기타" 카테고리에 저장
- 새 트윗 없음 → "새로운 릴리스 노트 없음" 출력 후 정상 종료

## 중요 규칙

- 이미 수집된 트윗(상태 파일의 releases[].tweets에 URL 존재)은 절대 재처리하지 않는다
- 월별 파일에 이미 존재하는 버전 섹션은 덮어쓰지 않는다
- 한글 번역 시 기술 용어(API, CLI, MCP, SDK 등)는 영문 그대로 유지한다
- 트윗 원문 링크는 반드시 각 버전 섹션의 "원문" 하위에 포함한다
