# Claude Code Daily Log System - Implementation Plan

## 목표

Claude Code 세션 로그를 분석하여 daily log를 생성하고, 기존 `daily-work-logger` 스킬을 확장하여 Obsidian Daily Note에 통합.

---

## Phase 1: 핵심 Daily Log 기능

### 1.1 세션 로그 구조 (탐색 완료)

**위치**: `~/.claude/projects/[encoded-project-path]/[session-uuid].jsonl`

**레코드 타입**:
- `user`: 사용자 메시지, timestamp, cwd, gitBranch
- `assistant`: tool_use (Edit, Read, Bash 등), 수정된 파일 정보
- `summary`: 세션 요약

**추출 가능 정보**:
- 작업 시작/종료 시간 (timestamp)
- 프로젝트 경로 (cwd, 디렉토리명)
- 수정된 파일 (Edit/Write tool_use의 file_path)
- 사용된 도구 목록
- Jira 이슈 ID (ABC-123 패턴)

### 1.2 수정할 파일

**Primary**: `/Users/msbaek/.claude/skills/daily-work-logger/SKILL.md`

**변경 내용**:
1. "Step 2.5: Claude Code 세션 로그 탐색" 추가
2. "Step 4.5: 세션 로그에서 업무 내용 추출" 추가
3. "Step 5: Daily Note 업데이트"에 Claude 세션 섹션 템플릿 추가

### 1.3 추가할 섹션 (SKILL.md)

```markdown
### Step 2.5: Claude Code 세션 로그 탐색

\```bash
# 어제 수정된 세션 로그 찾기
YESTERDAY=$(date -v-1d +%Y-%m-%d)
find ~/.claude/projects -name "*.jsonl" \
  -newermt "$YESTERDAY" ! -newermt "$(date +%Y-%m-%d)"
\```

### Step 4.5: Claude Code 세션에서 추출

**추출 정보**:
| 항목 | 소스 |
|------|------|
| 프로젝트명 | 디렉토리 경로 디코딩 |
| 작업 시간 | user/assistant 레코드의 timestamp |
| 수정된 파일 | tool_use (Edit, Write)의 file_path |
| 작업 의도 | user message.content |
| Jira 이슈 | `[A-Z]{2,10}-\d+` 패턴 매칭 |
| Git 브랜치 | user 레코드의 gitBranch |
```

### 1.4 Daily Note 출력 형식

**추가 위치**: `## Notes` 섹션 하위 또는 `## Today's Activity` 상단

```markdown
## Claude Code 세션 요약

> 총 **N개 프로젝트**, **M개 세션**, **K개 파일** 수정

### 프로젝트별 작업

#### [프로젝트명] ([유형])

**브랜치**: `feature/xxx`
**Jira**: [[ABC-123]]

| 시간 | 작업 요약 |
|-----|----------|
| 10:21-11:38 | 작업 내용 요약 |

**수정된 파일**:
- `path/to/file.java` - 변경 유형
```

### 1.5 작업 유형 분류 기준

| 유형 | 키워드 | 도구 패턴 |
|-----|-------|---------|
| 기능 개발 | feature, 기능, 추가, 구현 | Write (신규 파일) |
| 버그 수정 | fix, bug, error, 오류 | Edit (기존 파일) |
| 리팩토링 | refactor, 정리, cleanup | Edit (다수 파일) |
| 문서화 | doc, 문서, README | Write (.md 파일) |
| 테스트 | test, 테스트, TDD | Edit (*Test.*, *Spec.*) |
| 탐색/분석 | 분석, 찾아, 확인 | Read, Grep, Glob |

---

## Phase 2: 주간 분석 리포트

### 2.1 새 스킬 생성

**경로**: `/Users/msbaek/.claude/skills/weekly-claude-analytics/SKILL.md`

### 2.2 리포트 구조

**출력**: `analytics/claude-weekly/YYYY-WXX.md`

```markdown
# Claude Code 주간 분석 - YYYY년 WXX주차

## 요약 통계
| 항목 | 이번 주 | 지난 주 | 변화 |
|-----|--------|--------|-----|
| 총 세션 수 | N | M | +X% |
| 총 작업 시간 | Xh Ym | ... | ... |

## 프로젝트별 시간 분포
(차트 또는 테이블)

## 작업 유형 분석
| 유형 | 세션 수 | 비율 |
|-----|--------|-----|

## Jira 이슈 진행 현황
| 이슈 | 프로젝트 | 세션 수 |
|-----|---------|--------|
```

---

## Phase 3: 향후 확장

### 3.1 회고 리포트 데이터 축적
- 월간 집계 JSON 파일 자동 생성
- 경로: `analytics/claude-monthly/YYYY-MM.json`

### 3.2 프롬프트 패턴 분석
- 의도 분류별 빈도 분석
- 효율적인 프롬프트 패턴 추출

### 3.3 지식 그래프 연결
- Obsidian frontmatter에 `cc-*` 메타데이터 추가
- Jira 이슈, 프로젝트 노트에 역링크 생성

---

## 구현 순서

1. **Phase 1-A**: daily-work-logger SKILL.md 확장
   - Claude 세션 로그 탐색 단계 추가
   - 세션 파싱 및 추출 로직 정의

2. **Phase 1-B**: Daily Note 출력 형식 구현
   - 프로젝트별 섹션 템플릿
   - 일일 통계 요약

3. **Phase 2**: 주간 분석 리포트 스킬 생성

4. **Phase 3**: 추가 기능 (별도 요청 시)

---

## 검증 방법

1. `/daily-work-logger` 실행 후 Daily Note 확인
2. Claude Code 세션 섹션이 올바르게 추가되었는지 검증
3. 프로젝트별 분류, 시간 정보, 파일 목록 정확성 확인
4. Jira 이슈 링크가 올바르게 생성되었는지 확인

---

## Uncertainty Map

**낮은 확신 영역**:
- 세션 파일 mtime vs 레코드 내 timestamp 불일치 가능성
- 작업 유형 자동 분류 정확도 (키워드 기반 한계)
- 프로젝트 경로 디코딩 시 특수 문자 처리

**확인 필요 사항**:
- 실제 세션 로그 파싱 테스트 필요
- 주간 리포트 저장 위치 최종 확정 (analytics/ vs notes/)
