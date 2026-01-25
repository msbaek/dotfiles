# AI 활용 기법 통합 및 가이드 생성 계획

## 🔄 진행 상황 (2026-01-04 완료)

| Phase | 작업 | 상태 | 비고 |
|-------|------|------|------|
| **1.1** | 배치 01-10 파싱 | ✅ 완료 | 66개 기법 추출 |
| **1.1** | 배치 11-20 파싱 | ✅ 완료 | ~95개 기법 추출 |
| **1.1** | 배치 21-29 파싱 | ✅ 완료 | 125개 기법 추출 |
| **1.2** | 중복 제거 | ✅ 완료 | 1745→1403개 (19.6% 중복률) |
| **1.3** | 마스터 문서 생성 | ✅ 완료 | AI-Practice-Master.md (306k) |
| **2** | 카테고리 재구성 (6개) | ✅ 완료 | 6개 심층 분석 문서 |
| **3** | 실용 가이드 4종 | ✅ 완료 | Quick Ref, Daily, Claude Code, TDD+AI |
| **4** | Obsidian 노트 52개 | ✅ 완료 | MOC + 6 categories + 4 guides + 30 techniques |

### Phase 1.2 결과
- **원본 기법**: 1,745개
- **중복 제거 후**: 1,403개
- **중복 그룹**: 161개
- **중복률**: 19.6%
- **카테고리별 분포**:
  - AI-Assisted Development: 574개 (40.9%)
  - Prompt Engineering: 272개 (19.4%)
  - Agent & Workflow: 187개 (13.3%)
  - Tools & Integration: 179개 (12.8%)
  - Quality & Security: 122개 (8.7%)
  - Learning & Mindset: 69개 (4.9%)

### 생성된 폴더 구조 ✅
- `plans/ai-practice-consolidated/categories/`
- `plans/ai-practice-guides/tools/`
- `plans/ai-practice-guides/workflows/`
- `~/DocumentsLocal/msbaek_vault/003-RESOURCES/AI/AI-Practice-Techniques/categories/`
- `~/DocumentsLocal/msbaek_vault/003-RESOURCES/AI/AI-Practice-Techniques/guides/`
- `~/DocumentsLocal/msbaek_vault/003-RESOURCES/AI/AI-Practice-Techniques/techniques/`

---

## 개요

29개 배치 파일(286개 문서, ~2,319개 기법)을 통합하여:
1. 마스터 문서 생성
2. 6개 카테고리로 재구성 및 심층 분석
3. 4종 실용 가이드 생성
4. Obsidian vault에 체계적 저장

---

## Phase 1: 데이터 통합 및 분석

### 1.1 배치 파일 파싱 (병렬 처리)

**입력**: `plans/ai-practice-results/batch-01~29-results.md`

**작업**:
- 3개 에이전트 병렬 처리 (batch 01-10, 11-20, 21-29)
- 각 기법 추출: 기법명, 설명, 카테고리, 관련 도구, 출처

**출력**:
- `plans/ai-practice-consolidated/ai-techniques-raw.json`

### 1.2 중복 제거

**기준**:
- 기법명 유사도 (Levenshtein distance < 3)
- 설명 의미적 유사도 (cosine > 0.85)

**병합 규칙**:
- 가장 상세한 설명 선택
- 출처 문서 누적
- 관련 도구 합집합

**출력**:
- `plans/ai-practice-consolidated/ai-techniques-deduplicated.json`
- `plans/ai-practice-consolidated/deduplication-report.md`

### 1.3 마스터 문서 생성

**출력**: `plans/ai-practice-consolidated/AI-Practice-Master.md`

```
# AI 활용 기법 마스터 문서
## 개요 (통계 요약)
## 카테고리별 분포
## 전체 기법 목록 (중복 제거 후)
```

---

## Phase 2: 카테고리 재구성 (19개 → 6개)

### 2.1 새 카테고리 체계

| # | 카테고리 | 통합 대상 | 예상 비율 |
|---|----------|-----------|-----------|
| 1 | **Prompt Engineering** | 프롬프트 엔지니어링, 컨텍스트 엔지니어링 | ~20% |
| 2 | **AI-Assisted Development** | TDD+AI, Spec-Driven, Vibe Coding | ~25% |
| 3 | **Agent & Workflow** | AI 에이전트, 워크플로우, 자동화 | ~20% |
| 4 | **Quality & Security** | 코드 품질, 검증, 보안, AI 한계 | ~15% |
| 5 | **Tools & Integration** | MCP, Claude Code, Cursor, 도구 | ~15% |
| 6 | **Learning & Mindset** | 학습, 역량, 마인드셋, 협업 문화 | ~5% |

### 2.2 카테고리별 심층 분석 문서

**출력**: `plans/ai-practice-consolidated/categories/`

각 카테고리별 생성:
- `category-01-prompt-engineering.md`
- `category-02-ai-assisted-development.md`
- `category-03-agent-workflow.md`
- `category-04-quality-security.md`
- `category-05-tools-integration.md`
- `category-06-learning-mindset.md`

**각 문서 구조**:
```
# [카테고리명] 심층 분석
## 핵심 기법 TOP 10
## 기법 관계도 (Mermaid)
## 실무 적용 체크리스트
## 학습 경로 (입문→중급→고급)
```

---

## Phase 3: 실용 가이드 생성

### 3.1 Quick Reference Card

**출력**: `plans/ai-practice-guides/quick-reference-card.md`

```
# AI 활용 기법 Quick Reference
## 프롬프트 작성 5원칙
## 상황별 빠른 선택 테이블
## 필수 파일 구조 (CLAUDE.md, AGENTS.md 등)
## 핵심 프롬프트 템플릿 (5개)
```

### 3.2 Daily Workflow Guide

**출력**: `plans/ai-practice-guides/daily-workflow-guide.md`

```
# AI 활용 일일 워크플로우
## 아침: 계획 수립 (Spec → Plan 모드)
## 오전: 핵심 구현 (TDD 사이클)
## 오후: 확장 및 통합
## 저녁: 정리 및 문서화
## 일일 체크리스트
```

### 3.3 Claude Code 전용 가이드

**출력**: `plans/ai-practice-guides/tools/claude-code-guide.md`

```
# Claude Code 완전 가이드
## 필수 설정 (CLAUDE.md, Skills, Hooks)
## 핵심 명령어 10선
## 서브에이전트 활용법
## MCP 서버 통합
## 고급 팁 (Worktrees, Checkpoints)
```

### 3.4 TDD+AI 워크플로우

**출력**: `plans/ai-practice-guides/workflows/tdd-ai-workflow.md`

```
# TDD + AI 통합 워크플로우
## Red-Green-Refactor + AI 역할
## Spec-First 접근법
## AI 생성 코드 검증 체크리스트
## 실전 예제 (Spring Boot)
```

---

## Phase 4: Obsidian 노트 생성

### 4.1 폴더 구조

```
~/DocumentsLocal/msbaek_vault/003-RESOURCES/AI/AI-Practice-Techniques/
├── _AI-Practice-MOC.md          # Map of Content
├── categories/
│   ├── prompt-engineering.md
│   ├── ai-assisted-development.md
│   ├── agent-workflow.md
│   ├── quality-security.md
│   ├── tools-integration.md
│   └── learning-mindset.md
├── guides/
│   ├── quick-reference.md
│   ├── daily-workflow.md
│   ├── claude-code-guide.md
│   └── tdd-ai-workflow.md
└── techniques/                   # TOP 30 핵심 기법
    ├── sticc-prompting.md
    ├── spec-first-development.md
    └── ... (28개 더)
```

### 4.2 태그 전략 (Hierarchical Tags)

```yaml
# 카테고리 태그
- ai/practice/prompt-engineering
- ai/practice/development
- ai/practice/agent
- ai/practice/quality
- ai/practice/tools
- ai/practice/learning

# 문서 유형 태그
- type/guide
- type/reference
- type/moc
- type/technique

# 도구 태그
- tools/claude-code
- tools/cursor
- tools/mcp
```

### 4.3 MOC 문서

**출력**: `_AI-Practice-MOC.md`

```markdown
---
tags:
  - ai/practice
  - type/moc
created: 2026-01-04
---

# AI 활용 기법 Map of Content

## 통계
- 총 기법 수: XXX개
- 카테고리: 6개
- 원본 문서: 286개

## 카테고리별 탐색
### [[prompt-engineering|Prompt Engineering]]
### [[ai-assisted-development|AI-Assisted Development]]
...

## Quick Links
- [[quick-reference|Quick Reference Card]]
- [[daily-workflow|Daily Workflow]]
```

---

## 실행 순서 및 병렬화

```
Phase 1: 데이터 통합 (30분)
├── [병렬] 배치 01-10 파싱
├── [병렬] 배치 11-20 파싱
├── [병렬] 배치 21-29 파싱
└── 중복 제거 및 마스터 문서 생성

Phase 2: 카테고리 분석 (45분)
├── 기법 재분류
└── [병렬] 6개 카테고리 심층 분석 문서 생성

Phase 3: 가이드 생성 (30분)
├── [병렬] Quick Reference Card
├── [병렬] Daily Workflow Guide
├── [병렬] Claude Code 가이드
└── [병렬] TDD+AI 워크플로우

Phase 4: Obsidian 통합 (30분)
├── 폴더 구조 생성
├── [병렬] MOC + 카테고리 노트
├── [병렬] 가이드 노트
└── [병렬] TOP 30 기법 노트
```

**총 예상 소요 시간**: 2-2.5시간

---

## 산출물 요약

| 유형 | 파일 수 | 위치 |
|------|--------|------|
| 마스터 문서 | 1 | plans/ai-practice-consolidated/ |
| 카테고리 분석 | 6 | plans/ai-practice-consolidated/categories/ |
| 실용 가이드 | 4 | plans/ai-practice-guides/ |
| Obsidian MOC | 1 | vault/.../AI-Practice-Techniques/ |
| Obsidian 카테고리 | 6 | vault/.../categories/ |
| Obsidian 가이드 | 4 | vault/.../guides/ |
| Obsidian 기법 노트 | 30 | vault/.../techniques/ |
| **총계** | **52개** | |

---

## Critical Files

### 입력 파일
- `plans/ai-practice-results/batch-*.md` (29개)
- `plans/ai-practice-progress.md` (진행 상태)

### 참조 파일
- `~/DocumentsLocal/msbaek_vault/WIP/TDD-MOC-완전정리.md` (MOC 패턴)
- `~/DocumentsLocal/msbaek_vault/000-SLIPBOX/AI 지원 TDD 실전 워크플로우.md` (기존 인사이트)

### 생성할 폴더
- `plans/ai-practice-consolidated/`
- `plans/ai-practice-consolidated/categories/`
- `plans/ai-practice-guides/`
- `plans/ai-practice-guides/tools/`
- `plans/ai-practice-guides/workflows/`
- `~/DocumentsLocal/msbaek_vault/003-RESOURCES/AI/AI-Practice-Techniques/`
