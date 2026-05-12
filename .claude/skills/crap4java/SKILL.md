---
name: crap4java
description: |
  This skill should be used when the user asks to "CRAP 분석", "crap4java 실행", "메서드 복잡도 분석",
  "코드 품질 게이트 확인", "CRAP score 확인", "변경된 파일 CRAP 분석", "cyclomatic complexity + coverage 분석",
  "crap 점수가 8 이상인 메서드 찾아줘", or mentions CRAP metric, JaCoCo coverage + complexity 조합 분석.
  Java Maven 프로젝트의 메서드별 CRAP(Change Risk Anti-Patterns) 점수를 측정하여 리팩터링 우선순위를 제시.
---

# crap4java Skill

Java Maven 프로젝트의 메서드별 CRAP 점수를 측정·보고하고, 임계값(8.0) 초과 시 리팩터링 우선순위를 제시한다.

## CRAP 공식

```
CRAP = CC² × (1 - coverage)³ + CC
```

- `CC`: 메서드 cyclomatic complexity (분기 수 + 1)
- `coverage`: JaCoCo `INSTRUCTION` 카운터 기준 메서드 커버리지 (0.0 ~ 1.0)
- **임계값**: 8.0 초과 시 exit code 2 (품질 게이트 실패)

커버리지가 높을수록 CRAP이 낮아짐 → 테스트로 리스크를 낮추거나, CC를 줄여 리팩터링하거나, 둘 다.

## 도구 위치

```
JAR=/Users/msbaek/git/uncle-bob/crap4java/target/crap4java-0.1.0-SNAPSHOT.jar
```

## 실행 방법

**분석 대상 프로젝트 루트에서 실행해야 한다** (JaCoCo XML과 pom.xml 탐색 기준).

```bash
# 프로젝트 전체 분석
cd <project-root>
java -jar $JAR

# Git 변경 파일만 분석 (PR 리뷰 / 커밋 전 체크에 적합)
java -jar $JAR --changed

# 특정 파일 분석
java -jar $JAR src/main/java/com/example/Foo.java

# 특정 디렉토리(src/ 하위 전체)
java -jar $JAR module-a module-b

# 도움말
java -jar $JAR --help
```

## 워크플로우

### 1. 일반 분석 (전체 프로젝트)

```bash
cd <project-root>
java -jar /Users/msbaek/git/uncle-bob/crap4java/target/crap4java-0.1.0-SNAPSHOT.jar
```

내부 동작:
1. 스테일 커버리지 삭제 (`target/site/jacoco/`, `target/jacoco.exec`)
2. `mvn jacoco:prepare-agent test jacoco:report` 실행
3. `target/site/jacoco/jacoco.xml` 파싱
4. JDK compiler tree API로 Java 메서드 파싱 + CC 계산
5. 결과를 CRAP 내림차순 출력

### 2. 변경 파일만 (빠른 피드백)

```bash
cd <project-root>
java -jar /Users/msbaek/git/uncle-bob/crap4java/target/crap4java-0.1.0-SNAPSHOT.jar --changed
```

`git status --porcelain`으로 수정·추가·미추적 Java 파일만 대상.
커밋 전 빠른 품질 게이트로 활용.

### 3. 결과 해석

| CRAP 범위 | 의미 | 권장 액션 |
|-----------|------|-----------|
| 1 ~ 5     | 양호 | 유지 |
| 6 ~ 8     | 주의 | 테스트 보강 고려 |
| > 8       | 위험 | 리팩터링 or 테스트 우선 추가 |
| N/A       | 커버리지 없음 | 테스트 작성 우선 |

## Exit Codes

| Code | 의미 |
|------|------|
| 0    | 성공 (임계값 이내 또는 파일 없음) |
| 1    | CLI 사용 오류 |
| 2    | CRAP 임계값 초과 (최대값 > 8.0) |

## 리팩터링 우선순위 제안

분석 후 CRAP > 8 메서드가 있으면:

1. **커버리지 N/A 메서드** → 테스트 먼저 작성 (안전망 확보)
2. **CC 높고 커버리지 낮은 메서드** → 테스트 추가 후 리팩터링
3. **CC 높고 커버리지 충분한 메서드** → 즉시 리팩터링 가능 (테스트가 보호)

CC를 낮추는 방법: Extract Method, Replace Conditional with Polymorphism, Decompose Conditional 등.
→ 상세 리팩터링은 `msbaek-tdd` skill 참조.

## 주의사항

- Maven 프로젝트 전용 (Gradle 미지원)
- 생성자·추상 메서드·익명 클래스 메서드는 분석 제외
- JaCoCo XML 없으면 커버리지 N/A (Maven 빌드 실패 시 발생)
- 멀티모듈 Maven 프로젝트: 각 파일의 최근접 `pom.xml`을 모듈 루트로 사용

## 추가 참고

자세한 CRAP 공식·CLI 스펙·모듈 그룹핑 규칙은 `references/spec.md` 참조.
