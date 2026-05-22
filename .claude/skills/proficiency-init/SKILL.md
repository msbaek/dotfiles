---
name: proficiency-init
description: |
  reviewer-profile-compact.md를 시드로 ~/.claude/proficiency.md(글로벌 기술 영역)를 최초 생성.
  --reseed 옵션으로 compact.md 변경 사항을 명시적으로 재반영.
  이후 숙련도의 진실 원천은 proficiency.md 하나뿐 — compact.md는 읽기 전용 시드로 동결.
argument-hint: "[--reseed]"
---

# Proficiency Init

`reviewer-profile-compact.md`를 시드로 글로벌 숙련도 지표 파일을 생성한다.

## Step 1: 조건 확인

```bash
ls ~/.claude/proficiency.md 2>/dev/null && echo "EXISTS" || echo "NOT_FOUND"
```

- `NOT_FOUND` → Step 2로 진행
- `EXISTS` + `$ARGUMENTS`에 `--reseed` 없음 → 중단하고 사용자에게 알림:
  > `~/.claude/proficiency.md` 이미 존재합니다. 재시드하려면 `--reseed` 옵션을 사용하세요.
- `EXISTS` + `--reseed` 있음 → Step 2로 진행 (덮어씀)

## Step 2: compact.md 읽기

```bash
cat ~/git/aboutme/reviewer-profile-compact.md
```

파일이 없으면:
```bash
cat ~/git/aboutme/reviewer-profile.md
```

둘 다 없으면 → "시드 파일을 찾을 수 없습니다." 안내 후 중단.

## Step 3: 영역 분류 및 점수 할당

compact.md에서 영역을 추출해 아래 규칙으로 초기 점수 할당:

| compact.md 분류 | 초기 점수 | 밴드 |
|----------------|----------|------|
| 전문 (결론만) | 85 | Expert |
| 중간 (트레이드오프만) | 55 | Competent |
| 취약 (배경+예시 필수) | 25 | Adv.Beginner |

모든 행의 confidence = `seed` (low 취급), n = 0.

**영역 → scope 매핑 규칙**:
- 범용 기술 용어(java-spring, react-hooks, complex-sql, ddd, kafka, docker-k8s 등) → `technical`
- 사내 고유명사 또는 특정 레포 한정 지식 → `domain`
- 초기화 시점에서 모두 `technical`로 분류하고, domain 영역은 프로젝트별 별도 파일에서 관리

## Step 4: Domain Lexicon 초기값 생성

compact.md 영역 이름으로 기본 키워드 세트를 생성:
- `java-spring`: Java, Spring Boot, Bean, JPA, Repository, Service, Controller, @, 애노테이션
- `react-hooks`: useEffect, useState, hook, 렌더링, 의존성 배열, memo, useCallback, useMemo
- `complex-sql`: JOIN, CTE, 윈도우 함수, WINDOW, GROUP BY, 서브쿼리, 실행 계획, EXPLAIN
- `ddd`: 애그리거트, 도메인 이벤트, 바운디드 컨텍스트, 엔티티, 값 객체, 리포지토리
- `kafka`: 토픽, 파티션, 컨슈머 그룹, 오프셋, 프로듀서, 스트림
- `docker-k8s`: Dockerfile, Pod, Deployment, Service, ConfigMap, namespace, kubectl
- 기타 영역은 영역 이름 자체를 키워드로 등록

## Step 5: proficiency.md 파일 작성

`~/.claude/proficiency.md`에 아래 스키마로 작성:

```markdown
---
name: proficiency
description: 영역별 숙련도 지표 — reviewer-profile 보강 입력 (scope:technical 글로벌)
metadata:
  node_type: memory
  type: proficiency-metric
  schema_version: 1
  seeded_from: reviewer-profile-compact.md
  seeded_at: <YYYY-MM-DD>
  last_auto_update: <YYYY-MM-DD>
  last_confirmed: <YYYY-MM-DD>
---

# 영역별 숙련도 지표 (글로벌 — scope:technical)
> 자동 수집 → `/proficiency-review`로 확정. `locked: true` 행은 자동 갱신 제외.
> 시드 출처: `reviewer-profile-compact.md` (초기화 후 compact.md는 읽기 전용 동결)

## 확정 지표 (confirmed)

| 영역 | scope | 점수 | 밴드 | confidence | n | 최근 갱신 | locked | 비고 |
|------|-------|-----|------|-----------|---|----------|--------|------|
<compact.md 전문 영역들 — 점수 85, Expert, seed, 0>
<compact.md 중간 영역들 — 점수 55, Competent, seed, 0>
<compact.md 취약 영역들 — 점수 25, Adv.Beginner, seed, 0>

## 후보 영역 (자동 발견, 미확정)
| 후보 영역 | scope(추정) | 키워드 | 관측 신호 요약 | n |
|----------|------------|--------|---------------|---|

## 변경 로그 (pending — 다음 review에서 검토)
_비어 있음 — /proficiency-review 실행 시 채워짐_

## Domain Lexicon (사용자 편집 가능)
| 영역 | 키워드 |
|------|--------|
| java-spring | Java, Spring Boot, Bean, JPA, Repository, Service, Controller, 애노테이션 |
| react-hooks | useEffect, useState, hook, 렌더링, 의존성 배열, memo, useCallback |
| complex-sql | JOIN, CTE, 윈도우 함수, GROUP BY, 서브쿼리, 실행 계획, EXPLAIN |
| ddd | 애그리거트, 도메인 이벤트, 바운디드 컨텍스트, 엔티티, 값 객체 |
| kafka | 토픽, 파티션, 컨슈머 그룹, 오프셋, 프로듀서, 스트림 |
| docker-k8s | Dockerfile, Pod, Deployment, Service, ConfigMap, kubectl |
```

## Step 6: 완료 보고

생성 완료 후:
```
✅ ~/.claude/proficiency.md 생성 완료
- 전문 영역: N개 (점수 85, Expert, confidence:seed)
- 중간 영역: N개 (점수 55, Competent, confidence:seed)
- 취약 영역: N개 (점수 25, Adv.Beginner, confidence:seed)

다음 단계:
1. /proficiency-review — 세션 큐 분석 후 지표 갱신 제안
2. reviewer-profile skill — proficiency.md를 보강 입력으로 자동 읽음
```
