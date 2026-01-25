# MoC 생성 계획: TDD와 과학적 방법론의 반증가능성

## 목표
과학적 접근법(가정-실험-증명)과 TDD의 반증가능성(falsifiability)에 대해 언급한 vault 문서들의 Map of Content(MoC) 생성

---

## 핵심 문서 목록 (확인 완료)

### 1. 반증가능성 (Falsifiability) 핵심
| 문서 | 핵심 내용 |
|------|----------|
| `003-RESOURCES/TDD/Falsifiable.md` | Karl Popper의 반증가능성 개념, TDD와의 철학적 연결, 실패하는 테스트 = 반증가능성 입증 |
| `003-RESOURCES/TDD/TDD의 과학적 접근법.md` | 이중 가설 구조 (메타 가설 + 명세 가설), Dijkstra 인용, 반증력 개념 |

### 2. 과학적 방법론과 TDD
| 문서 | 핵심 내용 |
|------|----------|
| `003-RESOURCES/TDD/소프트웨어 공학의 3가지 메타포.md` | Characterize-Hypothesize-Predict-Experiment 단계, Arrange-Act-Assert 매핑 |
| `000-SLIPBOX/TDD와 과학적 방법론, AI 코딩의 관계.md` | 과학적 방법론 5단계와 TDD 대응, AI 시대의 Test-Driven Generation |

### 3. 실증적 검증
| 문서 | 핵심 내용 |
|------|----------|
| `003-RESOURCES/TDD/Empirical-Characterization-Testing.md` | Dijkstra 명언, Mark Seemann의 Sabotage 방법, 동어반복적 어설션 경고 |

### 4. 연결된 추가 문서
- `[[동어반복적 어설션]]` - 의미 없는 테스트 패턴
- `[[Saboteur Assertion]]` - 테스트 반증력 검증 기법

---

## MoC 생성 계획

### 파일 위치
`003-RESOURCES/TDD/MOC-TDD와 반증가능성.md`

### MoC 구조

```markdown
---
id: MOC-TDD와 반증가능성
tags:
  - moc/tdd
  - tdd/philosophy/falsifiability
  - methodology/scientific-method
created_at: 2026-01-16
---

# TDD와 과학적 방법론: 반증가능성 MOC

> "Testing shows the presence, not the absence of bugs." - Dijkstra

## 🎯 핵심 개념

### 반증가능성 (Falsifiability)
- [[Falsifiable]] - Karl Popper의 반증가능성 원칙과 TDD 연결
  - 실패하는 테스트 = 반증가능성의 실질적 증명
  - "틀릴 수 있음"을 코드 수준에서 명확히 드러냄

### 이중 가설 구조
- [[TDD의 과학적 접근법]] - Red-Green 단계의 과학적 해석
  - 1단계 (Red): 테스트 반증력 검증 (메타 가설)
  - 2단계 (Green): 명세 충족 가설의 경험적 보강

---

## 🔬 과학적 방법론과 TDD

### 방법론 대응
- [[소프트웨어 공학의 3가지 메타포]] - 공학적 접근법
  - Characterize → Hypothesize → Predict → Experiment
  - Arrange → Act → Assert

### 현대적 적용
- [[TDD와 과학적 방법론, AI 코딩의 관계]]
  - 가설 설정 → 테스트 작성
  - 실험 설계 → Given-When-Then
  - 결과 분석 → 리팩터링

---

## 📖 실증적 검증 기법

### 테스트의 반증력 확보
- [[Empirical-Characterization-Testing]] - Mark Seemann의 접근법
  - Sabotage 방법: SUT를 의도적으로 방해하여 각 어설션 검증
  - 레거시 코드에 특성화 테스트 추가하기

### 관련 개념
- [[동어반복적 어설션]] - 반증력 없는 테스트의 위험
- [[Saboteur Assertion]] - 테스트 유효성 검증 기법

---

## 💡 핵심 통찰

| 과학적 방법 | TDD | 의미 |
|------------|-----|------|
| 가설은 반증가능해야 | 테스트는 실패할 수 있어야 | 틀림을 증명할 기준 필요 |
| 실험으로 검증 | 테스트 실행 | 경험적 증거 수집 |
| 반증 시도 | Red 단계 | 가설의 유효성 확인 |
| 잠정적 신뢰 | Green 단계 | 아직 반증되지 않음 |

---

## 🔗 관련 문서
- [[TDD의 본질]]
- [[TDD and Generative AI – A Perfect Pairing]]
```

---

## 실행 단계

1. **MoC 파일 생성**
   - 위치: `003-RESOURCES/TDD/MOC-TDD와 반증가능성.md`
   - 위 구조대로 작성

2. **검증**
   - 각 wiki-link 유효성 확인
   - `python -m src related --file "MOC-TDD와 반증가능성.md"` 실행

---

## Uncertainty Map

| 영역 | 확신도 | 비고 |
|------|--------|------|
| 핵심 문서 식별 | ⭐⭐⭐⭐⭐ | vault-intelligence 검색으로 확인 |
| MoC 구조 설계 | ⭐⭐⭐⭐ | 기존 vault 패턴 참조 |
| 파일 저장 위치 | ⭐⭐⭐ | 사용자 확인 필요할 수 있음 |
