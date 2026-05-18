# daily-work-logger

> 매일 아침 어제 작업 내역을 자동으로 정리하여 Obsidian Daily Note에 반영하는 스킬

## 만든 배경

Obsidian 기반 개인 지식 관리 자동화의 일환으로 제작되었습니다. 매일 아침 업무 시작 전 어제 작성한 문서, Claude 세션, 미팅 노트, Things 작업 내역을 수동으로 정리하던 작업을 자동화하기 위해 개발했습니다. 서브 에이전트 기반 병렬 처리 아키텍처로 메인 세션의 컨텍스트를 절약하면서 빠르게 분석합니다.

## 사용법

### 호출 방법
```bash
/daily-work-logger           # 어제 작업 내역 정리
/daily-work-logger 2026-01-15  # 특정 날짜 작업 내역 정리
```

또는 자연어로 요청:
- "어제 작업 정리해줘"
- "daily log"
- "업무 내역 정리"

### 예시

**시나리오 1: 매일 아침 루틴**
```
사용자: /daily-work-logger
Claude: 2026-02-28 작업 내역이 Daily Note에 반영되었습니다.
```

**시나리오 2: 특정 날짜 회고**
```
사용자: /daily-work-logger 2026-02-25
Claude: 2026-02-25 작업 내역이 Daily Note에 반영되었습니다.
```

## 주요 기능

- **Vault 문서 분석**: 해당 날짜에 생성/수정된 Obsidian 문서에서 업무 관련 내용 추출 (기술 학습, 문서 작성, 프로젝트 작업)
- **Claude 세션 분석**: `~/.claude/history.jsonl` 파싱하여 프로젝트별 작업 내역 및 학습 내용(도구/개념/해결방법) 추출
- **미팅 노트 분석**: 미팅 주제, 논의 사항, 결정 사항, Action Items 요약
- **Things 작업 분석**: 완료된 작업 및 새로 추가된 작업 목록 수집
- **서브 에이전트 병렬 실행**: 4개 분석 작업을 동시 실행하여 속도 향상 및 메인 컨텍스트 절약

## 의존성

| 도구/서비스 | 용도 | 비고 |
|------------|------|------|
| Obsidian Vault | 문서 저장소 (`$VAULT_ROOT`) | 필수 |
| `~/.claude/history.jsonl` | Claude 세션 인덱스 | 필수 (없으면 해당 섹션 건너뜀) |
| Things MCP | Things 3 작업 관리 데이터 접근 | 선택 (없으면 해당 섹션 건너뜀) |
| Python 3 | history.jsonl 파싱 | 필수 (macOS 기본 제공) |

## 아키텍처

서브 에이전트 기반 병렬 처리로 메인 에이전트는 orchestration만 담당합니다.

```
Main Agent
  ├─ Phase 1: 날짜 결정
  ├─ Phase 2: 서브 에이전트 병렬 실행 (haiku 모델)
  │   ├─ SubAgent 1: Vault Files Analyzer
  │   ├─ SubAgent 2: Claude Sessions & Learning Analyzer
  │   ├─ SubAgent 3: Meeting Notes Analyzer
  │   └─ SubAgent 4: Things Analyzer
  └─ Phase 3: 결과 통합 및 Daily Note 반영
```

## 참고

- **관련 스킬**: `weekly-newsletter`, `learning-tracker`, `weekly-claude-analytics`
- **출력 경로**: `$VAULT_ROOT/notes/dailies/YYYY-MM-DD.md`
- **Things MCP 설치**: `claude mcp add-json -s user things '{"command":"uvx","args":["things-mcp"]}'`
