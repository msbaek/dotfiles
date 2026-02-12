---
description: "반복적 개선 패스로 레이어별 노이즈 제거. 리팩토링/품질 개선 시 호출."
---

# Refinement Loop - 반복적 정제

출처: [Augmented Coding Patterns](https://lexler.github.io/augmented-coding-patterns/patterns/refinement-loop/)

## 문제

AI의 첫 시도는 최적이 아니다. 한 번의 패스로는 충분하지 않고, 표면적 문제가 깊은 문제를 가린다.

## 핵심 원칙

> 각 반복이 노이즈 한 레이어를 벗겨내면, 다음 레이어의 개선점이 보인다.

## 프로세스

### 1단계: 개선 목표 정의

한 가지 구체적 목표만 설정:
- 단순화(simplify)
- 품질 개선(improve quality)
- 추출(distill)
- 깊은 이해(understand deeper)
- 중복 제거(remove duplication)

### 2단계: 한 번의 포커싱된 패스

- 가장 단순하게 보이는 개선 하나에 집중
- 변경 후 커밋 (테스트 통과 확인)
- 외부 아티팩트(파일/커밋)로 반복을 실체화

### 3단계: 반복

- 이전 패스 위에 다음 패스 수행
- 눈에 띄는 개선이 없을 때까지 반복
- 각 패스에서 process 파일을 todo 리스트로 활용하여 AI 추적 유지

### 4단계: 종료 조건

- 더 이상 눈에 띄는 개선이 없음
- 또는 3-5회 패스 후 수확 체감

## 적용 예시

Llewellyn Falco의 리팩토링 프로세스:
1. 가장 단순한 리팩토링에 집중
2. 테스트 통과 후 커밋
3. process 파일로 AI 방향 유지
4. 단순한 수정이 이전에 숨겨진 개선점을 드러냄

## 관련 패턴

- **유사**: Feedback Flip (평가 모드 전환의 일반화)
- **연관**: `/tdd:tidying` (Tidying 리팩토링과 결합 시 효과적)
- **연관**: `/tdd:composed-method` (composed method 적용 시 refinement loop 활용)
