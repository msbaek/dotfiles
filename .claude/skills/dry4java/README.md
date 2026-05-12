# /dry4java 스킬 사용 가이드

Java 소스의 **구조적 중복**을 AST 기반 Jaccard 유사도로 탐지하고, 어디서부터 리팩터링할지
우선순위를 잡아주는 스킬이다.

---

## DRY 위반이란?

> "이름과 리터럴만 다를 뿐, 구조가 같으면 그건 중복이다."

도구가 각 선언(메서드·클래스·생성자·람다 등)을 AST로 파싱하고, 식별자·리터럴을 제거한 채
구조적 fingerprint만 비교한다.

```java
// 선언 A
public int sum(int[] xs) {
    int total = 0;
    for (int x : xs) total += x;
    return total;
}

// 선언 B — 이름·타입만 다름, 구조 동일
public double total(double[] vs) {
    double acc = 0;
    for (double v : vs) acc += v;
    return acc;
}
```

dry4java가 두 선언의 fingerprint를 비교해 **유사도 점수**(0.0~1.0)를 매긴다. 기본 임계값은
`0.82`이며, 그 이상이면 중복 후보로 보고된다.

```
score = shared fingerprints / fingerprints in either candidate
```

---

## 사전 준비

### JAR 빌드 (최초 1회)

```bash
cd ~/git/uncle-bob/dry4java
mvn -q -DskipTests package
```

이후 JAR이 `target/dry4java-0.1.0-SNAPSHOT.jar`에 유지되므로 다시 빌드할 필요 없다.

### 스킬 호출

Claude Code 프롬프트에서:

```
/dry4java
```

또는 자연어로 트리거할 수 있다.

- "중복 코드 찾아줘"
- "dry4java 실행"
- "구조적으로 유사한 코드 찾아줘"
- "copy-paste 패턴 찾기"

---

## 빠른 시작: 첫 번째 DRY 스캔

### 1단계 — 프로젝트 루트에서 실행

```
"이 프로젝트의 중복 코드 찾아줘"
```

Claude가 내부적으로 실행하는 명령:

```bash
cd <project-root>
java -jar ~/git/uncle-bob/dry4java/target/dry4java-0.1.0-SNAPSHOT.jar
```

경로를 지정하지 않으면 현재 디렉토리의 `src/`를 자동 스캔한다.

### 2단계 — 출력 읽기

```
DUPLICATE score=0.97
  src/main/java/app/Invoice.java:12-25
  src/main/java/app/Receipt.java:30-44

DUPLICATE score=0.88
  src/main/java/app/OrderService.java:45-67
  src/main/java/app/RefundService.java:50-72

DUPLICATE score=0.83
  src/main/java/app/Validator.java:10-18
  src/main/java/app/Sanitizer.java:14-22
```

| 점수 범위 | 등급 | 의미 | 권장 액션 |
|-----------|------|------|-----------|
| `0.95 ~ 1.00` | 🔴 거의 동일 | copy-paste 가능성 매우 높음 | 즉시 Extract Method / Extract Class |
| `0.85 ~ 0.94` | 🟡 높은 유사 | 숨은 공통 추상화 존재 가능 | Template Method / Strategy Pattern |
| `0.82 ~ 0.84` | 🟢 중복 후보 | 우연한 유사일 수 있음 | 검토 후 결정 |

### 3단계 — 리팩터링 제안 받기

```
"score 0.97 짜리 먼저 정리하자. 어떻게 줄일까?"
```

Claude가 두 위치의 소스를 읽고 적합한 리팩터링을 제안한다.

```java
// Invoice.java:12-25 와 Receipt.java:30-44 는 99% 동일한 합계 계산
// → 공통 헬퍼로 추출
class MoneyMath {
    static BigDecimal sum(List<LineItem> items) { ... }
}
```

---

## 시나리오별 예제

### 시나리오 A — 특정 디렉토리만 검사

특정 패키지나 모듈만 빠르게 검사하고 싶을 때.

```
"src/main/java/com/example/billing/ 안에서만 중복 찾아줘"
```

내부 명령:

```bash
java -jar $JAR src/main/java/com/example/billing/
```

---

### 시나리오 B — 임계값 조정

기본값(0.82)보다 더 엄격하게 보고 싶거나, 더 많은 후보를 노출하고 싶을 때.

```
"임계값 0.9 이상만 보여줘"   → 거의 동일한 것만
"임계값 0.75 로 낮춰서 더 찾아줘"   → 모호한 후보까지 모두
```

내부 명령:

```bash
java -jar $JAR --threshold 0.90
java -jar $JAR --threshold 0.75
```

---

### 시나리오 C — 멀티 모듈 동시 분석

여러 모듈을 한 번에 검사해서 모듈 간 중복을 찾고 싶을 때.

```
"module-a 와 module-b 사이 중복 코드 있는지 봐줘"
```

내부 명령:

```bash
java -jar $JAR module-a/src module-b/src
```

dry4java는 동일 파일 안의 중복, 같은 모듈 안의 중복, 모듈 간 중복을 모두 탐지한다.

---

### 시나리오 D — 짧은 선언까지 포함

기본은 4줄 이상만 검사. 더 짧은 메서드도 비교 대상에 넣고 싶을 때.

```
"min-lines 2 로 낮춰서 짧은 메서드도 검사해줘"
```

내부 명령:

```bash
java -jar $JAR --min-lines 2
```

> 다만 짧은 선언은 우연한 유사가 많아 노이즈가 늘어난다.

---

### 시나리오 E — 프로그래밍 처리용 EDN 출력

다른 도구로 후속 처리하거나 자동화하려면 EDN(Clojure 데이터) 포맷으로 출력한다.

```
"중복 결과를 EDN 으로 내려줘"
```

내부 명령:

```bash
java -jar $JAR --edn
```

출력 예시:

```clojure
{:candidates
 [{:score 0.89
   :left {:file "src/.../Invoice.java", :start-line 12, :end-line 25}
   :right {:file "src/.../Receipt.java", :start-line 30, :end-line 44}
   :left-nodes 88
   :right-nodes 91}]}
```

---

### 시나리오 F — 리팩터링 후 재검증

중복을 제거했다고 생각하면 같은 경로를 다시 돌려서 점수가 떨어졌는지 확인한다.

```
"방금 Invoice 와 Receipt 정리했어. 진짜 중복 사라졌는지 다시 봐줘"
```

내부 명령:

```bash
java -jar $JAR src/main/java/app/Invoice.java src/main/java/app/Receipt.java
```

이전 결과와 비교해서 score 하락폭을 보고한다.

---

## 실전 워크플로우 (권장)

```
┌─────────────────────────────────────────────────────────────┐
│  1. PR 리뷰 직전                                            │
│     → /dry4java + "이번 PR 디렉토리 중복 검사"             │
│     → 🔴 (≥0.95) 있으면 머지 전 정리                       │
│                                                             │
│  2. 모듈 정리 / 리팩터링 세션                               │
│     → "전체 프로젝트 중복 한번 훑어줘"                     │
│     → 🔴 부터 처리, msbaek-tdd 스킬과 연동                 │
│                                                             │
│  3. 리팩터링 검증                                           │
│     → "수정한 두 파일만 다시 돌려서 score 떨어졌는지 확인"│
└─────────────────────────────────────────────────────────────┘
```

---

## 리팩터링 매핑 (중복 패턴 → 권장 기법)

| 중복 패턴 | 권장 리팩터링 / 연계 스킬 |
|-----------|---------------------------|
| 이름·리터럴만 다른 동일 로직 | Extract Method / Extract Class |
| 동일 알고리즘, 다른 타입 처리 | `msbaek-tdd:replace-conditional-with-poly` / Generic |
| 반복되는 반복문 패턴 | `msbaek-tdd:replace-loop-with-pipeline` |
| 유사한 조건 구조 | `msbaek-tdd:decompose-conditional` |
| 동일 계산이 여러 메서드에 분산 | `msbaek-tdd:extract-method-object` |
| 유사한 초기화·설정 코드 | `msbaek-tdd:introduce-parameter-object` |
| 유사 클래스 간 중복 | Extract Superclass / Extract Interface |

---

## 옵션 레퍼런스

| 옵션 | 기본값 | 설명 |
|------|--------|------|
| `--threshold N` | `0.82` | 유사도 최솟값 (0.0~1.0) |
| `--min-lines N` | `4` | 비교 대상 최소 소스 라인 수 |
| `--min-nodes N` | `20` | 비교 대상 최소 AST 노드 수 |
| `--format text\|edn` | `text` | 출력 형식 |
| `--edn` | — | `--format edn` 과 동일 |
| `--text` | — | `--format text` 와 동일 |

---

## 출력 형식 상세

### text (기본)

```
DUPLICATE score=0.89
  src/main/java/app/Invoice.java:12-25
  src/main/java/app/Receipt.java:30-44
```

### EDN (프로그래밍 처리용)

```clojure
{:candidates
 [{:score 0.8909090909090909
   :left {:file "src/main/java/app/Invoice.java", :start-line 12, :end-line 25}
   :right {:file "src/main/java/app/Receipt.java", :start-line 30, :end-line 44}
   :left-nodes 88
   :right-nodes 91}]}
```

---

## Sub-agent 위임 (상세 분석)

단순 스캔이 아니라 **결과 파싱 + 소스 검사 + 리팩터링 계획**까지 한 번에 받고 싶으면
`dry4java-analyzer` agent로 위임된다. 스킬이 자동으로 위임하는 시점:

- 🔴 (≥0.95) 결과가 다수일 때 — 개별 pair마다 소스 inspect 필요
- "어디부터 정리할까?" 같은 우선순위 질문
- 리팩터링 전후 score 비교 검증

agent는 각 pair의 양쪽 소스를 직접 `Read` 한 뒤, 공통점·차이점·권장 기법을 매핑한
리포트를 돌려준다.

---

## 주의사항

- `src/` 가 없는 디렉토리에서 경로 미지정 실행 시 0건 출력 → 명시적 경로 지정 필요
- 매우 짧은 선언(4줄 미만 / AST 노드 20 미만)은 노이즈 방지를 위해 기본 제외
- Java 파일이 없는 경로를 지정하면 결과 없이 종료
- 0건 출력 = 임계값을 낮춰서 다시 시도해볼 가치 있음 (특히 0.75)
- 동일 파일 내부 선언끼리도 비교 대상 (한 클래스 안 메서드 간 중복도 잡힘)

---

## 자주 묻는 질문

**Q: PMD CPD 와 무엇이 다른가요?**
A: CPD는 토큰 단위 textual matching이라 식별자·리터럴이 바뀌면 놓친다. dry4java는 AST 정규화
후 구조만 비교하므로, 이름·타입이 달라도 구조가 같으면 잡아낸다.

**Q: Gradle 프로젝트에서도 쓰나요?**
A: 빌드 도구와 무관하다. 소스 디렉토리 경로만 전달하면 된다.

**Q: 0.82 점수가 정말 중복인가요?**
A: 0.82~0.84는 우연한 유사일 수 있다. 🟢 등급은 반드시 소스를 직접 보고 결정한다.
시간이 부족하면 `--threshold 0.90` 으로 올려서 🔴·🟡 만 보면 된다.

**Q: 결과를 CI 에 묶을 수 있나요?**
A: `--edn` 출력을 파싱해 임계 개수를 초과하면 fail 시키는 식으로 게이트화 가능하다.
하지만 false positive 가능성이 있으니 hard fail 보다 informational 단계로 시작하는 게 안전하다.

**Q: JAR 이 없다고 나옵니다.**
A: `cd ~/git/uncle-bob/dry4java && mvn -q -DskipTests package` 로 빌드한 뒤 다시 시도.

---

## 관련 리소스

| 리소스 | 용도 |
|--------|------|
| `mutate4java` | 테스트가 뮤턴트를 잡는지로 테스트 품질 검증 |
| `crap4java` | 복잡도 + 커버리지 기반 리팩터링 우선순위 |
| `msbaek-tdd:*` | 중복 패턴별 구체적 리팩터링 절차 |
| `dry4java-analyzer` agent | dry4java 결과의 자동 해석 + 우선순위화 |
