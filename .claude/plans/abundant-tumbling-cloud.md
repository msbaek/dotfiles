# 나의 AI 활용 사례 문서화 계획

## 프로젝트 개요

**목표**: Obsidian vault와 coffee-time 문서에서 AI 활용 사례를 수집, 그룹핑하여 이력서/블로그용 문서 생성

**최종 산출물**: 3개 버전의 문서
- `나의 AI 활용 사례-내부용.md` - 민감정보 포함, 상세 버전
- `나의 AI 활용 사례-이력서용.md` - 간결, 임팩트 중심
- `나의 AI 활용 사례-블로그용.md` - 스토리텔링, 프로세스 상세

---

## 1단계: 데이터 소스 수집

### 1.1 대상 소스 (우선순위순)

| 소스 | 경로 | 예상 문서 수 | 우선순위 |
|------|------|-------------|---------|
| **Claude Code plans** | `~/.claude/plans/` | 50+개 | ⭐⭐⭐ |
| **Claude Code projects** | `~/.claude/projects/*/session-memory/summary.md` | 27개 | ⭐⭐⭐ |
| cc-logs | `/Users/msbaek/DocumentsLocal/msbaek_vault/cc-logs/` | 4개 | ⭐⭐⭐ |
| coffee-time | `/Users/msbaek/git/kt4u/coffee-time/` | 53개 | ⭐⭐⭐ |
| **Claude Code todos** | `~/.claude/todos/` | 100+개 JSON | ⭐⭐ |
| daily notes | `/Users/msbaek/DocumentsLocal/msbaek_vault/notes/dailies/2025/` | 191개 | ⭐⭐ |
| work-log | `/Users/msbaek/DocumentsLocal/msbaek_vault/work-log/` | 466개 | ⭐⭐ |
| TIL/학습노트 | `997-BOOKS/` 등 | 다수 | ⭐ |

### 1.1.1 Claude Code 관련 소스 상세

**~/.claude/plans/** (핵심 소스)
- 50개 이상의 계획 파일 (각 4-20KB)
- 프로젝트별 AI 협업 계획 상세 기록
- 파일명: `{형용사}-{동사}-{명사}.md` 형식

**~/.claude/projects/** (프로젝트별 기록)
- 27개 프로젝트 폴더
- 각 프로젝트별 `session-memory/summary.md` 포함
- 주요 프로젝트: kt4u-*, vault-intelligence, dotfiles

**~/.claude/todos/** (작업 기록)
- 100개 이상의 JSON 파일
- 각 세션의 작업 목록 및 진행 상태

### 1.2 검색 전략 (vault-intelligence 활용)

**1차 검색 키워드**:
```bash
python -m src search --query "Claude Code 활용 사례" --rerank --top-k 50
python -m src search --query "AI로 코드 리팩토링" --rerank --top-k 30
python -m src search --query "ChatGPT 개발 생산성" --rerank --top-k 30
python -m src search --query "LLM 프롬프트 엔지니어링" --rerank --top-k 30
```

**2차 검색 (도메인별)**:
- 개발: "Claude 아키텍처 설계", "AI 코드리뷰", "TDD AI"
- 문서화: "AI 문서 작성", "자동 요약"
- 학습: "AI 학습 도우미", "개념 설명"
- 자동화: "워크플로우 자동화", "스크립트 생성"

---

## 2단계: 사례 분류 체계

### 2.1 1차 분류: 업무 도메인별
```
1. 코드 개발
   - 신규 기능 구현
   - 리팩토링/개선
   - 버그 수정
   - 코드 리뷰

2. 아키텍처/설계
   - 시스템 설계
   - 기술 의사결정
   - 문제 분석

3. 문서화
   - 기술 문서 작성
   - README/가이드
   - 코드 주석

4. 학습/연구
   - 신기술 학습
   - 개념 이해
   - 트렌드 분석

5. 자동화/효율화
   - 반복 작업 자동화
   - 스크립트 생성
   - 워크플로우 개선
```

### 2.2 2차 분류: 문제 해결 유형별
```
A. 자동화 (Automation)
B. 분석/통찰 (Analysis)
C. 창작/생성 (Creation)
D. 검토/개선 (Review)
E. 학습/이해 (Learning)
```

### 2.3 메타데이터 스키마
```yaml
- 제목: string
- 날짜: YYYY-MM-DD
- 도구: Claude Code | ChatGPT | GitHub Copilot | 기타
- 도메인: 코드개발 | 아키텍처 | 문서화 | 학습 | 자동화
- 유형: 자동화 | 분석 | 창작 | 검토 | 학습
- 결과: string (정량적 성과 또는 정성적 결과)
- 상세수준: 간략 | 상세
- 민감정보: true | false
- 원본출처: 파일경로
```

---

## 3단계: 문서 구조

### 3.1 내부용 (상세)
```markdown
# 나의 AI 활용 사례 (내부용)

## 요약 통계
- 총 사례 수: N개
- 기간: YYYY-MM ~ YYYY-MM
- 주요 도구: Claude Code (N%), ChatGPT (N%), ...

## 업무 도메인별 사례

### 1. 코드 개발 (N건)
#### 1.1 [사례명] - YYYY-MM-DD
- **도구**: Claude Code
- **배경**: [프로젝트명, 상황 설명]
- **문제**: [해결해야 할 문제]
- **접근법**: [AI와 어떻게 협업했는지]
- **결과**: [정량적/정성적 성과]
- **교훈**: [배운 점, 개선점]

...이하 반복
```

### 3.2 이력서용 (간결)
```markdown
# AI 활용 역량

## 핵심 성과 요약
- Claude Code를 활용한 개발 생산성 N% 향상
- AI 기반 코드 리뷰로 버그 사전 탐지율 N% 개선
- N개 프로젝트에서 AI 협업 워크플로우 적용

## 대표 사례

### 1. [대규모 레거시 시스템 리팩토링]
**도구**: Claude Code | **기간**: 3개월
- N만 라인 코드베이스 현대화
- 기존 대비 N% 성능 개선
- AI와 페어 프로그래밍으로 복잡한 비즈니스 로직 이해

### 2. [실시간 데이터 파이프라인 설계]
...
```

### 3.3 블로그용 (스토리텔링)
```markdown
# 30년 경력 개발자의 AI 협업 여정

## 들어가며
[개인적 경험과 AI 도입 배경 스토리]

## Part 1: 회의에서 확신으로
[초기 시행착오와 전환점 사례]

## Part 2: 실전 활용 노하우
### 2.1 [사례: 복잡한 레거시 코드와의 싸움]
#### 상황
[구체적인 문제 상황 묘사]

#### AI와의 대화
[실제 프롬프트와 응답 예시]

#### 결과와 교훈
[성과 + 시니어 관점에서의 인사이트]

## Part 3: AI 시대의 시니어 개발자
[경험과 AI의 시너지, 후배 개발자에게 전하는 메시지]
```

---

## 4단계: 실행 계획

### 4.1 수집 단계
1. **~/.claude/plans/ 전체 읽기** (50+개 파일) - AI 협업 계획 기록
2. **~/.claude/projects/*/summary.md 읽기** (27개 프로젝트) - 세션 요약
3. **cc-logs 전체 읽기** (4개 파일)
4. **coffee-time 전체 읽기** (53개 파일) - 민감정보 마킹
5. **~/.claude/todos/ 샘플링** (JSON에서 작업 내용 추출)
6. **vault-intelligence로 daily notes/work-log 검색**
7. **모든 사례를 임시 수집 문서에 기록**

### 4.2 분류 및 정제 단계
1. **메타데이터 부여** (날짜, 도구, 도메인, 유형)
2. **중복 제거** 및 유사 사례 병합
3. **민감정보 표시** (coffee-time, 사내 프로젝트)
4. **중요도 평가** (사용자 검토용)

### 4.3 문서화 단계
1. **내부용 초안 작성** (전체 사례 포함)
2. **사용자 검토 및 선별**
3. **이력서용 추출** (대표 사례 3-5개)
4. **블로그용 재구성** (스토리 형식)

### 4.4 익명화 단계 (외부 공개용)
- 프로젝트명 → 일반화된 설명
- 고객사명 → 업종/규모로 대체
- 구체적 수치 → 범위 또는 비율로 표현

---

## 5단계: 검증

### 5.1 완료 기준
- [ ] 모든 소스에서 AI 활용 사례 수집 완료
- [ ] 분류 체계에 따라 정리 완료
- [ ] 3개 버전 문서 초안 작성
- [ ] 사용자 검토 후 최종 확정
- [ ] 민감정보 익명화 확인

### 5.2 품질 체크
- 각 사례에 메타데이터(날짜, 도구, 결과) 포함 여부
- 이력서용: 정량적 성과 포함 여부
- 블로그용: 스토리 흐름 및 가독성
- 익명화: 사내 정보 노출 여부

---

## 주요 파일 경로

- **수집 대상 (Claude Code 관련)**:
  - `/Users/msbaek/.claude/plans/` - 50+개 계획 파일
  - `/Users/msbaek/.claude/projects/*/session-memory/summary.md` - 27개 프로젝트 요약
  - `/Users/msbaek/.claude/todos/` - 100+개 작업 기록 (JSON)

- **수집 대상 (Obsidian vault)**:
  - `/Users/msbaek/DocumentsLocal/msbaek_vault/cc-logs/`
  - `/Users/msbaek/git/kt4u/coffee-time/`
  - `/Users/msbaek/DocumentsLocal/msbaek_vault/notes/dailies/2025/`
  - `/Users/msbaek/DocumentsLocal/msbaek_vault/work-log/`

- **산출물 (예정)**:
  - `/Users/msbaek/DocumentsLocal/msbaek_vault/나의 AI 활용 사례-내부용.md`
  - `/Users/msbaek/DocumentsLocal/msbaek_vault/나의 AI 활용 사례-이력서용.md`
  - `/Users/msbaek/DocumentsLocal/msbaek_vault/나의 AI 활용 사례-블로그용.md`

---

## Uncertainty Map

**높은 확도**:
- 파일 위치 및 구조 (탐색 완료)
- 분류 체계 및 메타데이터 스키마
- 문서 구조 템플릿

**중간 확도**:
- 실제 수집될 사례 수 (예상 30-100개)
- 각 사례의 상세 수준
- 익명화 필요 범위

**확인 필요**:
- 사용자가 원하는 대표 사례 선별 기준
- 블로그 연재 계획 여부 (단일 포스트 vs 시리즈)
- 이력서에 포함할 정량적 수치의 정확도
