---
name: reviewer-profile
description: |
  plan, spec, code 등 작성 후 사용자에게 리뷰/피드백을 요청하기 직전에 호출.
  ~/git/aboutme/reviewer-profile-compact.md를 읽어 리뷰이(백명석)의 전문성 지도를 로드하고,
  설명 깊이·용어 수준·예시 필요 여부를 자동으로 조정한다.
  "리뷰해줘", "피드백 부탁해", "어떻게 생각해" 등 사용자 판단을 구하는 시점에 자동 적용.
argument-hint: "[context: plan|spec|code|sql|infra]"
---

# Reviewer Profile Loader

사용자에게 리뷰·피드백을 요청하기 전, 이 스킬로 리뷰이의 전문성 지도를 로드한다.

## Step 1: 프로파일 읽기

```bash
cat ~/git/aboutme/reviewer-profile-compact.md
```

파일이 없으면:
```bash
cat ~/git/aboutme/reviewer-profile.md
```

둘 다 없으면 → 이하 단계 skip, 일반 리뷰 요청으로 진행.

## Step 2: 컨텍스트 분류

`$ARGUMENTS`로 전달된 컨텍스트 힌트(없으면 현재 작업물로 자동 판단):

| 힌트 | 주요 영역 |
|------|----------|
| `plan` / `spec` | 설계·아키텍처 리뷰 — 전문 영역 비중 높음 |
| `code` (Java/Spring) | 전문 영역 — 결론 중심 |
| `sql` | 복잡도에 따라 중간↔취약 전환 |
| `infra` / `aws` | 취약 영역 — 배경+예시 필수 |
| `react` / `js` / `ts` | 취약 영역 — 코드 예시 필수 |

## Step 3: 리뷰 요청 메시지 조정 원칙

프로파일 로드 후 리뷰 요청 시 아래 원칙을 즉시 적용한다.

### 전문 영역 (Java/OOP/TDD/Spring/DDD/MSA/Kafka/Refactoring)
- 패턴·원칙 이름만 언급, 배경 설명 생략
- "이 부분 SRP 위반입니다 — OrderService가 결제 로직도 품고 있습니다" 형태
- 질문은 설계 트레이드오프 중심

### 중간 영역 (MySQL 기본 SQL / Docker·K8s 기초 / CI/CD)
- 기술 용어 그대로, 트레이드오프만 1줄 추가
- "이 인덱스는 read 성능을 개선하지만 write 부하가 생깁니다" 형태

### 취약 영역 (React/JS/TS / 복잡한 SQL / AWS 고급 / Databricks·Spark)
- 왜 문제인지 배경 1-2줄
- 구체적 코드/설정 예시
- 확인 방법까지 안내
- 사내 도메인 테이블이 핵심이면 "팀원 확인 권고"로 마무리

### 공통 규칙
- 우선순위: 버그/보안 > 설계 > 스타일
- 핵심 피드백 3개 이내로 집약
- 항상 "테스트가 있는가" 먼저 확인
- 한국어 응답, 코드·변수명은 영어

## Step 4: 리뷰 요청 출력

아래 형식으로 리뷰 요청을 제시한다:

```
## 리뷰 요청 — [작업물 제목]

**리뷰 포인트** (우선순위 순):
1. [가장 중요한 포인트 — 영역에 맞는 깊이로]
2. [두 번째 포인트]
3. [세 번째 포인트 (있는 경우)]

**특히 확인 부탁드릴 부분**: [취약 영역이면 구체적 질문, 전문 영역이면 짧게]

> 피드백이나 방향 수정이 있으시면 알려주세요.
```
