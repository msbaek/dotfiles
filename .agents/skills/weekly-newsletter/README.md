# weekly-newsletter

> 매주 토요일 실행하여 이번 주(토~금) 기술/리더십 학습 내용을 외부 공유용 뉴스레터로 정리하는 스킬

## 만든 배경

2026-01-15, vault-intelligence 프로젝트의 일환으로 daily-work-logger와 함께 기획되었습니다. 매일 쌓이는 Daily Notes, coffee-time 노트, 기술 문서들을 매주 토요일 오전 자동으로 수집하여 외부에 공유할 만한 인사이트를 추출합니다. 서브 에이전트 기반 병렬 처리로 메인 컨텍스트를 절약하면서 빠르게 뉴스레터를 생성합니다.

## 사용법

### 호출 방법

```bash
# 금주 뉴스레터 생성 (토~금 기준)
/weekly-newsletter

# 특정 주차 뉴스레터 생성
/weekly-newsletter 2026-W03
```

### 예시

```bash
# 매주 토요일 오전에 실행
/weekly-newsletter

# 생성 위치: $VAULT_ROOT/newsletters/2026-W09-newsletter.md
```

**주의**: 이 스킬에서 "주(week)"는 **토요일~금요일** 기준입니다. ISO 주차(월~일)와 다릅니다.

## 주요 기능

### 1. 서브 에이전트 병렬 처리

3개의 서브 에이전트(Daily Notes, coffee-time, 주간 문서)가 동시 실행되어 분석 결과를 메인 에이전트에 전달합니다. 메인 에이전트는 분석된 결과만 받아 뉴스레터를 작성하므로 컨텍스트가 최소화됩니다.

```
Main Agent → [SubAgent 1, SubAgent 2, SubAgent 3] → 결과 통합 → 뉴스레터 작성
```

### 2. 외부 공유 필터링

- **포함**: 기술 트렌드, 리더십 인사이트, 학습 방법론, 업계 동향
- **제외**: 내부 업무 세부사항, 회사 프로세스, 고객/파트너 정보

### 3. 구조화된 뉴스레터 생성

- 커피타임 하이라이트
- 기술 트렌드
- 리더십 & 조직 인사이트
- 주간 업무 하이라이트
- 이번 주 핵심 교훈
- 다음 주 포커스

### 4. CTO 관점의 톤앤매너

`~/git/aboutme/AI-PROFILE.md`의 프로필을 반영하여 30년 경력 개발자 관점, TDD/Clean Code 철학, 점진적 개선 관점으로 뉴스레터를 작성합니다.

## 의존성

### 경로
- Vault: `$VAULT_ROOT/`
- Daily Notes: `$VAULT_ROOT/notes/dailies/`
- Coffee-time: `$VAULT_ROOT/coffee-time/`
- 출력 위치: `$VAULT_ROOT/newsletters/`
- 사용자 프로필: `~/git/aboutme/AI-PROFILE.md`

### 관련 스킬
- `daily-work-logger`: 매일 업무 내역 정리 (이 스킬의 입력 소스)
- `obsidian-vault`: vault 작업 기본 가이드

### 환경 요구사항
- macOS `date` 명령어 (ISO 주차 계산)
- `find`, `stat`, `awk` (파일 검색)
- Read/Write 도구

## 참고

- **주차 정의**: 토요일~금요일 (ISO 주차와 다름)
- **실행 빈도**: 매주 토요일 오전 권장
- **모델**: 서브 에이전트는 haiku 사용 (비용/속도 최적화)
- **실패 격리**: 하나의 서브 에이전트 실패 시 해당 섹션만 "분석 실패"로 표시, 나머지는 정상 생성
- **의존 관계**: `daily-work-logger` → `dailies/*.md` → `weekly-newsletter` → `newsletters/*.md`
