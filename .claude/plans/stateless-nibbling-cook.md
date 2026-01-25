# AI 활용 기법 수집 계획

## 개요

**목표**: ~/DocumentsLocal/msbaek_vault/003-RESOURCES/AI 폴더의 286개 문서에서 AI 활용 기법들을 체계적으로 수집

**선택된 옵션**:
- 배치 크기: 10개/배치 (29개 배치)
- 추출 범위: 상세 분석 (기법명, 설명, 적용 조건, 예시, 관련 도구, 주의사항)
- 결과 형식: 카테고리별 정리 (프롬프트/에이전트/도구 등)

**폴더 구조**:
- 루트 레벨: 177개 파일
- 하위 폴더: 109개 파일 (13개 폴더)

---

## 아키텍처 설계

### 1. 3-Tier 에이전트 구조

```
┌─────────────────────────────────────────────────────────┐
│                 Coordinator Agent                        │
│  (전체 워크플로우 조율, 진행 상태 관리, 결과 통합)         │
└─────────────────────────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│  Analyzer   │   │  Analyzer   │   │  Analyzer   │
│  Agent 1    │   │  Agent 2    │   │  Agent N    │
│ (병렬 조사) │   │ (병렬 조사) │   │ (병렬 조사) │
└─────────────┘   └─────────────┘   └─────────────┘
                          │
                          ▼
              ┌─────────────────────┐
              │   Collector Agent   │
              │  (결과 수집 및 통합) │
              └─────────────────────┘
```

### 2. 배치 처리 전략

- **배치 크기**: 10개 문서/배치 (토큰 효율성 고려)
- **총 배치 수**: 약 29개 배치
- **병렬 에이전트**: 최대 5개 동시 실행

---

## 실행 계획

### Phase 1: 초기화 (현재 세션)
1. 전체 파일 목록 생성 및 저장
2. 진행 상태 추적 파일 생성 (`plans/ai-practice-progress.md`)
3. TODO 리스트 생성 (`plans/ai-practice-todo.md`)

### Phase 2: 문서 분석 (다중 세션)
1. 배치 단위로 Analyzer Agent 실행
2. 각 문서에서 추출:
   - AI 활용 기법/패턴
   - 핵심 인사이트
   - 실천 가능한 팁
   - 관련 도구/기술
3. 배치 완료 시마다 진행 상태 업데이트

### Phase 3: 결과 수집 (배치 완료 후)
1. Collector Agent가 배치 결과 통합
2. 중복 제거 및 카테고리화
3. 최종 보고서 생성

---

## 파일 구조

```
plans/
├── ai-practice-plan.md       # 이 계획 파일
├── ai-practice-todo.md       # 전체 TODO 리스트
├── ai-practice-progress.md   # 진행 상태 추적
├── ai-practice-files.md      # 전체 파일 목록
└── ai-practice-results/      # 수집된 결과
    ├── batch-01-results.md
    ├── batch-02-results.md
    └── final-report.md
```

---

## 진행 상태 추적 형식

### ai-practice-progress.md 구조
```markdown
## 진행 상태
- 총 문서: 286개
- 완료: XX개 (XX%)
- 진행 중: X개
- 대기: XX개

## 완료된 배치
- [x] Batch 01 (1-10): 완료 - 2025-01-03
- [ ] Batch 02 (11-20): 진행 중
- [ ] Batch 03 (21-30): 대기

## 완료된 문서 목록
1. [x] 파일명1.md
2. [x] 파일명2.md
...
```

---

## 세션 이어가기 가이드

### 토큰 고갈 시 다음 세션에서:

1. **진행 상태 확인**:
   ```
   plans/ai-practice-progress.md 파일 확인
   ```

2. **이어서 실행할 명령**:
   ```
   "AI 활용 기법 수집 작업을 이어서 진행해줘.
   plans/ai-practice-progress.md 파일에서 현재 진행 상태를 확인하고,
   다음 배치부터 처리해줘."
   ```

3. **전체 재시작 명령**:
   ```
   "AI 활용 기법 수집 작업을 처음부터 다시 시작해줘."
   ```

---

## 구현 상세 단계

### Step 1: 초기화 (현재 세션에서 실행)
```bash
# 실행할 작업
1. plans/ai-practice-files.md 생성 (286개 파일 전체 목록)
2. plans/ai-practice-todo.md 생성 (29개 배치 TODO)
3. plans/ai-practice-progress.md 생성 (진행 상태 추적)
4. plans/ai-practice-results/ 폴더 생성
```

### Step 2: 문서 분석 (배치 처리)
```
각 배치마다:
1. Analyzer Agent 5개를 병렬 실행 (각각 2개 문서 담당)
2. 각 문서에서 추출:
   - AI 활용 기법/패턴 이름
   - 상세 설명
   - 적용 조건 및 상황
   - 구체적인 예시
   - 관련 도구/기술
   - 주의사항 및 한계
3. 배치 결과를 plans/ai-practice-results/batch-XX-results.md에 저장
4. plans/ai-practice-progress.md 업데이트
```

### Step 3: 결과 수집 (5배치마다)
```
1. Collector Agent가 완료된 배치 결과 통합
2. 중복 기법 병합
3. 카테고리별 분류 진행
```

### Step 4: 최종 보고서 (모든 배치 완료 후)
```
1. 전체 결과 통합
2. 카테고리별 최종 정리
3. plans/ai-practice-results/final-report.md 생성
```

---

## 생성될 파일 목록

| 파일 | 용도 |
|-----|------|
| `plans/ai-practice-plan.md` | 이 계획 파일 (영구 보관) |
| `plans/ai-practice-files.md` | 전체 286개 파일 목록 |
| `plans/ai-practice-todo.md` | 29개 배치 TODO 리스트 |
| `plans/ai-practice-progress.md` | 실시간 진행 상태 |
| `plans/ai-practice-results/` | 배치별 결과 저장 폴더 |

---

## 예상 소요

- 배치당 약 5-10분 (병렬 처리 시)
- 전체 29개 배치: 약 3-5세션 필요 (토큰 제한 고려)
- 최종 보고서 작성: 1세션

---

## 결과물 형식

### 최종 보고서 (final-report.md)
```markdown
# AI 활용 기법 종합 보고서

## 1. 핵심 기법 카테고리
### 1.1 프롬프트 엔지니어링
### 1.2 AI 페어 프로그래밍
### 1.3 에이전트 활용
...

## 2. 도구별 활용법
### 2.1 Claude Code
### 2.2 Cursor
### 2.3 MCP
...

## 3. 실천 가능한 팁 (Top 50)
## 4. 주의사항 및 한계
## 5. 참조 문서 목록
```
