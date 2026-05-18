---
name: mutate4java
description: |
  Use when the user asks to run mutation testing on a Java file, check test quality by mutating code,
  find surviving mutants, kill mutants with tests, or says "뮤테이션 테스트", "mutate", "뮤턴트 잡기",
  "살아남은 뮤턴트", "테스트가 뮤턴트를 잡는지 확인", or wants to verify that tests actually catch bugs.
  Java Maven 프로젝트의 단일 `.java` 파일에 대해 mutation testing을 실행하는 도구.
---

# mutate4java Skill

Java Maven 프로젝트의 단일 `.java` 소스 파일에 mutation testing을 실행하고, 살아남은 뮤턴트를 죽이는 테스트를 제안·작성한다.

## 도구 위치

```bash
JAR=~/git/uncle-bob/mutate4java/target/mutate4java-0.1.0-SNAPSHOT.jar
```

JAR이 없으면 먼저 빌드:

```bash
cd ~/git/uncle-bob/mutate4java && mvn package -DskipTests -q
```

## 기본 실행 방법

**대상 파일이 속한 Maven 모듈 루트에서 실행해야 한다** (가장 가까운 `pom.xml` 탐색 기준).

```bash
# 표준 실행 (커버리지 갱신 + 전체 뮤테이션)
java -jar $JAR src/main/java/com/example/Foo.java

# 가볍게 먼저 스캔 (테스트 실행 없음)
java -jar $JAR src/main/java/com/example/Foo.java --scan

# 변경된 scope만 (반복 실행 시)
java -jar $JAR src/main/java/com/example/Foo.java --since-last-run

# 커버리지 재사용 (같은 모듈 내 다음 파일 분석 시)
java -jar $JAR src/main/java/com/example/Bar.java --reuse-coverage
```

## 워크플로우

### 1. 첫 실행 (신규 파일)

```bash
cd <module-root>
java -jar ~/git/uncle-bob/mutate4java/target/mutate4java-0.1.0-SNAPSHOT.jar \
  src/main/java/com/example/Foo.java --verbose
```

- 베이스라인 테스트 실행 + JaCoCo 커버리지 생성
- 커버된 뮤테이션 사이트만 실행
- 완료 후 파일 끝에 manifest 자동 기록

### 2. 반복 실행 (변경 후)

```bash
# 변경된 scope만 선택적으로 뮤테이션 (빠른 피드백)
java -jar $JAR src/main/java/com/example/Foo.java --since-last-run
```

manifest가 있으면 변경된 declaration scope만 재실행 → 대규모 파일에서도 빠름.

### 3. 배치 실행 (여러 파일)

```bash
# 첫 번째 파일: 커버리지 생성
java -jar $JAR src/main/java/com/example/A.java

# 이후 파일들: 커버리지 재사용
java -jar $JAR src/main/java/com/example/B.java --reuse-coverage
java -jar $JAR src/main/java/com/example/C.java --reuse-coverage
```

### 4. 살아남은 뮤턴트 처리 (핵심 워크플로우)

출력에 `SURVIVED`가 있으면:

1. 해당 라인의 원본 코드와 뮤테이션 내용 확인
2. 어떤 입력값/케이스에서 그 변화가 드러나는지 분석
3. `msbaek-tdd:tdd-red` skill로 그 케이스를 커버하는 테스트 작성
4. 테스트 통과 후 재실행해서 뮤턴트가 KILLED로 바뀌는지 확인

```text
# 살아남은 뮤턴트 예시
SURVIVED src/main/java/demo/Flag.java:9 replace == with !=
```
→ `line 9`의 `==` 조건이 `!=`으로 바뀌어도 기존 테스트가 감지 못함
→ `==`와 `!=`를 구분하는 경계값 테스트 케이스 추가 필요

## 출력 해석

| 결과 | 의미 | 액션 |
|------|------|------|
| `KILLED` | 테스트가 뮤턴트 잡음 ✅ | 없음 |
| `SURVIVED` | 테스트가 뮤턴트 못 잡음 ❌ | 새 테스트 작성 |
| `UNCOVERED` | 커버리지 미달 라인 — 실행 안 함 | 커버 테스트 추가 |
| `TIMEOUT` | 타임아웃 — killed 처리됨 | 없음 |

## 주요 옵션

| 옵션 | 용도 |
|------|------|
| `--scan` | 테스트 미실행, 뮤테이션 사이트만 목록 출력 |
| `--since-last-run` | 변경된 scope만 실행 (manifest 필요) |
| `--mutate-all` | manifest 무시하고 전체 실행 |
| `--reuse-coverage` | 기존 JaCoCo XML 재사용 |
| `--lines 12,18` | 특정 라인만 뮤테이션 |
| `--update-manifest` | 테스트 실행 없이 manifest만 갱신 |
| `--max-workers N` | 병렬 워커 수 제한 (기본: CPU/2) |
| `--verbose` | 워커별 진행 상황 실시간 출력 |
| `--test-command CMD` | 기본 `mvn test` 대신 커스텀 명령 사용 |

## Exit Codes

| Code | 의미 |
|------|------|
| 0 | 성공 (모든 뮤턴트 killed, 또는 실행할 뮤턴트 없음) |
| 1 | CLI 사용 오류 |
| 2 | 베이스라인 테스트 실패 |
| 3 | 살아남은 뮤턴트 있음 |

## 지원 뮤테이션 목록

- boolean 리터럴: `true` ↔ `false`
- 비교 연산자: `==`, `!=`, `<`, `<=`, `>`, `>=`
- 산술 연산자: `+` ↔ `-`, `*` ↔ `/`
- 논리 연산자: `&&` ↔ `||`
- 단항 연산자: `!expr` → `expr`, `-expr` → `expr`
- 정수 상수: `0` ↔ `1`
- 참조 rvalue → `null`

## 주의사항

- 파일 하나씩만 대상으로 함 (디렉토리 전체 지원 안 함)
- Maven 프로젝트 전용
- 테스트 소스는 뮤테이션 대상 아님
- `--scan`과 `--since-last-run` 조합 불가 (충돌 옵션 많음 — README 참조)

## 관련 스킬

- 살아남은 뮤턴트 → 테스트 작성: `msbaek-tdd:tdd-red` → `msbaek-tdd:tdd-green`
- 코드 복잡도 분석: `crap4java`
