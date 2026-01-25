# AI 한계 MOC 작성 계획

## 작업 개요
vault-intelligence로 검색한 결과를 기반으로 AI의 한계에 대한 MOC(Map of Content) 문서를 작성합니다.

## MOC 저장 위치
`/Users/msbaek/DocumentsLocal/msbaek_vault/000-SLIPBOX/AI-한계-MOC.md`

## 핵심 주제 구조

### 1. 출력 신뢰성 문제
#### 1.1 Non-deterministic (비결정적) 특성
- 같은 입력에 대해 다른 출력 생성, 결과 예측 불가
- 재현성(Reproducibility) 부재로 디버깅 어려움
- **관련 문서**:
  - [[Embabel 프레임워크 분석 및 요약]] - GOAP 알고리즘으로 LLM 비결정성 보완
  - [[AI-문제점-종합-분석]] - 비결정적 특성 분류
  - [[Kent-Beck-on-AI-Coding-and-Tidy-First-Tim-OReilly-Interview]] - 컴파일러처럼 결정적이지 않음
  - [[Backlog-MD-and-Spec-Driven-Development]] - 스펙 기반 개발로 비결정성 극복

#### 1.2 Prompt Ambiguity (프롬프트 모호성)
- 자연어의 본질적 모호함으로 AI가 의도를 정확히 파악 어려움
- Acceptance Testing이 해결책으로 제시됨
- **관련 문서**:
  - [[AI-시대-개발자의-미래-뜬장의-시대]] - 프롬프트 모호성 문제
  - [[Chapter-17-AIs-LLMs-and-God-Knows-What]] - AI 코드 생성의 가장 큰 문제
  - [[The-Coming-of-the-New-Code-Specification-Driven-Development]] - Specification 중심 접근
  - [[Acceptance Testing Is the FUTURE of Programming]] - 모호함 해결, 재현성 보장

### 2. 내적 동기 부재
#### 2.1 직관과 내적 동기의 부재
- AI는 "더 좋은 코드를 만들고자 하는 내적 동기"가 없음
- 단순히 작동하는 코드와 유지보수 가능한 좋은 코드의 차이를 이해하지 못함
- **관련 문서**:
  - [[AI의 한계와 AI 시대 개발자들의 나아갈 길]] - 직관과 내적 동기의 부재
  - [[AI-시대-신입-개발자의-생존-전략-MOC]] - 내적 동기 부재 언급
  - [[AI Limitations]] - 인간 고유 역량으로서의 동기

### 3. 환각(Hallucination) 현상
- 존재하지 않는 정보를 사실인 것처럼 생성
- 존재하지 않는 API, 라이브러리, 논문 인용 문제
- **관련 문서**:
  - [[AI-시대의-채용과-HR-애널리틱스-어승수]] - 숫자 정확성 문제
  - [[Claude-Code-Prevention-Lying-Guide]] - Claude Code 거짓말 방지
  - [[Replit AI 데이터베이스 삭제 사건]] - 실제 피해 사례
  - [[Vibe-Coding with TDD and AI]] - TDD로 환각 통제

### 4. 본질적 복잡성 vs 우발적 복잡성
- AI는 GitHub에 공개된 일반적 기술 패턴(우발적 복잡성)만 잘 처리
- 기업 고유 비즈니스 도메인(본질적 복잡성)은 이해 불가
- **관련 문서**:
  - [[AI-문제점-종합-분석]] - Fred Brooks의 구분
  - [[AI Limitations]] - Essential Complexity 처리 불가
  - [[Conversation-LLMs and Building Abstractions]] - 추상화 발견 한계

### 5. 컨텍스트 윈도우 한계
- 컨텍스트 윈도우 길어질수록 정확도 저하
- 프로젝트 전체 맥락 파악 어려움
- **관련 문서**:
  - [[클로드코드 완벽 가이드]] - 200k 컨텍스트 윈도우 제한
  - [[Tmux Orchestrator]] - 계층화된 에이전트로 극복
  - [[Should-We-Revisit-XP-in-the-Age-of-AI]] - 컨텍스트 윈도우와 정확도 관계

### 6. 코드 품질 문제
- 보안 취약점 322% 증가
- 효율성 부족 (정확성 72%, 효율성 35%)
- 기술 부채 가속화 ("Vibe code is legacy code")
- **관련 문서**:
  - [[AI가 주니어를 빛나게 할 것이라 했지만, 왜 시니어만 더 강해졌을까]]
  - [[AI가 작성하는 유지보수 불가능한 코드 - COMPASS 벤치마크 연구]]
  - [[Vibe code is legacy code]]

### 7. 창의성과 예술적 한계 (테드 창의 통찰)
- AI는 "응용통계"일 뿐, 진정한 지능이 아님
- 예술은 무수한 선택의 결과물, AI는 평균값만 생성
- 의도(intention)와 주관적 경험 없음
- **관련 문서**:
  - [[테드 창 - AI에 대한 통찰과 예술의 미래]] - 핵심 철학적 관점

### 8. 인력/생태계 위협
- 주니어 개발자 채용 73.4% 감소
- 학습 기회 단절
- 제본스 역설 (효율화 → 더 많은 일 요구)
- **관련 문서**:
  - [[AI 시대의 엔지니어 성장에 대한 재고]]
  - [[AI is Making Junior Developers Extinct]]
  - [[인공지능이-우리-삶을-더-힘들게-만드는-진짜-이유]]

## 대응 전략 섹션
- TDD 필수 (테스트가 환각 방지 레일)
- Specification 중심 개발
- Augmented Coding (대체가 아닌 보조)
- 작은 단계, 피드백 루프 유지

## 기존 관련 MOC/문서
- [[AI-문제점-종합-분석]] - 가장 포괄적인 기존 분석
- [[AI-시대-주니어-개발자-생존-가이드-MOC]]
- [[AI-시대-신입-개발자의-생존-전략-MOC]]

## 구현 단계
1. 위 구조에 따라 MOC 문서 작성
2. 모든 관련 문서 링크 연결 ([[wikilink]] 형식)
3. hierarchical tags 추가
4. 000-SLIPBOX 폴더에 저장
