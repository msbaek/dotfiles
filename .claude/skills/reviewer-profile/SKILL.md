---
name: reviewer-profile
description: |
  plan, spec, code 등 작성 후 사용자에게 리뷰/피드백을 요청하기 직전에 호출.
  ~/git/aboutme/reviewer-profile-compact.md를 읽어 리뷰이(백명석)의 전문성 지도를 로드하고,
  ~/.claude/proficiency.md(행동 신호 기반 보강 지표)를 추가로 읽어 리뷰 깊이를 자동 보정한다.
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

## Step 1b: Proficiency 지표 읽기 (행동 신호 보강)

```bash
cat ~/.claude/proficiency.md 2>/dev/null || echo "PROFICIENCY_MISSING"
```

프로젝트별 파일도 확인:
```bash
# 현재 프로젝트 키 도출 (CWD basename 기반)
PROJECT_KEY=$(basename "$PWD" | tr ' /' '_-')
cat ~/.claude/projects/${PROJECT_KEY}/memory/proficiency.md 2>/dev/null || true
```

`PROFICIENCY_MISSING`이면 → compact.md 기반으로만 진행 (Step 2로).
파일 있으면 → 글로벌 + 프로젝트별 confirmed 표를 메모리에 로드.

**불일치 처리**: proficiency.md 점수와 compact.md 분류가 2밴드 이상 차이 날 때:
- confidence가 high/medium인 proficiency.md 쪽 우선
- 양쪽 모두 불확실하면 리뷰 끝에 "⚠ 시드 프로필과 불일치 — /proficiency-review 권장" 표기

## Step 2: 컨텍스트 분류

`$ARGUMENTS`로 전달된 컨텍스트 힌트(없으면 현재 작업물로 자동 판단):

| 힌트 | 주요 영역 |
|------|----------|
| `plan` / `spec` | 설계·아키텍처 리뷰 — 전문 영역 비중 높음 |
| `code` (Java/Spring) | 전문 영역 — 결론 중심 |
| `sql` | 복잡도에 따라 중간↔취약 전환 |
| `infra` / `aws` | 취약 영역 — 배경+예시 필수 |
| `react` / `js` / `ts` | 취약 영역 — 코드 예시 필수 |

## Step 3: Proficiency 보정 적용

Step 1b에서 로드한 proficiency.md의 영역별 밴드로 리뷰 파라미터를 결정.
해당 영역이 proficiency.md에 없으면 compact.md 분류(전문/중간/취약)로 폴백.

**confidence 보정**: confidence가 `low` 또는 `seed`이거나 `stale` 플래그이면
→ 현재 밴드에서 Competent 쪽으로 1밴드 당김 (예: Expert → Proficient로 취급).

**밴드 → 리뷰 3축 매핑**:

| 밴드 | 리뷰 단위 크기 | 설명 깊이 | 지적 우선순위 | 톤 |
|------|--------------|----------|--------------|-----|
| Expert | PR 전체 / 여러 파일 묶음 | 결론만, 패턴명만 | 설계·아키텍처 트레이드오프 | 동료 간 약식 |
| Proficient | 중간 단위 | 결론 + 트레이드오프 1줄 | 설계 + 주요 버그 | 간결 |
| Competent | 중간 단위 | 핵심 근거 포함 | 버그/보안 + 설계 | 표준 |
| Adv.Beginner | 파일/함수 단위 | 왜→어떻게→확인, 코드 예시 | 버그/보안 우선 + 개념 보강 | 교육적 |
| Novice | 변경 1개씩 | 배경 개념부터 단계별, 예시 필수 | 기초 오류 + 안전성 | 멘토링 |

### 전문 영역 (Expert/Proficient 밴드)
- 패턴·원칙 이름만 언급, 배경 설명 생략
- "이 부분 SRP 위반입니다 — OrderService가 결제 로직도 품고 있습니다" 형태
- 질문은 설계 트레이드오프 중심

### 중간 영역 (Competent 밴드)
- 기술 용어 그대로, 트레이드오프만 1줄 추가
- "이 인덱스는 read 성능을 개선하지만 write 부하가 생깁니다" 형태

### 취약 영역 (Adv.Beginner/Novice 밴드)
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

📊 <주요 영역> <밴드>(conf:<등급>) 기준 보정 — 너무 얕음/깊음? /proficiency-review
```

마지막 `📊` 줄은 항상 1줄 표기. proficiency.md 없거나 해당 영역 미등록이면:
`📊 compact.md 시드 기준 (proficiency.md 미사용) — /proficiency-init으로 활성화 가능`
