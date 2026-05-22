---
name: proficiency
description: 영역별 숙련도 지표 — reviewer-profile 보강 입력 (scope:technical 글로벌)
metadata:
  node_type: memory
  type: proficiency-metric
  schema_version: 1
  seeded_from: reviewer-profile-compact.md
  seeded_at: 2026-05-22
  last_auto_update: 2026-05-22
  last_confirmed: 2026-05-22
---

# 영역별 숙련도 지표 (글로벌 — scope:technical)
> 자동 수집 → `/proficiency-review`로 확정. `locked: true` 행은 자동 갱신 제외.
> 시드 출처: `reviewer-profile-compact.md` (초기화 후 compact.md는 읽기 전용 동결)

## 확정 지표 (confirmed)

| 영역 | scope | 점수 | 밴드 | confidence | n | 최근 갱신 | locked | 비고 |
|------|-------|-----|------|-----------|---|----------|--------|------|
| java-oop | technical | 85 | Expert | seed | 0 | 2026-05-22 | false | Java 30년+, OOP/SOLID/GoF |
| tdd-junit | technical | 85 | Expert | seed | 0 | 2026-05-22 | false | TDD/JUnit/Mockito |
| java-spring | technical | 85 | Expert | seed | 0 | 2026-05-22 | false | Spring Boot·Cloud·Security·JPA |
| ddd | technical | 85 | Expert | seed | 0 | 2026-05-22 | false | DDD 전술+전략 |
| kafka-eda | technical | 85 | Expert | seed | 0 | 2026-05-22 | false | MSA/EDA/Kafka |
| refactoring | technical | 85 | Expert | seed | 0 | 2026-05-22 | false | Fowler 전편 |
| clean-code | technical | 85 | Expert | seed | 0 | 2026-05-22 | false | Clean Code |
| mysql-sql | technical | 55 | Competent | seed | 0 | 2026-05-22 | false | 단일·이중 조인, 인덱스 방향 |
| docker-k8s | technical | 55 | Competent | seed | 0 | 2026-05-22 | false | Docker/K8s 기초 |
| cicd | technical | 55 | Competent | seed | 0 | 2026-05-22 | false | GitHub Actions/ArgoCD |
| react-hooks | technical | 25 | Adv.Beginner | seed | 0 | 2026-05-22 | false | React/JS/TS — Hook 동작·렌더링 최적화 |
| complex-sql | technical | 25 | Adv.Beginner | seed | 0 | 2026-05-22 | false | 3-way JOIN·윈도우 함수·CTE·실행 계획 |
| aws-advanced | technical | 25 | Adv.Beginner | seed | 0 | 2026-05-22 | false | VPC·IAM·Lambda·IaC |
| databricks-spark | technical | 25 | Adv.Beginner | seed | 0 | 2026-05-22 | false | Shuffle·Delta Lake·Streaming |

> 참고: 사내 도메인 테이블 지식(scope:domain)은 각 프로젝트별 `memory/proficiency.md`에서 관리.

## 후보 영역 (자동 발견, 미확정)
| 후보 영역 | scope(추정) | 키워드 | 관측 신호 요약 | n |
|----------|------------|--------|---------------|---|

## 변경 로그 (pending — 다음 review에서 검토)
_비어 있음 — /proficiency-review 실행 시 채워짐_

## Negative Examples (재제안 억제)
_비어 있음_

## Domain Lexicon (사용자 편집 가능)
| 영역 | 키워드 |
|------|--------|
| java-oop | OOP, SOLID, GoF, 디자인 패턴, 인터페이스, 추상 클래스, 다형성, 상속, 캡슐화 |
| java-spring | Java, Spring Boot, Bean, JPA, Repository, Service, Controller, 애노테이션, @, Hibernate |
| tdd-junit | TDD, Red-Green-Refactor, JUnit, Mockito, 테스트, 단위 테스트, mock, stub |
| ddd | 애그리거트, 도메인 이벤트, 바운디드 컨텍스트, 엔티티, 값 객체, 리포지토리, 도메인 서비스 |
| kafka-eda | Kafka, 토픽, 파티션, 컨슈머 그룹, 오프셋, 프로듀서, 스트림, MSA, EDA, 이벤트 |
| refactoring | 리팩토링, Extract Method, Rename, Move, 코드 스멜, 기술 부채 |
| clean-code | Clean Code, 명명, 함수, 주석, 가독성 |
| mysql-sql | MySQL, SQL, JOIN, INDEX, 인덱스, 쿼리, SELECT, GROUP BY |
| docker-k8s | Docker, Kubernetes, Pod, Deployment, Service, ConfigMap, kubectl, container |
| cicd | GitHub Actions, ArgoCD, CI/CD, 파이프라인, 배포, workflow |
| react-hooks | useEffect, useState, hook, 렌더링, 의존성 배열, memo, useCallback, useMemo, React |
| complex-sql | CTE, 윈도우 함수, WINDOW, 3-way JOIN, 서브쿼리, 실행 계획, EXPLAIN, 파티션 |
| aws-advanced | AWS, VPC, IAM, Lambda, IaC, CloudFormation, Terraform, ARN, 보안 그룹 |
| databricks-spark | Databricks, Spark, Delta Lake, Streaming, Shuffle, checkpoint, watermark |
