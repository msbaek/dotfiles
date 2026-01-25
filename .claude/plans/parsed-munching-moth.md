# ~/.claude 활용 최종 계획

## 사용자 요구사항

1. **일일 작업 요약** → Daily Notes 반영
2. **시간 추적** → 프로젝트별 작업 시간 측정
3. **학습 기록** → 새로 배운 것들 자동 추적
4. **패턴 분석** → 도구 사용 패턴, 생산성 트렌드

---

## 현황 분석

### 데이터 자원 (이미 존재)

| 자원 | 위치 | 활용 가능 정보 |
|------|------|---------------|
| `history.jsonl` | `~/.claude/` | 32,116개 프롬프트 기록 |
| `stats-cache.json` | `~/.claude/` | 세션/토큰 통계, 시간대별 분포 |
| `transcripts/*.jsonl` | `~/.claude/transcripts/` | 세션별 상세 대화 |
| `projects/[path]/*.jsonl` | `~/.claude/projects/` | 프로젝트별 세션 로그 |

### 기존 스킬 (개선 대상)

| 스킬 | 현재 상태 | 개선 필요 |
|------|----------|----------|
| `daily-work-logger` | 서브 에이전트 구조 완성 | 테스트 및 검증 필요 |
| `weekly-claude-analytics` | 기본 구조 완성 | 패턴 분석 강화 |

---

## 실행 계획

### Phase 1: 기존 스킬 검증 및 개선

#### 1.1 daily-work-logger 테스트
- `/daily-work-logger` 실행하여 동작 확인
- 서브 에이전트 병렬 실행 검증
- Daily Note 반영 형식 확인

#### 1.2 weekly-claude-analytics 테스트
- `/weekly-claude-analytics` 실행
- 프로젝트별 시간 분포 정확성 검증
- 작업 유형 분류 검증

### Phase 2: learning-tracker 스킬 (이중 활용)

#### 2.1 learning-tracker 설계

**사용 방식 2가지**:
1. **자동 실행**: `/daily-work-logger` 실행 시 서브 에이전트로 자동 호출
2. **독립 실행**: `/learning-tracker` 로 직접 호출 가능

**위치**: `~/.claude/skills/learning-tracker/SKILL.md`

**핵심 기능**:
- 세션에서 새로운 기술/라이브러리/개념 언급 감지
- 학습 키워드 패턴: "배웠", "알게 됐", "처음", "새로운", "TIL"
- 질문 패턴: "이게 뭐야?", "어떻게 해?", "왜?"
- Obsidian Daily Note 또는 별도 TIL 문서로 출력

**데이터 소스**:
- `history.jsonl` - 사용자 질문 패턴
- `transcripts/*.jsonl` - 상세 대화 내용

#### 2.2 daily-work-logger 확장

**기존 구조** (3개 서브 에이전트):
```
Main Agent
├── SubAgent 1: Vault Files Analyzer
├── SubAgent 2: Claude Sessions Analyzer
└── SubAgent 3: Meeting Notes Analyzer
```

**확장 구조** (4개 서브 에이전트):
```
Main Agent
├── SubAgent 1: Vault Files Analyzer
├── SubAgent 2: Claude Sessions Analyzer
├── SubAgent 3: Meeting Notes Analyzer
└── SubAgent 4: Learning Extractor ← /learning-tracker 스킬 호출
```

**장점**:
- `/daily-work-logger` 실행 시 학습 내용도 자동 수집
- `/learning-tracker` 단독 실행으로 학습만 별도 추적 가능
- 코드 중복 없음 (동일 스킬 재사용)

#### 2.2 project-time-tracker 스킬 (시간 추적)

**위치**: `~/.claude/skills/project-time-tracker/SKILL.md`

**핵심 기능**:
- 프로젝트별 세션 시간 집계 (시작~종료 타임스탬프)
- 일별/주별/월별 시간 리포트
- Obsidian 테이블로 시각화

**데이터 소스**:
- `projects/[encoded-path]/*.jsonl` - 세션 타임스탬프
- JSONL 파싱: 첫 번째/마지막 레코드 시간 차이

#### 2.3 usage-pattern-analyzer 스킬 (패턴 분석)

**위치**: `~/.claude/skills/usage-pattern-analyzer/SKILL.md`

**핵심 기능**:
- 도구 사용 빈도 분석 (Read, Edit, Write, Bash 등)
- 시간대별 생산성 패턴
- 반복 작업 감지 → 스킬/에이전트 제안
- `stats-cache.json` 데이터 시각화

**데이터 소스**:
- `stats-cache.json` - 집계 통계
- `transcripts/*.jsonl` - 도구 호출 상세

---

## 수정 대상 파일

### 기존 파일 (검증/개선)
- `~/.claude/skills/daily-work-logger/SKILL.md` ← **SubAgent 4로 learning-tracker 호출 추가**
- `~/.claude/skills/weekly-claude-analytics/SKILL.md`

### 신규 파일 (생성)
- `~/.claude/skills/learning-tracker/SKILL.md` ← **독립 실행 + daily-work-logger 연동**
- `~/.claude/skills/project-time-tracker/SKILL.md`
- `~/.claude/skills/usage-pattern-analyzer/SKILL.md`

---

## 검증 방법

### 기존 스킬 테스트
```bash
# daily-work-logger 실행
claude "/daily-work-logger"

# weekly-claude-analytics 실행
claude "/weekly-claude-analytics"
```

### 신규 스킬 테스트
- 각 스킬 생성 후 실제 실행
- 출력 파일 확인 (Obsidian vault)
- 데이터 정확성 검증

---

## 예상 결과물

### Daily Note에 추가될 섹션
```markdown
## 작업 내역

### Claude Code 작업
- **project-a**: 기능 개발 (2h 30m)
- **project-b**: 버그 수정 (1h)

### 학습 기록
- [[TIL/2026-01-17-new-api]]: 새로운 API 사용법 학습
```

### 프로젝트 시간 리포트
```markdown
## 이번 주 시간 분포

| 프로젝트 | 월 | 화 | 수 | 목 | 금 | 합계 |
|---------|-----|-----|-----|-----|-----|------|
| dotfiles | 1h | 2h | - | 30m | 1h | 4h30m |
| mercury | - | 3h | 2h | 1h | - | 6h |
```

---

## Uncertainty Map

- **학습 감지 정확도**: 키워드 기반 감지의 정밀도는 실제 테스트 필요
- **시간 계산 정확성**: 세션 간 공백 시간 처리 방식 결정 필요
- **패턴 분석 깊이**: 어느 수준까지 분석할지 (단순 빈도 vs 상관관계)
