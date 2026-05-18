# crap4java Skill & Agent

Java Maven 프로젝트의 메서드별 **CRAP(Change Risk Anti-Patterns)** 점수를 측정하고,
리팩터링 우선순위를 자동으로 제시하는 Claude Code 스킬 + 서브에이전트 패키지.

---

## CRAP이란?

```
CRAP = CC² × (1 - coverage)³ + CC
```

| 변수 | 의미 |
|------|------|
| `CC` | 메서드 cyclomatic complexity (분기 수 + 1) |
| `coverage` | JaCoCo INSTRUCTION 카운터 기준 커버리지 (0.0 ~ 1.0) |

**임계값: 8.0** — 초과 시 exit code 2 (품질 게이트 실패).

직관: 복잡한 코드도 테스트가 충분하면 CRAP이 낮아진다.
반대로 단순한 코드라도 테스트가 없으면 CRAP이 높아진다.

---

## 구성

| 파일 | 역할 |
|------|------|
| `~/.claude/skills/crap4java/SKILL.md` | 스킬 — Claude가 CRAP 관련 요청 시 자동 로드 |
| `~/.claude/skills/crap4java/references/spec.md` | 전체 CLI/모듈/파싱 스펙 (상세 참고) |
| `~/.claude/agents/crap4java-analyzer.md` | 서브에이전트 — 실행·파싱·리팩터링 계획까지 자율 처리 |

**JAR 위치:**
```
~/git/uncle-bob/crap4java/target/crap4java-0.1.0-SNAPSHOT.jar
```

---

## 빠른 시작

### 스킬 트리거 (대화로 호출)

다음 중 하나를 Claude에게 말하면 crap4java 스킬이 자동 활성화됩니다:

- "CRAP 분석해줘"
- "변경된 파일 CRAP 점수 확인해줘"
- "이 파일 cyclomatic complexity + coverage 분석해줘"
- "CRAP score가 8 이상인 메서드 찾아줘"
- "crap4java 실행해줘"

### 서브에이전트 직접 사용

복잡한 분석(실행 → 결과 파싱 → 소스 검사 → 리팩터링 계획)은 서브에이전트에 위임:

```
crap4java-analyzer agent로 [project-root] 전체 분석해줘
```

---

## 사용 예시

### 예시 1: 전체 프로젝트 분석

**사용자:**
```
~/git/myapp 프로젝트 CRAP 분석해줘
```

**Claude (crap4java-analyzer agent):**
1. `~/git/myapp` 에서 `pom.xml` 확인
2. `java -jar .../crap4java-0.1.0-SNAPSHOT.jar` 실행
3. 결과를 위험 티어로 분류

```
## CRAP Analysis — myapp (전체, 2026-05-12)

Exit code: 2
Max CRAP: 24.5  Threshold: 8.0  Status: FAIL

### 🔴 Critical (CRAP > 8.0)

| Method           | Class         | CC | Coverage | CRAP |
|------------------|---------------|----|----------|------|
| processOrder     | OrderService  | 12 | 23%      | 24.5 |
| validatePayment  | PaymentHandler| 8  | 41%      | 10.2 |

### 🟡 Warning (6.0 – 8.0)

| Method     | Class        | CC | Coverage | CRAP |
|------------|--------------|----|----------|------|
| buildQuery | QueryBuilder | 5  | 62%      | 7.1  |

### ⚪ No Coverage (N/A)

| Method      | Class      | CC |
|-------------|------------|----|
| sendEmail   | Mailer     | 3  |

---

## Refactoring Plan

### 1. processOrder — CRAP 24.5
**Problem:** 12개 분기가 한 메서드에 집중된 God Method
**Skill:** `/msbaek-tdd:decompose-conditional` → `/msbaek-tdd:extract-method-object`
**Why:** 분기를 조건별 메서드로 분리하면 CC가 3~4로 줄어 CRAP이 임계값 이하로 내려감

### 2. validatePayment — CRAP 10.2
**Problem:** 커버리지 41% — 테스트 추가만으로 CRAP 8 이하로 내릴 수 있음
**Skill:** `/msbaek-tdd:tdd` (테스트 먼저 작성)
**Why:** coverage 70%만 달성해도 CRAP ≈ 5.5

### 3. sendEmail — N/A (커버리지 없음)
**Problem:** 테스트 전무 — 실제 CRAP 알 수 없음
**Skill:** `/msbaek-tdd:tdd` (테스트 작성 후 재분석)
```

---

### 예시 2: 커밋 전 변경 파일만 빠르게 체크

**사용자:**
```
커밋 전에 변경된 파일 CRAP 점수만 확인해줘
```

**Claude:**
```bash
cd ~/git/myapp
java -jar ~/git/uncle-bob/crap4java/target/crap4java-0.1.0-SNAPSHOT.jar --changed
```

결과가 exit code 0이면 "품질 게이트 통과", 2이면 초과 메서드 목록과 함께 보고.

---

### 예시 3: 특정 파일만 분석

**사용자:**
```
OrderService.java 파일 CRAP 분석해줘
```

**Claude:**
```bash
cd ~/git/myapp
java -jar ~/git/uncle-bob/crap4java/target/crap4java-0.1.0-SNAPSHOT.jar \
  src/main/java/com/example/OrderService.java
```

---

### 예시 4: 멀티모듈 프로젝트에서 특정 모듈만

**사용자:**
```
payment-module이랑 order-module만 CRAP 분석해줘
```

**Claude:**
```bash
cd ~/git/myapp  # repo root
java -jar ~/git/uncle-bob/crap4java/target/crap4java-0.1.0-SNAPSHOT.jar \
  payment-module order-module
```

---

## CRAP 점수 해석 기준

| 범위 | 위험도 | 권장 액션 |
|------|--------|-----------|
| 1 – 5 | 🟢 양호 | 유지 |
| 6 – 8 | 🟡 주의 | 테스트 보강 고려 |
| > 8   | 🔴 위험 | 리팩터링 또는 테스트 우선 추가 |
| N/A   | ⚪ 미측정 | 테스트 작성 후 재분석 |

---

## 리팩터링 스킬 매핑

분석 후 고 CRAP 메서드에는 다음 `msbaek-tdd` 스킬을 적용합니다:

| 코드 스멜 | 권장 스킬 |
|-----------|----------|
| 긴 메서드 + 다중 분기 | `msbaek-tdd:extract-method-object` |
| 중첩 조건문 | `msbaek-tdd:decompose-conditional` |
| instanceof/타입 분기 | `msbaek-tdd:replace-conditional-with-poly` |
| 반복 조건 조각 | `msbaek-tdd:consolidate-conditional` |
| 루프 + 사이드이펙트 | `msbaek-tdd:replace-loop-with-pipeline` |
| 쿼리 + 변경 혼재 | `msbaek-tdd:separate-query-modifier` |
| null/기본값 특수처리 | `msbaek-tdd:introduce-special-case` |
| 커버리지 없음 (N/A) | `msbaek-tdd:tdd` (테스트 먼저) |

---

## 작업 순서 (우선순위)

1. **N/A 메서드** — 테스트 작성 → 커버리지 가시화 → CRAP 자동 하락
2. **고 CC + 저 커버리지** — 테스트 추가로 안전망 확보 → 리팩터링
3. **고 CC + 충분한 커버리지 (≥ 70%)** — 테스트가 보호하므로 즉시 리팩터링 가능

---

## Exit Codes

| Code | 의미 |
|------|------|
| 0 | 성공 (임계값 이내 또는 파일 없음) |
| 1 | CLI 사용 오류 (잘못된 인자) |
| 2 | CRAP 임계값 초과 (최대값 > 8.0) |

---

## 주의사항

- **Maven 전용** — Gradle 프로젝트 미지원
- **생성자·추상·익명 클래스 메서드** 제외
- **JAR 없을 때** — `cd ~/git/uncle-bob/crap4java && mvn -DskipTests package` 로 재빌드
- **JaCoCo XML 없을 때** — Maven 빌드 실패가 원인; `mvn test` 로 빌드 진단
- **멀티모듈** — 각 파일의 가장 가까운 `pom.xml` 기준으로 모듈 판단; 항상 repo root에서 실행

---

## 참고

- [crap4java GitHub](https://github.com/msbaek/crap4java)
- 상세 스펙: `references/spec.md`
- CRAP 원조 논문: Crap4j (Alberto Savoia & Bob Evans, 2007)
