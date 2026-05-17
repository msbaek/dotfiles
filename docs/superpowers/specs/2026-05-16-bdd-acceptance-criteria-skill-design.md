# BDD Acceptance Criteria Skill — Design Spec

> **⚠️ Status: DEFERRED (2026-05-17)** — over-engineering으로 판단되어 보류.
> 자동 호출/CLAUDE.md wiring/trial protocol/rollback은 사용자 핵심 가치("Gherkin이 markdown spec보다 리뷰에 효율적인가?") 검증에 비해 무거움.
> Pivot: 사용자가 명시적으로 호출하는 작은 도구 `/spec-to-feature-review`로 분해.
> 새 spec: `2026-05-17-spec-to-feature-review-tool-design.md`
> 이 문서는 향후 자동화/trial 단계에서 참고용으로만 유지.

**Date**: 2026-05-16
**Updated**: 2026-05-17
**Status**: Design (Phase 1: 1-week trial) — **DEFERRED**
**Author**: 백명석
**Language default**: Java + Cucumber-JVM (English keywords: Given/When/Then)
**Trial period**: 2026-05-16 → 2026-05-23
**Evaluation date**: 2026-05-23

---

## 1. 문제 정의 (Motivation)

### 1.1 현재 상태

사용자의 Superpowers workflow (`brainstorming → writing-plans → executing-plans`)는 strong하지만 한 가지 빈틈이 있다:

- **brainstorming spec**: architecture, components, data flow 등 상세 기술 — **너무 상세해서 리뷰 어렵고 리팩토링에 취약**
- **writing-plans TDD 형식**: Unit Test 수준 구현 세부 결합 — Ian Cooper가 비판한 "구현 세부사항 결합" 그대로

→ 결과: spec과 plan이 **개발자 리뷰 수준의 상세도**로 작성되어, **리뷰가 어렵고 리팩토링에 취약**.

### 1.2 사용자 동기 (Origin)

> "plan/spec은 내용이 너무 상세해서 리뷰에 어려움이 있는데, BDD 스타일로 개발자 테스트를 목표로 하면 리뷰하기 좋겠다는 생각이 들어."

핵심은 **리뷰 용이성** + **리팩토링 탄력성**.

### 1.3 이론적 근거 (Theory Foundation)

vault 검색에서 발견한 3가지 핵심:

| 근거 | 핵심 메시지 | vault 위치 |
|---|---|---|
| **Ian Cooper** — "TDD, Where Did It All Go Wrong" | TDD의 오해 = 클래스 메소드 검증이 아니라 **시스템의 행위** 검증. BDD = TDD 오해를 시나리오로 바로잡는 방법론. Mock은 경계(Port)에만. | `003-RESOURCES/TDD/Misunderstanding/(KOR)Ian Cooper TDD, where did it all go wrong.md` |
| **Kent Beck** — Developer Test 정의 | "Tests should be coupled to **behavior**, decoupled from **structure**." Developer Test = 공개 API 중심, 리팩토링 탄력적. | `003-RESOURCES/TDD/Rules/개발자 테스트 - 단위 테스트.md` |
| **Robert C. Martin** — 테스트 이중 스트림 | **Acceptance Test (What) + Unit Test (How)** 페어. Acceptance = 외부 행위 계약 정의. | `coffee-time/2026-02-23.md` |

추가 origin reference:
- Robert C. Martin의 **Acceptance-Pipeline-Specification** 리포 — Gherkin + mutation testing pipeline. 본 skill의 idea origin.

### 1.4 이 design의 목표

새 skill `bdd-acceptance-criteria`를 도입하여:
1. brainstorming spec 작성 **이후** 자동 호출 → spec을 Gherkin BDD scenarios로 변환
2. **사용자 리뷰 대상 = Gherkin** (spec 대신 — 짧고 행위 중심, 리뷰 부담 최소)
3. **Developer Test 수준** 강제 (행위 중심, 구현 세부 분리, 블랙박스 검증)
4. **Mutation Testing (unit test에만)** 조기 도입
5. 1주 trial로 효과 검증, 실패 시 rollback 가능

---

## 2. 큰 그림 결정 (Pre-brainstorm Agreements)

이전 대화에서 합의된 결정 (재확인용):

| 결정 사항 | 선택 | 대안 |
|---|---|---|
| 통합 layer | **Layer 4 — 신규 skill** | Layer 1 (CLAUDE.md context only), Layer 3 (Hook) |
| 자동 호출 위치 | **Pattern A+C** (brainstorming Step 6 이후 + writing-plans gate) | A only, C only |
| 자동/명시 균형 | **Hybrid** (자동 default + `/bdd-criteria` escape hatch) | 자동 only, 명시 only |
| 검증 주기 | **1-week trial → rollback decision** | 영구 도입, 2-week trial |
| Gherkin 키워드 | **영어** (Given/When/Then) — 1주 후 조정 가능 | 한국어 (기능/시나리오/조건/만일/그러면) |

---

## 3. Design Decisions (Brainstorming 결과)

### 3.1 prompt-contracts skill과의 관계 — 독립, 보완

| Skill | 책임 | 호출 |
|---|---|---|
| `prompt-contracts` | 전반적 계약 (Goal/Constraints/Format/Failure Conditions) | brainstorming/planning 자동 |
| `bdd-acceptance-criteria` (new) | 행위 검증 (Given-When-Then scenarios) | brainstorming Step 6 이후, writing-plans gate |

두 skill 모두 호출됨. prompt-contracts의 "Goal"이 bdd의 scenarios로 변환됨 — **연쇄적 정제**.

### 3.2 Scenario 강제 수준 — 최소 1 happy + 1 sad

- **이유**: Ian Cooper가 비판한 ATDD 한계 중 "happy path만 다루는 시나리오" 회피
- **Kent Beck의 Test List 패턴** 부분 적용 (happy + sad 강제, edge case는 권장)
- trivial 작업은 skill description의 "Skip ONLY for trivial..." 어구로 회피
- **작성 순서**: Degenerate → Simple → General (msbaek-tdd 원칙). 가장 단순한 실패/거부 케이스(degenerate)부터 쓰고, happy path(most general)를 마지막에. 복잡한 비즈니스 시나리오가 자연스럽게 뒤에 온다.

### 3.3 Developer Test 수준 보장 — Examples + Self-Review + Mutation Testing

- SKILL.md에 **좋은 예 / 나쁜 예 (Java)** 충분 제공
- Scenario 작성 후 AI가 **4-point self-review** 실행:
  1. 구현 세부 없음 (DB table, class name, method 호출, query 등)
  2. UI 세부 없음 ("button click" 대신 사용자 의도)
  3. 외부 관찰 가능 (내부 상태 들춰볼 필요 없음)
  4. Mock 없이 검증 가능 (외부 경계 행위)
- 하나라도 fail → scenario 재작성

### 3.4 언어 default — Java + Cucumber-JVM (English keywords)

- 사용자가 Java 30년+, Spring/JUnit/Mockito 전문가
- Cucumber-JVM 사용
- **Gherkin 키워드: 영어** (`Given/When/Then/And/But`) — 1주 trial 후 한국어로 전환 가능
- **결정적 가치**: spec → Gherkin 생성 → **사용자 리뷰 대상이 Gherkin** (spec 상세 내용 아님)
- **spec과 .feature 병행**: spec은 상세 기술 문서로 유지. Gherkin은 spec에서 추출하여 `.feature`로 저장. spec이 불필요해지면 제거 가능.
- Fallback: 사용자가 "too much"라고 판단 시 요청 → JUnit + Given-When-Then 주석
- Mutation Testing: `mutate4java` 스킬로 별도 진행 — 이 skill 범위 밖

### 3.5 Acceptance Test 중심 (이중 스트림 완화)

- **Acceptance Test (What)**: spec → Gherkin → `.feature` → **사용자 리뷰/승인** → writing-plans
- **Unit Test (How)**: writing-plans/executing-plans의 TDD inner loop에서 자연스럽게 작성
- acceptance test만으로 충분하면 OK — unit test 강제 불필요
- Robert C. Martin의 "이중 스트림" 참고 의미는 유지하되, **Two-Stream Mapping 표는 writing-plans에서 옵션**으로

---

## 4. Skill Identity

### 4.1 Frontmatter

```yaml
---
name: bdd-acceptance-criteria
description: >
  You MUST use this skill AFTER writing a brainstorming spec (Step 6).
  Converts spec into Given-When-Then Gherkin scenarios at Developer Test level
  (Kent Beck: behavior-coupled, structure-decoupled).
  The user reviews GHERKIN, not the full spec — short, behavior-focused, easy to approve.
  Auto-invoke: after brainstorming Step 6 (spec written), before Step 8 (user review).
  Pre-flight gate: invoked by writing-plans when "## Acceptance Criteria" section absent.
  Explicit invoke: `/bdd-criteria <spec-file>` for existing-spec augmentation.
  Skip ONLY for trivial Q&A or single-line edits.
  Required output: ≥1 happy scenario + ≥1 sad scenario, each passing
  self-review (no implementation details, externally observable, mock-free).
  Language default: Java + Cucumber-JVM (English keywords: Given/When/Then).
---
```

### 4.2 정체성 한 줄

> Spec → 행위 검증 가능한 Gherkin 변환기. 사용자는 Gherkin만 리뷰한다. (Kent Beck/Ian Cooper/Robert C. Martin 통합)

---

## 5. SKILL.md 본문 구조

### 5.1 Header + HARD-GATE

```markdown
# BDD Acceptance Criteria

Spec intent를 Given-When-Then 행위 검증 시나리오로 변환.
사용자 리뷰 대상 = Gherkin (짧고 행위 중심). Spec 전체 리뷰 불필요.
Kent Beck의 Developer Test + Ian Cooper의 행위 중심 TDD 통합.

<HARD-GATE>
다음 충족 전까지 writing-plans skill 호출 금지:
- ≥1 happy scenario + ≥1 sad scenario 작성됨
- 각 scenario가 self-review 4-point 통과
- spec 파일에 "## Acceptance Criteria" 섹션으로 통합됨
- 사용자가 Gherkin scenarios를 승인함
</HARD-GATE>
```

### 5.2 Checklist (7-step)

각 항목 TaskCreate 후 순차 실행:

1. **Spec 파악** — brainstorming spec 파일 읽기 (이미 작성된 상태)
2. **Happy path scenario 작성** — 정상 흐름, Given-When-Then 형식
3. **Sad path scenario 작성** — 예상 실패/거부 흐름
4. **(선택) Edge case scenario** — 경계 조건, 복잡한 기능 시
5. **Self-review** — 각 scenario에 대해 4-point checklist 실행
6. **Spec 통합 + .feature 생성** — `## Acceptance Criteria` 섹션으로 통합. Cucumber 모드면 `.feature` 파일도 생성.
7. **사용자 Gherkin 제시 + 승인 요청** — spec 전체 리뷰 대신 Gherkin만 제시. 승인 후 writing-plans 호출.

### 5.3 BDD Template (English Keywords)

```gherkin
Feature: <one-line intent>

  Scenario: <happy path description>
    Given <precondition — externally observable state>
    When <trigger — user/system intent>
    Then <expected result — externally verifiable effect>
    And <additional expectation, optional>

  Scenario: <sad path description>
    Given <precondition>
    When <trigger>
    Then <expected failure/rejection result>
    And <additional expectation, optional>
```

### 5.4 Self-Review Checklist (4-point, 모든 scenario 통과 필수)

각 scenario에 대해:

- [ ] **구현 세부 없음**: DB table, class name, method 호출, SQL query 등 언급 안 함
- [ ] **UI 세부 없음**: "button click", "modal open" 대신 사용자 의도 표현
- [ ] **외부 관찰 가능**: Then의 결과를 검증하려고 내부 상태 들춰볼 필요 없음
- [ ] **Mock 없이 검증 가능**: 행위 자체가 외부 경계(Port)에서 발생 — Ian Cooper
- [ ] **Act-Assert 동일 추상화 수준**: When과 Then이 같은 API 레벨. POST로 생성했으면 Then은 GET 응답으로 검증 — DB 직접 조회, 내부 필드 확인 금지

하나라도 fail → scenario 재작성.

### 5.5 Key Principles

- **행위(What) > 구현(How)** (Ian Cooper) — 내부를 블랙박스로 간주, 외부에서 행위 검증
- **외부 관찰 가능** (Ian Cooper — "Port at boundary")
- **리팩토링 탄력성** (Kent Beck — "decoupled from structure")
- **Programmer Test 원칙**: Behavior change에 민감, structure change에 둔감. 사용자에게 가치를 제공하는 external behavior에 coupled, 리팩터링 시 변경되는 internal structure에 decoupled. (msbaek-tdd Programmer Test 규칙과 동일 원칙)
- **Gherkin = 사용자 리뷰 언어** — 짧고 행위 중심. spec 상세 내용은 AI가 해석, 사용자는 Gherkin만 승인.
- **유스케이스마다 소수의 테스트** — acceptance test는 행위를 잘 드러내는 데 집중.

### 5.6 References Section

`references/sources.md`:
```markdown
# 이론적 근거 (Theory References)

## Robert C. Martin (Uncle Bob)
- **Acceptance-Pipeline-Specification 리포**: https://github.com/unclebob/Acceptance-Pipeline-Specification
- **테스트 이중 스트림** (커피타임 2026-02-23): Acceptance = What, Unit = How

## Kent Beck
- "Tests coupled to behavior, decoupled from structure" (X/Twitter)
- Developer Test 개념

## Ian Cooper
- "TDD, Where Did It All Go Wrong" (NDC Porto 2023)
- 행위 검증 + 모듈 경계(Port) + BDD = TDD 오해 교정

## Vault Sources (local)
- `003-RESOURCES/TDD/Misunderstanding/(KOR)Ian Cooper TDD, where did it all go wrong.md`
- `003-RESOURCES/TDD/Rules/개발자 테스트 - 단위 테스트.md`
- `coffee-time/2026-02-23.md`
- `003-RESOURCES/TDD/AI-에이전트와-TDD-유닛-테스트가-아닌-개발자-테스트.md`
```

---

## 6. Java + Cucumber-JVM 변환 패턴

### 6.1 도구 default

- **Cucumber-JVM** (`.feature` + step definitions)
- **JUnit 5** (runner)
- **AssertJ** (fluent assertions)
- **Spring Boot** `@SpringBootTest`

Fallback: 사용자가 "too much"라고 판단 시 요청 → JUnit + Given-When-Then 주석

### 6.2 변환 매핑 (1:1)

| Spec Gherkin (English) | Java Cucumber Annotation |
|---|---|
| `Scenario: <title>` | `.feature` 파일의 Scenario block |
| `Given <precondition>` | `@Given("...")` step definition |
| `When <action>` | `@When("...")` step definition |
| `Then <result>` | `@Then("...")` step definition |
| `And <additional>` | `@And("...")` step definition |

### 6.3 디렉토리 구조

```
src/test/
├── java/com/example/subscription/
│   ├── SubscriptionStepDefinitions.java
│   └── CucumberSpringConfiguration.java
└── resources/features/
    └── subscription-upgrade.feature
```

### 6.4 의존성 (Gradle)

```gradle
testImplementation 'io.cucumber:cucumber-java:7.18.0'
testImplementation 'io.cucumber:cucumber-junit-platform-engine:7.18.0'
testImplementation 'io.cucumber:cucumber-spring:7.18.0'
testImplementation 'org.junit.platform:junit-platform-suite:1.10.0'
```


### 6.5 예시 — Happy + Sad path (English Gherkin)

`subscription-upgrade.feature`:
```gherkin
Feature: Subscription upgrade

  Scenario: Free user upgrades to Pro successfully
    Given a free-tier user is logged in
    When the user subscribes to Pro
    Then Pro features become accessible within 5 seconds
    And a payment receipt is delivered to the user

  Scenario: Card error keeps tier unchanged
    Given a free user with an expired card is registered
    When the user subscribes to Pro
    Then the subscription fails and the tier stays Free
    And a retry guidance notification is delivered to the user
```

`SubscriptionStepDefinitions.java`:
```java
@SpringBootTest
@CucumberContextConfiguration
public class SubscriptionStepDefinitions {

    @Autowired private SubscriptionFacade subscription;
    @Autowired private FeatureAccess featureAccess;
    @Autowired private ReceiptInbox receiptInbox;
    @Autowired private UserFixtures fixtures;

    private User user;
    private SubscriptionResult result;
    private Instant startedAt;

    @Given("a free-tier user is logged in")
    public void freeUserLoggedIn() {
        this.user = fixtures.givenFreeUserLoggedIn();
    }

    @Given("a free user with an expired card is registered")
    public void freeUserWithExpiredCard() {
        this.user = fixtures.givenFreeUserWithExpiredCard();
    }

    @When("the user subscribes to Pro")
    public void userSubscribesToPro() {
        this.startedAt = Instant.now();
        this.result = subscription.subscribeTo(user, Tier.PRO);
    }

    @Then("Pro features become accessible within {int} seconds")
    public void proAccessibleWithinSeconds(int seconds) {
        assertThat(result.isSuccessful()).isTrue();
        assertThat(Duration.between(startedAt, Instant.now()))
            .isLessThan(Duration.ofSeconds(seconds));
        assertThat(featureAccess.canAccess(user, ProFeature.ADVANCED_REPORTS))
            .isTrue();
    }

    @And("a payment receipt is delivered to the user")
    public void receiptDelivered() {
        assertThat(receiptInbox.findFor(user)).isPresent();
    }

    @Then("the subscription fails and the tier stays Free")
    public void subscriptionFailsAndTierStaysFree() {
        assertThat(result.isSuccessful()).isFalse();
        assertThat(result.failureReason()).isEqualTo(FailureReason.CARD_INVALID);
        assertThat(featureAccess.canAccess(user, ProFeature.ADVANCED_REPORTS))
            .isFalse();
    }

    @And("a retry guidance notification is delivered to the user")
    public void retryGuidanceDelivered() {
        assertThat(user.notifications())
            .anyMatch(n -> n.type() == NotificationType.RETRY_PAYMENT);
    }
}
```

### 6.6 Anti-example (구현 세부 누설)

```java
// ❌ BAD: 구현 세부 결합
@Test
void test_upgradeToPro() {
    // Given: users 테이블에 직접 INSERT
    jdbcTemplate.update("INSERT INTO users (id, tier) VALUES (1, 'free')");

    // When: UserService.upgrade() 메서드 호출
    userService.upgrade(1L, "pro");

    // Then: users.tier 컬럼이 'pro'로 변경됨
    String tier = jdbcTemplate.queryForObject(
        "SELECT tier FROM users WHERE id=1", String.class);
    assertEquals("pro", tier);
}
```

**문제** (Self-review 4-point fail):
- `jdbcTemplate` 직접 사용 → 데이터 계층 결합
- `UserService.upgrade()` 구체 메서드 의존 → 리네임 시 깨짐
- SQL이 테스트에 침투 → 스키마 변경 시 깨짐
- **외부 행위 (Pro 기능 접근, 영수증 도달) 검증 없음** — Ian Cooper의 핵심 비판

---

## 7. CLAUDE.md Wiring

### ⚠️ 핵심 제약: Superpowers Plugin 파일 수정 금지

`~/.claude/plugins/` 하위 파일 (brainstorming SKILL.md, writing-plans SKILL.md 등)은 **직접 수정 불가**.
업그레이드 시 변경사항이 유실된다.

**유일한 확장 방법**: `~/.claude/CLAUDE.md`의 `<*-context>` 태그로만 동작 보강.

수정 파일: `~/.claude/CLAUDE.md` (백업: `~/.claude/CLAUDE.md.bak-pre-bdd-trial-20260516`)

### 7.1 Wiring #1 — `<brainstorming-context>`

```markdown
<brainstorming-context>
Each design: Goal / Constraints / Failure Conditions 명시.
(사용자 프로파일은 Section 1 Context 참조)

**MANDATORY auto-invocation after Step 6 (spec 작성 완료)**:
- BEFORE Step 8 (user review), invoke `bdd-acceptance-criteria` skill
- 변환: spec → ≥1 happy + ≥1 sad Gherkin scenarios (English keywords)
- **사용자 리뷰 대상 = Gherkin** (spec 전체 아님 — 짧고 행위 중심)
- 결과: spec의 `## Acceptance Criteria` 섹션 + Cucumber `.feature` 파일
- Skip ONLY if: spec이 이미 `## Acceptance Criteria` 섹션을 포함하고 Gherkin이 승인됨

**Plugin Step 8 워딩 충돌 처리 (CRITICAL)**:
- 플러그인 brainstorming SKILL.md Step 8은 "Please review it [the spec]"이라고 명시 → 우리 의도("Gherkin만 review")와 충돌
- 충돌을 우리 의도 쪽으로 reframe:
  - Step 8 진입 시 사용자에게 **Gherkin scenarios만 제시** (spec 파일 본문 출력 금지)
  - spec 파일 경로는 reference로만 한 줄 언급 ("spec 본문은 `<path>`. 검토는 아래 Gherkin으로 충분합니다.")
  - 사용자가 spec 본문 자체를 요청하면 그때만 제시
- 이 reframe이 작동하지 않으면(사용자가 spec과 Gherkin을 모두 보게 됨) → "Gherkin만 review" 핵심 가치 무산. trial 평가에서 이 시나리오 빈도를 기록.

**언어 기본값**: Java + Cucumber-JVM. Gherkin keywords: English (Given/When/Then).
</brainstorming-context>
```

### 7.2 Wiring #2 — `<writing-plans-context>`

```markdown
<writing-plans-context>
Each task: Output Format + Failure Conditions.
Plan: Goal (testable) + Constraints (non-negotiable).

**MANDATORY pre-flight check**:
1. Read spec file referenced by user
2. grep for "## Acceptance Criteria" section
3. If missing → STOP, invoke `bdd-acceptance-criteria` skill on the spec
4. If present → verify each scenario has Given-When-Then (English) structure and user-approved
5. Task 0 (mandatory): "Write Cucumber `.feature` + step definitions from Scenario 1 (happy)"
   - Task 0 실패 테스트 작성 후 → 사용자 리뷰/실행 확인 후 → 다음 Task 진행

**언어 기본값**: Java. Task 0 acceptance test = JUnit 5 + Cucumber-JVM.
(사용자가 "too much"라고 판단 시 JUnit + Given-When-Then 주석으로 대체 요청 가능)
</writing-plans-context>
```

### 7.3 Wiring #3 — `<superpowers-workflow>`

```markdown
<superpowers-workflow>
Complex tasks:
  brainstorming (Steps 1-6: spec 작성)
    → bdd-acceptance-criteria (spec → Gherkin 생성) [NEW — auto after Step 6]
    → [사용자: Gherkin 리뷰/승인]  ← 사용자 리뷰는 spec 아닌 Gherkin
    → writing-plans
    → executing-plans

TDD: NO PRODUCTION CODE WITHOUT FAILING TEST FIRST.
     Task 0 = Cucumber `.feature` green (acceptance test).
     Unit tests = Task 1+ TDD inner loop (자연스럽게, 강제 없음).
ADR: 2+ alternatives → suggest ADR.

**Language default: Java + Cucumber-JVM (English keywords)**.
**Superpowers plugin files: read-only.** Extend via CLAUDE.md context tags only.
</superpowers-workflow>
```

---

## 8. `/bdd-criteria` Slash Command

### 8.1 위치

`~/dotfiles/.claude/commands/bdd-criteria.md`

### 8.2 Frontmatter

```yaml
---
description: BDD acceptance criteria 작성 — spec을 Given-When-Then Gherkin으로 변환. 사용자 리뷰 대상은 Gherkin(짧고 행위 중심). 자동 호출은 brainstorming Step 6 이후, writing-plans pre-flight에서 발생. 명시 호출은 기존 spec 보강·단독 사용.
argument-hint: <spec-file> | --review <spec-file> | --feature "<설명>"
allowed-tools: [Read, Edit, Write, Skill, Bash, Grep]
---
```

### 8.3 모드

| 형식 | 효과 |
|---|---|
| `/bdd-criteria <spec-file>` | spec → `## Acceptance Criteria` 섹션 + `.feature` 생성 |
| `/bdd-criteria --review <spec-file>` | 기존 Gherkin의 4-point self-review만 실행 (수정 없이 보고) |
| `/bdd-criteria --feature "<설명>"` | spec 없이 단독 사용 (PoC, spike) |

### 8.4 Delegation 결정 — 변형 D (main context 직접 실행)

main context에서 Skill 도구로 직접 호출. brainstorming context 유지 필수.

---

## 9. 변경 인벤토리

### 9.1 신규 파일 (5개)

| 파일 | 책임 | 크기 추정 |
|---|---|---|
| `~/dotfiles/.claude/skills/bdd-acceptance-criteria/SKILL.md` | 메인 skill 정의 | ~250줄 |
| `~/dotfiles/.claude/skills/bdd-acceptance-criteria/references/sources.md` | 이론 reference (Kent Beck, Ian Cooper, Uncle Bob) | ~50줄 |
| `~/dotfiles/.claude/skills/bdd-acceptance-criteria/references/java-cucumber-examples.md` | Java Cucumber 변환 예제 풀 | ~200줄 |
| `~/dotfiles/.claude/skills/bdd-acceptance-criteria/rollback.sh` | 1주 trial rollback 스크립트 | ~40줄 |
| `~/dotfiles/.claude/commands/bdd-criteria.md` | Slash command (thin wrapper) | ~30줄 |

### 9.2 수정 파일 (1개, 백업 후)

| 파일 | 변경 내용 | 백업 |
|---|---|---|
| `~/.claude/CLAUDE.md` | 3겹 wiring (brainstorming-context, writing-plans-context, superpowers-workflow) + Problem-first ② | `~/.claude/CLAUDE.md.bak-pre-bdd-trial-$(cat ~/.claude/.bdd-trial-install-stamp)` |

### 9.3 Install marker (1개)

| 파일 | 책임 |
|---|---|
| `~/.claude/.bdd-trial-install-stamp` | install 날짜(YYYYMMDD) 기록. rollback.sh가 백업 파일명을 동적으로 결정하는 데 사용. |

**수정 금지 파일**: `~/.claude/plugins/cache/claude-plugins-official/superpowers/**` (업그레이드 시 유실)

---

## 10. 의존성 다이어그램

```
                    사용자: "X 기능 만들어줘"
                          │
                          ▼
                ┌─────────────────────┐
                │  brainstorming      │
                │  Steps 1-6          │
                │  (spec 작성 완료)   │
                └──────────┬──────────┘
                           │ spec 작성됨
                           │
              CLAUDE.md <brainstorming-context>
              MANDATORY auto-invoke ↓
                           │
                ┌──────────▼──────────────────────┐
                │ bdd-acceptance-criteria          │  ◄── /bdd-criteria (manual)
                │  - spec → Gherkin 변환            │
                │  - ≥1 happy + ≥1 sad             │
                │  - Self-review 4-point            │
                │  - ## Acceptance Criteria 통합    │
                │  - .feature 파일 생성             │
                └──────────┬──────────────────────┘
                           │
                ┌──────────▼──────────────────────┐
                │ 사용자: Gherkin 리뷰/승인        │
                │  (spec 전체 아님 — 짧고 행위 중심)│
                │  승인 → writing-plans            │
                │  수정 → bdd-criteria 재실행       │
                └──────────┬──────────────────────┘
                           │ Gherkin 승인됨
                ┌──────────▼──────────┐
                │ writing-plans       │
                │ Pre-flight gate:    │
                │  grep "## Accept-   │
                │   ance Criteria"    │
                └──────────┬──────────┘
                  present? │
              ┌────────────┼────────────┐
              │ no                       │ yes
              ▼                           ▼
        bdd-criteria              Task 0 (.feature green)
        (재호출)                   + Task 1+ (TDD inner loop)
                                   사용자: Task 0 실패 테스트
                                   리뷰/실행 후 진행
                                          │
                                          ▼
                                    executing-plans
```

---

## 11. Future Extensions

### 11.1 Acceptance Example Mutation (Robert C. Martin 방식)

Uncle Bob의 [Acceptance-Pipeline-Specification](https://github.com/unclebob/Acceptance-Pipeline-Specification)에서 정의한 mutation testing.

**핵심 원칙**: 소스 코드가 아닌 **Gherkin `Examples` table의 값(parameter)만** 변이시킨다.

```
feature file → parser → base JSON IR
  → mutator: Examples의 각 cell 값을 하나씩 변이 (20 → 27, "accepted" → "accfpted")
  → 변이된 IR → acceptance test 생성 → test runner 실행
  → fail이면 "killed"  : acceptance test가 변이를 감지함 (good)
  → pass이면 "survived": acceptance test가 허술하다는 신호 → scenario 보강 필요
```

**unit test 코드 변이(mutate4java)와 다른 점**:

| | Uncle Bob's acceptance mutation | mutate4java |
|---|---|---|
| 변이 대상 | Gherkin Examples 값 | Java 소스 코드 |
| 검증 대상 | acceptance test quality | unit test quality |
| 목적 | "이 시나리오가 충분히 구체적인가?" | "이 unit test가 로직 변화를 잡는가?" |

**적용 전제조건**: `Scenario Outline` + `Examples` 테이블 형식 필요.

```gherkin
Scenario Outline: Subscription upgrade outcome
  Given a <tier> user with card status <card_status>
  When the user subscribes to Pro
  Then the result is <expected_result>

  Examples:
    | tier | card_status | expected_result |
    | free | valid       | success         |
    | free | expired     | failure         |
```

Mutator가 `valid → valud`, `success → succfss` 등으로 변이 → acceptance test가 감지하지 못하면 시나리오 보강.

**도입 시점**: 1주 trial 성공 후 별도 검토. 별도 pipeline 구현 필요.

### 11.2 Unit Test Mutation

- `mutate4java` 스킬로 별도 진행.
- Java 소스 코드 변이 → unit test quality 측정.
- 이 skill 범위 밖.

### 11.3 Hook 기반 Hard Gate

- 1주 trial에서 자동 호출 신뢰성 <30% 시 PreToolUse hook 도입 검토.

---

## 12. 1주 Trial Protocol

### 12.0 Trial의 실제 검증 대상 (정직성 단락)

이 trial이 측정하는 것은 "BDD 가치" 자체가 아니라, **"Claude가 CLAUDE.md MANDATORY 어구에 얼마나 순응하는가"**이다.

CLAUDE.md의 `<brainstorming-context>` 같은 context 태그가 brainstorming skill 실행 시 LLM 컨텍스트에 함께 로드되어 MANDATORY 지시를 따르도록 유도하는 메커니즘은 **mechanism이 아니라 hope**:

- superpowers 플러그인 SKILL.md는 read-only (수정 금지)
- CLAUDE.md context 태그가 plugin SKILL.md의 Step 8("review the spec")과 **충돌**할 수 있음
- Claude가 두 컨텍스트를 모두 읽고 MANDATORY를 따르길 기대(hope)할 뿐

따라서:
1. **평가 기준 12.2의 정량 50% 통과** = "BDD 효익 50%"가 아니라 **"Claude 순응도 50%"**
2. **워딩 충돌 처리** (Section 7.1 참조): Step 8에서 사용자에게 "Gherkin만 제시, spec 본문 출력 금지"를 명시
3. **측정 가능성 먼저** (Section 12.1.5 Day 0 dry-run): trial 시작 전 측정 메커니즘이 의미 있는지 확인



### 12.1 일정 (install일 기준 동적 산정)

Install 시점에 `~/.claude/.bdd-trial-install-stamp` 마커 파일에 install 날짜(YYYYMMDD) 기록. 모든 일정은 marker 기준 상대 일자.

| 시점 | 행동 |
|---|---|
| D (install일) | Trial 시작. 모든 변경 단일 commit. marker 파일 생성. Things 태스크는 D+4 날짜로 자동 등록. `~/.claude/journals/YYYY-MM.journal.md` 기록. |
| D+4 | **중간 평가** — 자동 호출 횟수/Gherkin 리뷰 체감 메모 |
| D+7 | 최종 평가 + 결정 (유지/롤백/조정) |

**예시 (2026-05-17 install)**: D=2026-05-17, D+4=2026-05-21, D+7=2026-05-24. 단, 기존 Things 태스크(`2026-05-20`)는 사용자가 의도적으로 등록한 것이므로 install일에 맞춰 수정 여부 확인.

### 12.1.5 Day 0 Dry-Run (필수, trial 시작 전)

trial 시작 전 측정 메커니즘이 의미 있는지 확인:

1. **agf search 출력 검증**:
   ```bash
   agf search bdd-criteria --last 1
   agf search brainstorming --last 1
   ```
   → output이 "skill 호출"을 추적하는지 "텍스트 멘션"을 카운트하는지 판별

2. **측정 단위 결정**:
   - 분자: 실제 `Skill` 도구로 `bdd-acceptance-criteria` 호출된 횟수
   - 분모: brainstorming skill이 실행된 세션 수 (마지막 turn 기준)

3. **판단**:
   - 측정 가능 → trial 정식 시작
   - 측정 불가능 → trial 보류하고 측정 방법 재설계 (예: skill 호출 시 자체 로그 파일에 timestamp 기록)

dry-run 결과는 `~/.claude/journals/YYYY-MM.journal.md`에 기록.

### 12.2 평가 기준

**유지 기준 (이중 만족)**:
1. **정량**: brainstorming/writing-plans 진입 시 bdd-criteria가 ≥50% 자동 호출됨
   - 측정: `agf search bdd-criteria --last 7` 로 호출 횟수 확인
   - 비교 분모: brainstorming 실행 횟수 (`agf search brainstorming --last 7`)
2. **정성**: 사용자가 "Gherkin 리뷰가 spec 리뷰보다 쉬웠다"고 자기 인식
   - 2026-05-23 인터뷰: "Gherkin 리뷰가 의사결정에 도움이 됐나?" 등 질문

**롤백 기준 (어느 하나)**:
- 자동 호출이 30% 미만 (description 어구 실패)
- false-positive로 작업 흐름 방해 (trivial 작업에서도 자동 호출)
- 사용자가 Gherkin 작성 부담이 효익보다 크다고 느낌

**중간 (개선 옵션)**:
- 30~50% 구간 → SKILL.md/wiring 조정 후 추가 1주 trial

**2026-05-23 인터뷰 항목** (평가 시 사용자에게 요청):
1. Gherkin 리뷰가 spec 리뷰보다 빠르고 쉬웠나?
2. Gherkin을 보고 "이게 내가 원하는 동작인가" 판단하기 쉬웠나?
3. Cucumber 셋업이 부담스러웠나?
4. 어떤 작업에서 가장 유용했고, 어떤 작업에서 방해됐나?

### 12.3 Rollback 메커니즘

**Install 단계에서 마커 파일 생성 필수**:
```bash
# install 직전에 실행:
date +%Y%m%d > "$HOME/.claude/.bdd-trial-install-stamp"
cp "$HOME/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md.bak-pre-bdd-trial-$(cat $HOME/.claude/.bdd-trial-install-stamp)"
```

`~/dotfiles/.claude/skills/bdd-acceptance-criteria/rollback.sh`:

```bash
#!/bin/bash
set -e

MARKER="$HOME/.claude/.bdd-trial-install-stamp"

if [ ! -f "$MARKER" ]; then
    echo "ERROR: install marker 파일 없음: $MARKER"
    echo "→ trial이 적용되지 않았거나 marker가 손상됨."
    echo "→ 수동으로 백업 파일(~/.claude/CLAUDE.md.bak-pre-bdd-trial-*)을 찾아 복원하거나 git revert 사용."
    exit 1
fi

STAMP=$(cat "$MARKER")
BAK="$HOME/.claude/CLAUDE.md.bak-pre-bdd-trial-$STAMP"

if [ ! -f "$BAK" ]; then
    echo "ERROR: 백업 파일 없음: $BAK"
    echo "→ marker는 있으나 백업이 손상됨. git revert로 복원 시도."
    exit 1
fi

# 이미 롤백됐는지 확인 (idempotency)
if ! grep -q "bdd-acceptance-criteria" "$HOME/.claude/CLAUDE.md" 2>/dev/null; then
    echo "INFO: CLAUDE.md에 bdd wiring 없음 — 이미 롤백됐거나 미적용 상태."
fi

# 1. CLAUDE.md 복원
cp "$BAK" "$HOME/.claude/CLAUDE.md"
echo "✓ CLAUDE.md 복원 완료 (marker: $STAMP)"

# 2. Marker 제거
rm -f "$MARKER"
echo "✓ install marker 제거"

# 3. Skill 디렉토리 제거 (없어도 오류 없음)
rm -rf "$HOME/dotfiles/.claude/skills/bdd-acceptance-criteria"
echo "✓ skill 디렉토리 제거"

# 4. Slash command 제거 (없어도 오류 없음)
rm -f "$HOME/dotfiles/.claude/commands/bdd-criteria.md"
echo "✓ slash command 제거"

# 5. dotfiles에 rollback 커밋
cd "$HOME/dotfiles"
git add -A
git commit -m "revert: bdd-acceptance-criteria trial - 평가 후 롤백 (install: $STAMP)"

echo ""
echo "✅ Rollback 완료. 효과/실패 회고를 ~/.claude/journals/에 기록 권장."
```

### 12.4 위험 매트릭스

| # | 위험 | 측정 방법 | 완화 |
|---|---|---|---|
| 1 | 자동 호출 신뢰성 부족 | agf search로 invoke 횟수 확인 | 3겹 wiring redundancy. <30% 시 Hook 도입 검토 |
| 2 | Trivial 작업 false-positive | 사용자 정성 평가 | "Skip ONLY for trivial..." 어구. 잡음 많으면 description 조정 |
| 3 | Cucumber 셋업 부담 | 사용자 요청 횟수 | 사용자 요청 시 JUnit fallback |
| 4 | Self-review LLM judgment 실패 | scenario anti-pattern 잔존 빈도 | Examples/anti-examples 충분 제공 |
| 5 | Rollback 시 자료 손실 | rollback.sh 테스트 (idempotency 포함) | 백업 파일 + git history 이중 보호 |

---

## 13. Acceptance Criteria for This Design (Dogfooding)

이 spec 자체의 acceptance criteria. 이 skill이 만들어지면 적합한 예제로 dogfooding 필수.

```gherkin
Feature: bdd-acceptance-criteria skill introduction

  Scenario: Auto-invocation flow works after spec is written
    Given a user is proceeding with a new feature design using brainstorming skill
    When brainstorming Step 6 (spec writing) completes
    Then bdd-acceptance-criteria skill is invoked automatically
    And the spec file gains a "## Acceptance Criteria" section
    And the section contains ≥1 happy + ≥1 sad scenario in English Gherkin format
    And the user is presented with only the Gherkin for review (not the full spec)

  Scenario: writing-plans gate fires when Acceptance Criteria is absent
    Given a spec file has no "## Acceptance Criteria" section
    When the user attempts to enter writing-plans skill
    Then writing-plans detects the missing section
    And bdd-acceptance-criteria skill is re-invoked
    And plan writing is paused until Gherkin is approved

  Scenario: Rollback is lossless after one-week trial
    Given a rollback decision is made after the trial evaluation
    When the user runs rollback.sh
    Then CLAUDE.md is restored from the backup file
    And the skill directory and slash command are removed
    And changes are recorded as a revert commit in dotfiles git history
```

---

## 14. Status

- [x] Brainstorming Steps 1-5 완료
- [x] Spec 작성 (이 문서) — Step 6
- [x] Spec self-review — Step 7
- [x] User reviews spec (HTML) — Step 8
- [x] Spec 피드백 반영 (2026-05-17) — 주요 변경: 흐름 변경 (Gherkin 리뷰), 영어 키워드, Mutation Testing 도입, Superpowers 수정 금지 명시
- [x] Advisor 종합 리뷰 5건 처리 (2026-05-17) — rollback.sh 마커 기반, Trial 일정 동적화, MANDATORY 어구 순응도 정직 단락, Step 8 워딩 충돌 reframe, Day 0 dry-run 추가
- [ ] Transition to writing-plans — Step 9

---

**End of Design Spec**
