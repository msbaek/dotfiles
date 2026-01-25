# AI 활용 MOC 생성 계획

## 목표
vault에서 발견한 AI 활용 관련 50개 문서를 분석하여 체계적인 MOC(Map of Content) 생성

## 발견된 주요 카테고리

### 1. AI 한계와 문제점 (LIMITATIONS)
- AI 문제점 종합 분석
- 테드 창 - AI에 대한 통찰과 예술의 미래
- 인공지능이 우리 삶을 더 힘들게 만드는 진짜 이유
- AI를 활용한 개발 가이드 (한계 관점)
- AI를 활용한 레거시 시스템 현대화

### 2. AI 도구 및 프레임워크 (TOOLS)
- Claude Code 개요
- Context Engineering: AI 코딩의 새로운 패러다임
- Fabric (AI 프레임워크)
- Claude Code and the Future of Software Engineering

### 3. Spring AI 시리즈
- Spring AI를 활용한 RAG 구현 가이드
- Spring AI MCP Boot Starters
- Spring AI Text-to-SQL 구현 가이드

### 4. DDD/설계와 AI
- 생성형 AI를 활용한 DDD 지원
- 소프트웨어 아키텍처와 DDD

### 5. AI 개발자 전략
- AI가 소프트웨어 개발에 미치는 영향
- 나날이 발전하고픈 개발자를 위한 AI 활용법
- 실무에서 바이브 코딩
- AI 시대의 일자리 변화와 생존 전략
- 생성형 AI가 소프트웨어 개발에 미치는 영향

### 6. 프롬프트 엔지니어링
- Useful Prompts
- my prompts

### 7. RAG (검색 증강 생성)
- 옵시디언 볼트를 개인 AI 어시스턴트로: RAG 접근법
- RAG 기본 개념 및 AWS 구현 방법

### 8. Spec-Driven Development
- 스펙 주도 개발 이해하기: Kiro, Spec-kit, Tessl

## 실행 계획

### Step 1: MOC 파일 생성
- 위치: `003-RESOURCES/AI/AI-활용-MOC.md`
- 구조: 카테고리별 섹션으로 구성

### Step 2: MOC 내용 구성
1. 개요 섹션 - AI 활용의 전체 맥락
2. 카테고리별 문서 링크 (위 8개 카테고리)
3. 관련 태그 추가

### Step 3: 태그 추가
- `#moc/ai-활용`
- `#ai/overview`

## 생성할 MOC 구조

```markdown
# AI 활용 종합 가이드 (MOC)

## 개요
AI를 소프트웨어 개발에 효과적으로 활용하기 위한 종합 가이드

## 카테고리별 문서

### AI 한계와 현실적 관점
- [[문서링크들]]

### AI 도구 및 프레임워크
- [[문서링크들]]

... (각 카테고리)

## 관련 MOC
- [[TDD-MOC]]
- [[DDD-MOC]]
```

## 확정 사항
- **MOC 파일 위치**: `003-RESOURCES/AI/AI-활용-MOC.md`
- **포함 카테고리**: 전체 8개 카테고리 모두 포함

## Uncertainty Map
- **낮은 확신**: 일부 문서들이 중복(같은 내용, 다른 경로)될 수 있음 - RAW 폴더와 일반 폴더에 동일 문서 존재
- **검토 필요**: 검색 결과 중 AI와 직접 관련 없는 문서(레거시 코드 테스팅, TDD 등)가 포함되어 있을 수 있음
- **향후 개선**: MOC 생성 후 실제 문서 내용을 확인하여 카테고리 재조정 가능
