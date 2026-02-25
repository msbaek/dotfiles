---
name: agf
description: |
  Claude Code 세션 탐색 및 분석. agf 데이터 소스(history.jsonl)를 활용한 세션 리스트 조회 및 상세 분석.
  "세션 목록", "session list", "agf" 등의 요청 시 자동 적용.
---

# agf - Session Explorer Skill

## 개요

agf(AI Agent Session Finder)의 데이터 소스인 `~/.claude/history.jsonl`과 세션 JSONL 파일을 활용하여 Claude Code 세션을 프로그래밍 방식으로 탐색·분석하는 skill.

## 사용 방식

| 커맨드 | 설명 |
|--------|------|
| `/agf list` | 오늘 세션 리스트 |
| `/agf list YYYY-MM-DD` | 특정 날짜 세션 리스트 |
| `/agf show <session-id-prefix>` | 특정 세션 상세 + AI 요약 |

## 경로 정보

| 항목 | 경로 |
|------|------|
| 세션 인덱스 | `~/.claude/history.jsonl` |
| 세션 데이터 | `~/.claude/projects/<project-dir>/<sessionId>.jsonl` |
| 스크립트 디렉토리 | `~/.claude/skills/agf/` |
| 디렉토리 매핑 | 비영숫자 문자를 `-`로 치환 (예: `/Users/msbaek/dotfiles` → `-Users-msbaek-dotfiles`) |

---

## list 커맨드

인수가 없으면 오늘 날짜, YYYY-MM-DD 형식이면 해당 날짜의 세션 목록을 출력합니다.

### 실행 절차

1. **날짜 결정** — 인수에서 `list` 다음 값이 YYYY-MM-DD 형식이면 해당 날짜, 없으면 생략 (스크립트가 오늘 날짜를 기본값으로 사용)
2. **Bash로 스크립트 실행**
3. **결과를 사용자에게 표시** — 스크립트 출력을 그대로 표시

### 실행 명령

```bash
# 오늘 세션 목록
python3 ~/.claude/skills/agf/list.py

# 특정 날짜 세션 목록
python3 ~/.claude/skills/agf/list.py 2026-02-25
```

---

## show 커맨드

세션 ID prefix(8자 이상)를 받아 해당 세션의 상세 정보와 AI 요약을 제공합니다.

### 실행 절차

1. **세션 데이터 추출** — Bash로 스크립트 실행하여 메타데이터 + 대화 데이터 추출
2. **haiku 서브에이전트에 요약 위임** — Task 도구로 추출된 대화 데이터를 넘겨 AI 요약 생성
3. **결과 통합 출력** — 메타데이터 테이블 + AI 요약 + 사용자 메시지 목록

### Step 1: 세션 데이터 추출

```bash
python3 ~/.claude/skills/agf/show.py <SESSION_PREFIX>
```

출력 형식:
- `META_START` ~ `META_END`: 세션 메타데이터 (key: value)
- `CONV_START` ~ `CONV_END`: 대화 데이터 (U=사용자, A=어시스턴트, 최대 4000자)
- `HISTORY_START` ~ `HISTORY_END`: history.jsonl의 display 메시지 목록

### Step 2: haiku 서브에이전트로 요약 생성

추출된 CONV_START~CONV_END 사이의 대화 데이터를 haiku 서브에이전트에 전달합니다.

**Task 호출 파라미터:**

| 파라미터 | 값 |
|---------|-----|
| description | "세션 요약 생성" |
| subagent_type | "general-purpose" |
| model | "haiku" |

**프롬프트 (변수 치환 필요):**

```
아래 Claude Code 세션의 대화 내용을 분석하여 요약해주세요.
코드를 작성하지 말고 분석만 수행하세요.

## 세션 정보
- 프로젝트: {PROJECT_DIR}
- 기간: {START} ~ {END} ({DURATION})

## 대화 내용 (U=사용자, A=어시스턴트)
{CONV_DATA}

## 출력 형식
### 요약
- 이 세션에서 수행한 작업을 3-5개 항목으로 정리
- 각 항목은 "무엇을 했는지"를 1줄로 서술

### 주요 결정사항
- 세션 중 내려진 기술적 결정이 있으면 기록 (없으면 "없음")

### 미완료 작업
- 세션에서 시작했으나 완료되지 않은 작업이 있으면 기록 (없으면 "없음")
```

### Step 3: 결과 통합 출력

메인 에이전트가 아래 형식으로 메타데이터 + AI 요약 + 사용자 메시지를 조합하여 출력합니다:

```markdown
## 세션 상세: {SESSION_ID_SHORT}...

| 항목 | 값 |
|------|-----|
| 프로젝트 | {PROJECT_DIR} |
| 경로 | {CWD} |
| Git Branch | {GIT_BRANCH} |
| 시작 | {START} |
| 종료 | {END} |
| Duration | {DURATION} |
| 메시지 수 | User {USER_COUNT} / Assistant {ASST_COUNT} |
| 파일 크기 | {FILE_SIZE} |

### AI 요약
{HAIKU_SUBAGENT_RESULT}

### 사용자 메시지 목록
{HISTORY_MESSAGES}
```

---

## 에러 처리

- `history.jsonl` 파일 없음 → "~/.claude/history.jsonl 파일을 찾을 수 없습니다" 출력
- `show`에서 세션 ID prefix 매칭 0건 → "해당 prefix로 시작하는 세션을 찾을 수 없습니다" 출력
- `show`에서 세션 ID prefix 매칭 2건 이상 → 후보 목록(세션ID + 프로젝트) 표시 후 재선택 요청
- 세션 JSONL 파일 접근 불가 → "세션 파일을 읽을 수 없습니다" 출력
