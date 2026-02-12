---
description: "대화 방향 전환 - AI에게 제안/질문 역할 위임. 의사결정 막힐 때 호출."
---

# Reverse Direction - 대화 방향 전환

출처: [Augmented Coding Patterns](https://lexler.github.io/augmented-coding-patterns/patterns/reverse-direction/)

## 문제

일단 지시(monologue) 패턴이 확립되면 그 방향이 지속된다. 계속 명령만 내리거나, 계속 질문만 받거나. 이 관성 때문에 대화를 전환하면 더 나은 결과가 나올 기회를 놓친다.

## 핵심 원칙

> AI를 주문 받는 사람이 아닌 협업 파트너로 활용한다. AI의 강점(폭과 속도)과 사람의 강점(빠른 판단과 선호 명확화)을 결합한다.

## 언제 전환하는가

| 현재 상황 | 전환 프롬프트 |
|-----------|-------------|
| AI가 결정을 요청 | "네가 생각하기에 뭐가 더 나을까?" |
| 설명하다 막힘 | "무슨 질문이 있어?" |
| 혼자 결정 중 | "접근법 몇 가지 보여줘" |
| 이름/변수 고민 | "좋은 이름 몇 개 제안해봐" |
| 구조 고민 | "이 코드를 어떻게 구조화하겠어?" |

## 프로세스

1. AI의 질문에 바로 대답하려는 순간 **멈춤**
2. "네 생각은?" 또는 "제안해봐"로 방향 전환
3. AI가 여러 옵션을 제시하면 → 자신의 선호가 자연스럽게 드러남
4. 선호 기반으로 추가 아이디어 발전

## 예시

```
AI: 파일 이름을 뭘로 하시겠어요?
나: 좋은 이름 몇 개 제안해볼래?
AI: 1) data-processor.ts  2) event-handler.ts  3) message-pipeline.ts
나: 2번이 제일 의도에 가깝네. 근데 "handler"보다 "listener"가 나을 것 같아.
→ AI: event-listener.ts 로 하겠습니다.
```

## 관련 패턴

- **해결**: Answer Injection 안티패턴
- **연관**: Active Partner (CLAUDE.md), `/augmented:cast-wide`
