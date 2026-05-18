# agf

> Claude Code 세션 탐색 및 분석 스킬

## 만든 배경

Daily Work Logger 스킬에서 세션 정보를 프로그래매틱하게 수집해야 했습니다. agf는 원래 interactive TUI 도구이므로 자동화가 어려웠고, 이를 Python 스크립트 기반 스킿으로 재구현하여 `~/.claude/history.jsonl` 데이터를 직접 조회·분석할 수 있도록 만들었습니다.

## 사용법

### 호출 방법

| 커맨드 | 설명 |
|--------|------|
| `/agf` | 사용법 표시 |
| `/agf list` | 오늘 세션 리스트 |
| `/agf list YYYY-MM-DD` | 특정 날짜 세션 리스트 |
| `/agf show <session-id-prefix>` | 세션 상세 + AI 요약 |
| `/agf search <query>` | display 필드에서 세션 검색 |
| `/agf search --deep <query>` | 세션 JSONL 내부까지 검색 |

### 예시

```
/agf list 2026-02-25
→ 2월 25일에 시작된 모든 세션 목록 출력

/agf show a3f8c2d1
→ 세션 ID prefix로 상세 정보 + haiku 요약 생성

/agf search --deep "obsidian workflow"
→ 모든 세션 대화 내용에서 "obsidian workflow" 검색
```

## 주요 기능

- **세션 리스트**: 날짜별로 시작된 세션 목록 조회
- **세션 검색**: display 필드 또는 대화 내용 전체에서 키워드 검색
- **세션 상세 분석**: 메타데이터 + AI 요약 + 사용자 메시지 목록 출력
- **자동 트리거**: "세션 목록", "session list", "agf" 등의 요청 시 자동 적용

## 의존성

| 도구/서비스 | 용도 |
|------------|------|
| Python 3 | 스크립트 실행 환경 |
| `~/.claude/history.jsonl` | 세션 인덱스 데이터 소스 |
| `~/.claude/projects/<project-dir>/<sessionId>.jsonl` | 세션 대화 데이터 |
| haiku 서브에이전트 | `/agf show` 커맨드에서 AI 요약 생성 |

## 참고

- 스크립트 디렉토리: `~/.claude/skills/agf/`
- 세션 ID는 8자 이상의 prefix로 매칭 (부분 일치 가능)
- `--deep` 옵션은 대화 내용 전체를 검색하므로 시간이 더 걸림
- 프로젝트 디렉토리 매핑: 비영숫자 문자를 `-`로 치환 (예: `/Users/msbaek/dotfiles` → `-Users-msbaek-dotfiles`)
