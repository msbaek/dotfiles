# /mutate4java 스킬 사용 가이드

Java Maven 프로젝트에서 **뮤테이션 테스트**를 실행하고, 살아남은 뮤턴트를 잡는 테스트를 작성하도록
Claude Code가 도와주는 스킬이다.

---

## 뮤테이션 테스트란?

> "코드를 일부러 잘못 바꿔봤을 때 테스트가 실패하면 → 좋은 테스트"

도구가 소스 코드를 살짝 변형(뮤테이션)한 뒤 테스트를 돌린다.

```java
// 원본
if (age > 18) { ... }

// 뮤테이션 (자동 생성)
if (age >= 18) { ... }   ← 이걸 테스트가 잡아야 한다
```

테스트가 뮤턴트를 **잡으면 KILLED**, **못 잡으면 SURVIVED**.
SURVIVED가 많을수록 테스트가 허술하다는 뜻이다.

---

## 사전 준비

### JAR 빌드 (최초 1회)

```bash
cd ~/git/uncle-bob/mutate4java
mvn package -DskipTests -q
```

이후에는 JAR이 유지되므로 다시 빌드할 필요 없다.

### 스킬 호출

Claude Code 프롬프트에서:

```
/mutate4java
```

스킬이 로드된 뒤 자연어로 요청하거나, 아래 예제를 그대로 붙여 넣으면 된다.

---

## 빠른 시작: 첫 번째 뮤테이션 테스트

### 1단계 — 대상 파일 지정

```
"src/main/java/com/example/Calculator.java 뮤테이션 테스트 해줘"
```

Claude가 내부적으로 실행하는 명령:

```bash
cd <pom.xml이 있는 모듈 루트>
java -jar ~/git/uncle-bob/mutate4java/target/mutate4java-0.1.0-SNAPSHOT.jar \
  src/main/java/com/example/Calculator.java --verbose
```

### 2단계 — 출력 읽기

```
Baseline tests passed in 2 341 ms.
Total mutation sites : 8
Covered mutation sites : 6
Uncovered mutation sites : 2

KILLED    Calculator.java:12  replace + with -          (1 823 ms)
KILLED    Calculator.java:18  replace == with !=        (1 901 ms)
SURVIVED  Calculator.java:25  replace > with >=
UNCOVERED Calculator.java:31  replace true with false

Summary: 5 killed, 1 survived, 6 total.
```

| 결과 | 의미 | 할 일 |
|------|------|--------|
| `KILLED` | 테스트가 뮤턴트를 잡음 ✅ | 없음 |
| `SURVIVED` | 테스트가 뮤턴트를 놓침 ❌ | 테스트 추가 |
| `UNCOVERED` | 커버리지 없어서 실행도 안 함 | 커버 테스트 추가 |
| `TIMEOUT` | 타임아웃 → killed로 처리 | 없음 |

### 3단계 — 살아남은 뮤턴트 잡기

```
"살아남은 뮤턴트를 잡는 테스트 작성해줘"
```

Claude가 코드를 분석해서:

```java
// Calculator.java:25 원본
if (result > 0) { return result; }

// 뮤테이션: > 를 >= 로 바꿈
// → result == 0 일 때 동작이 달라짐 → 이 케이스 테스트가 없었음
```

테스트를 제안한다:

```java
@Test
void compute_결과가_0일때_양수_처리를_하지_않는다() {
    // result == 0 → > 0 은 false, >= 0 은 true → 동작 차이 발생
    assertThat(calculator.compute(0, 5)).isEqualTo(0);
}
```

---

## 시나리오별 예제

### 시나리오 A — 뮤테이션 사이트만 먼저 훑기 (테스트 실행 없음)

테스트가 느려서 전체 실행 전에 어디가 변형되는지 보고 싶을 때.

```
"Calculator.java 뮤테이션 사이트만 보여줘, 테스트는 안 돌려도 돼"
```

내부 명령:

```bash
java -jar $JAR src/main/java/com/example/Calculator.java --scan
```

출력 예시:

```
Scan: 8 mutation sites in Calculator.java
  Calculator.java:12  replace + with -
  Calculator.java:18  replace == with !=
* Calculator.java:25  replace > with >=      ← 변경된 scope
  Calculator.java:31  replace true with false
  ...
* = differs from manifest (changed since last run)
```

---

### 시나리오 B — 코드 수정 후 변경된 메서드만 빠르게 재검사

매번 전체를 돌리면 느리다. 수정한 메서드만 골라서 실행한다.

```
"Calculator.java 방금 add() 수정했는데 변경된 부분만 다시 뮤테이션 해줘"
```

내부 명령:

```bash
java -jar $JAR src/main/java/com/example/Calculator.java --since-last-run
```

이전 실행 결과가 소스 파일 끝에 manifest로 남아 있어 달라진 scope만 골라 실행한다.
파일이 크더라도 수 초 만에 끝난다.

---

### 시나리오 C — 같은 모듈 여러 파일 배치 실행

커버리지 측정은 한 번만 하고 나머지 파일은 재사용해서 시간을 절약한다.

```
"Calculator.java, Discount.java, Order.java 세 파일 모두 뮤테이션 테스트 해줘"
```

Claude가 순서대로 실행:

```bash
# 1번 파일 — 커버리지 생성
java -jar $JAR src/main/java/com/example/Calculator.java

# 2번 이후 — 커버리지 재사용
java -jar $JAR src/main/java/com/example/Discount.java  --reuse-coverage
java -jar $JAR src/main/java/com/example/Order.java     --reuse-coverage
```

---

### 시나리오 D — PR 전 특정 라인만 점검

수정한 라인이 12번, 25번이라면:

```
"Calculator.java 12번, 25번 라인만 뮤테이션 해줘"
```

내부 명령:

```bash
java -jar $JAR src/main/java/com/example/Calculator.java --lines 12,25
```

PR 리뷰 전 수정 범위만 빠르게 점검할 때 유용하다.

---

### 시나리오 E — SURVIVED 뮤턴트 전체 잡기 (PR 품질 게이트)

모든 뮤턴트를 잡아야 PR을 머지할 수 있다면:

```
"Calculator.java 뮤테이션 전체 다시 돌려서 SURVIVED 다 잡아줘"
```

내부 명령 (manifest 무시하고 전체 실행):

```bash
java -jar $JAR src/main/java/com/example/Calculator.java --mutate-all --reuse-coverage
```

exit code 0이 될 때까지 살아남은 뮤턴트마다 테스트를 추가한다.

---

## 실전 워크플로우 (권장)

```
┌─────────────────────────────────────────────────────────────┐
│  1. 새 코드 작성                                            │
│     → /mutate4java + "Foo.java 뮤테이션 테스트 해줘"       │
│     → SURVIVED 있으면 테스트 추가 (msbaek-tdd:tdd-red)     │
│                                                             │
│  2. 코드 수정 후                                            │
│     → "Foo.java 변경된 메서드만 다시 뮤테이션 해줘"        │
│     → --since-last-run 으로 수 초 안에 피드백               │
│                                                             │
│  3. PR 전 품질 게이트                                       │
│     → "Foo.java 전체 뮤테이션 테스트 해줘 (--mutate-all)"  │
│     → exit 0 (모든 뮤턴트 KILLED) 확인 후 머지             │
└─────────────────────────────────────────────────────────────┘
```

---

## 지원 뮤테이션 종류

| 종류 | 변환 예시 |
|------|-----------|
| boolean 리터럴 | `true` ↔ `false` |
| 비교 연산자 | `==` ↔ `!=`, `<` ↔ `>`, `<=` ↔ `>=` |
| 산술 연산자 | `+` ↔ `-`, `*` ↔ `/` |
| 논리 연산자 | `&&` ↔ `\|\|` |
| 단항 연산자 | `!expr` → `expr`, `-expr` → `expr` |
| 정수 상수 | `0` ↔ `1` |
| 참조 rvalue | `someExpr` → `null` |

---

## 옵션 레퍼런스

| 옵션 | 설명 |
|------|------|
| `--scan` | 테스트 실행 없이 뮤테이션 사이트 목록만 출력 |
| `--since-last-run` | 변경된 scope만 실행 (manifest 필요) |
| `--mutate-all` | manifest 무시, 전체 재실행 |
| `--reuse-coverage` | 기존 JaCoCo XML 재사용 (배치 실행 시 2번째부터) |
| `--lines 12,18` | 지정한 라인만 뮤테이션 |
| `--update-manifest` | 테스트 실행 없이 manifest만 갱신 |
| `--max-workers N` | 병렬 워커 수 제한 (기본: CPU 코어 / 2) |
| `--verbose` | 워커별 진행 상황 실시간 출력 |
| `--test-command CMD` | `mvn test` 대신 커스텀 테스트 명령 사용 |

### 함께 쓸 수 없는 옵션 조합

| 금지 조합 | 이유 |
|-----------|------|
| `--scan` + `--since-last-run` | scan은 manifest를 읽지 않음 |
| `--scan` + `--mutate-all` | scan은 실행 자체를 안 함 |
| `--scan` + `--reuse-coverage` | scan은 커버리지 불필요 |
| `--lines` + `--since-last-run` | 라인 지정과 scope 변경 감지는 충돌 |
| `--lines` + `--mutate-all` | 범위 지정이 서로 충돌 |
| `--since-last-run` + `--mutate-all` | 정반대 전략 |

---

## Exit Code

| Code | 의미 | 다음 행동 |
|------|------|-----------|
| `0` | 성공 — 모든 뮤턴트 KILLED | 없음 |
| `1` | CLI 옵션 오류 | 옵션 확인 |
| `2` | 베이스라인 테스트 실패 | 먼저 테스트를 고쳐라 |
| `3` | SURVIVED 뮤턴트 있음 | 테스트 보강 필요 |

---

## Embedded Manifest 동작 원리

실행 완료 후 소스 파일 끝에 주석이 자동으로 추가된다:

```java
// === mutate4java manifest ===
// version: 1
// module-hash: a3f8c12d...
// scope: add(int,int) hash=7b2e... lines=10-18
// scope: subtract(int,int) hash=9a1f... lines=20-28
// === end manifest ===
```

다음 번에 `--since-last-run`을 쓰면:
- **해당 scope의 hash 불변** → 실행 건너뜀 (이미 KILLED)
- **hash 변경** → 그 scope만 다시 실행

덕분에 큰 파일도 수정한 메서드만 수 초 내에 재검사할 수 있다.

---

## 관련 리소스

| 리소스 | 용도 |
|--------|------|
| `msbaek-tdd:tdd-red` | SURVIVED 뮤턴트를 잡는 실패 테스트 작성 |
| `msbaek-tdd:tdd-green` | 작성한 테스트 통과시키기 |
| `crap4java` | 복잡도 + 커버리지 기반 리팩터링 우선순위 분석 |

---

## 자주 묻는 질문

**Q: 디렉토리 전체를 한꺼번에 분석할 수 없나요?**
A: 현재 파일 하나씩만 지원한다. 배치 실행은 `--reuse-coverage`로 커버리지 재사용하면서 순서대로 돌린다.

**Q: Maven이 아닌 Gradle 프로젝트에서도 쓸 수 있나요?**
A: 기본은 Maven 전용이다. `--test-command ./gradlew test` 옵션으로 Gradle을 쓸 수 있지만, JaCoCo 리포트 경로 설정이 추가로 필요할 수 있다.

**Q: 테스트 소스(src/test/java)도 뮤테이션 대상인가요?**
A: 아니다. `src/main/java` 아래 소스만 뮤테이션한다.

**Q: 베이스라인 테스트가 실패하면 어떻게 되나요?**
A: exit code 2로 종료하고 뮤테이션을 시작하지 않는다. 먼저 테스트를 모두 통과시켜야 한다.
