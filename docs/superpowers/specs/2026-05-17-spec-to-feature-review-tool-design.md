# spec-to-feature-review Tool — Design Spec

**Date**: 2026-05-17
**Status**: Design
**Author**: 백명석
**Pivot from**: `2026-05-16-bdd-acceptance-criteria-skill-design.md` (deferred — over-engineering)

---

## 1. 문제 정의

Superpowers `brainstorming` / `writing-plans`가 만드는 spec·plan markdown 문서는 verbose하다 (수백 줄). 사용자(30년 Java 개발자)에게는 **자연어 본문보다 Gherkin Feature(행위 중심, 간결)가 리뷰에 훨씬 효율적**이다.

**핵심 가치**: 사용자가 verbose markdown 전체를 읽지 않고도 **유스케이스의 주요 시나리오만** 행위 중심 Gherkin으로 봐서 spec/plan의 의도를 빠르게 검증·피드백할 수 있어야 한다.

이전 시도(`2026-05-16-bdd-acceptance-criteria-skill-design.md`)는 자동 호출·CLAUDE.md wiring·trial protocol·rollback까지 한 번에 도입하려다 over-engineering으로 판단되어 deferred. 본 문서는 **사용자가 명시적으로 호출하는 작은 도구 하나**만 정의한다.

---

## 2. 파이프라인

사용자가 정의한 흐름:

```
spec/plan markdown (verbose)
  → use case 목록 추출
  → use case별 primary + alternative scenarios 추출
  → 각 scenario → Gherkin Feature 변환 (기능 중심, 간결, 명확)
  → /html-review 스타일 HTML 페이지에서 리뷰 + 피드백
```

---

## 3. 도구 정의

### 3.1 형식 — Slash Command + Sub-agent

- **Slash command**: `/spec-to-feature-review <markdown-file>`
- **위치**: `~/dotfiles/.claude/commands/spec-to-feature-review.md`
- **Delegation**: 변형 A (`~/.claude/templates/delegation.md`) — 동기 + sonnet sub-agent (`spec-to-feature-review-builder`)
- **이유**: 추출 + 변환 + HTML 생성 작업이 context-heavy. main context 보호 + sonnet 추론 깊이 필요.

### 3.2 입출력

**입력**:
- 위치 인자 1개: spec/plan markdown 파일 경로 (e.g. `docs/superpowers/specs/2026-05-17-foo-design.md`)

**출력**:
1. **Gherkin `.feature` 파일** — spec 옆 `features/` 디렉토리에 저장:
   `<spec-dir>/features/<spec-basename>.feature`
   예: `docs/superpowers/specs/features/2026-05-17-foo-design.feature`
2. **HTML 리뷰 페이지** — `~/Desktop/feature-review-<spec-basename>-<YYYYMMDD>.html`
3. **브라우저 자동 열기** (`open` 명령)

### 3.3 Gherkin 형식 — 영어 키워드 + 한국어 본문

- **키워드는 영어 유지**: `Feature/Scenario/Given/When/Then/And/But`
  - Cucumber 표준 영어 키워드 호환 → 향후 도구 통합 쉬움
- **시나리오 본문은 한국어**: feature 제목, scenario 제목, Given/When/Then 문장 모두 한국어로
  - 한국 개발자 가독성 ↑ — 30년 Java 개발자가 자연어처럼 빠르게 읽기 가능
  - 도메인 용어가 영어로 옮길 때 의미 손실 방지

예시:
```gherkin
Feature: 구독 업그레이드

  Scenario: 무료 사용자가 Pro로 업그레이드한다
    Given 무료 등급 사용자가 로그인되어 있다
    When 사용자가 Pro 구독을 신청한다
    Then 5초 이내 Pro 전용 기능 접근이 가능하다
    And 결제 영수증이 사용자에게 도달한다
```

---

## 4. 동작 흐름 (sub-agent 내부)

1. **markdown 읽기**: `Read` 도구로 spec/plan 파일 전체 로드
2. **use case 식별**: 문서에서 유스케이스 후보를 추출. 휴리스틱:
   - 섹션 제목 (`##`, `###`)이 동사·기능명 형태 ("X 생성", "Y 처리", "Z 검증")
   - "유스케이스 / Use Case / 시나리오" 키워드 포함 섹션
   - acceptance criteria / Gherkin 섹션이 이미 있으면 그것을 우선
3. **scenario 추출**: 각 use case당:
   - **Primary scenario** (happy path): 정상 흐름
   - **Alternative scenarios** (sad/edge): 실패·거부·경계 조건
   - 시나리오가 명시되지 않은 use case는 spec 본문에서 추론
4. **Gherkin 변환**: 각 scenario를 Given-When-Then 형식으로 작성. **영어 키워드 + 한국어 본문** 규칙 적용 (Section 3.3). 4-point self-review (구현 세부 없음 / UI 세부 없음 / 외부 관찰 가능 / Mock 없이 검증 가능) 통과.
5. **.feature 파일 작성**: `<spec-dir>/features/` 디렉토리 생성 후 `<spec-basename>.feature` 저장
6. **HTML 리뷰 페이지 생성**:
   - `~/.claude/skills/html-review/assets/template.html` 패턴 차용 (또는 html-review-builder 호출)
   - 각 Feature/Scenario를 항목으로 변환
   - 👍채택 / 🤔의문 / 🔁수정 / ❌거절 버튼 + 코멘트 + LocalStorage 자동저장 + Markdown·next-prompt export
7. **브라우저 열기**: `open ~/Desktop/feature-review-<...>.html`

---

## 5. 기존 자산 활용

| 자산 | 활용 방식 |
|---|---|
| `html-review` skill | UI 패턴 전체 차용 (버튼, 코멘트, export) |
| `html-review-builder` sub-agent | HTML 생성 위임 가능 (또는 이 도구 sub-agent가 직접 생성) |
| `~/.claude/skills/html-review/assets/template.html` | 템플릿 재사용 |

**결정**: 이 도구의 sub-agent (`spec-to-feature-review-builder`)가 use case 추출 + Gherkin 변환 + HTML 생성을 모두 수행. `html-review-builder` 재호출하지 않음 (단순화).

---

## 6. Acceptance Criteria (Dogfooding)

이 spec 자체를 새 도구로 변환한 결과의 acceptance criteria.

```gherkin
Feature: spec/plan markdown을 리뷰 가능한 Gherkin Feature로 변환

  Scenario: 도구가 유스케이스를 추출하여 Gherkin과 HTML 리뷰를 생성한다
    Given spec 또는 plan markdown 파일이 <file> 경로에 존재한다
    When 사용자가 /spec-to-feature-review <file>을 호출한다
    Then .feature 파일이 <spec-dir>/features/<basename>.feature에 생성된다
    And .feature는 식별된 유스케이스마다 하나의 Feature를 포함한다
    And 각 Feature는 1개의 primary scenario와 ≥1개의 alternative scenario를 포함한다
    And HTML 리뷰 페이지가 브라우저에서 열린다
    And HTML 페이지는 /html-review UX를 미러링한다 (항목별 👍/🤔/🔁/❌ + 코멘트 + export)

  Scenario: 추출 가능한 유스케이스가 없을 때
    Given markdown 파일에 식별 가능한 유스케이스가 없다
    When 사용자가 /spec-to-feature-review <file>을 호출한다
    Then .feature 파일이 생성되지 않는다
    And 응답에 "유스케이스를 추출할 수 없음" 사유가 포함된다
    And 사용자에게 명확화 또는 다른 파일 제공을 요청한다

  Scenario: 사용자가 피드백을 next-prompt로 export한다
    Given HTML 리뷰 페이지가 추출된 시나리오들과 함께 열려 있다
    When 사용자가 시나리오에 👍/🤔/🔁/❌를 표시하고 "Copy as next prompt"를 클릭한다
    Then 클립보드에 시나리오별 피드백이 포함된 구조화된 프롬프트가 복사된다
    And 사용자는 이를 Claude에 붙여넣어 수정을 요청할 수 있다

  Scenario: 기존 .feature 파일은 안전하게 덮어쓴다
    Given 대상 경로에 .feature 파일이 이미 존재한다
    When 사용자가 같은 spec으로 /spec-to-feature-review를 다시 호출한다
    Then 새 .feature가 기존 파일을 대체한다
    And 응답에 한 줄로 "기존 파일 덮어씀" 안내가 포함된다
```

---

## 7. 변경 인벤토리 (3개 파일)

| 파일 | 책임 | 크기 추정 |
|---|---|---|
| `~/dotfiles/.claude/commands/spec-to-feature-review.md` | Slash command thin wrapper (변형 A delegation) | ~40줄 |
| `~/dotfiles/.claude/agents/spec-to-feature-review-builder.md` | Sub-agent (sonnet) — 추출/변환/HTML 생성 | ~150줄 |
| (선택) `~/dotfiles/.claude/skills/spec-to-feature-review/SKILL.md` | 명시적 skill 정의 — slash command + sub-agent로 충분하면 생략 | ~80줄 (선택) |

**수정 파일 0개**. CLAUDE.md 변경 없음.
**Plugin 파일 수정 없음**. Superpowers 그대로.

---

## 8. Out of Scope (명시적으로 보류)

이전 거대 spec(`2026-05-16-...`)에 있던 다음 항목은 **이번 도구에 포함하지 않는다**:

- 자동 호출 (brainstorming Step 6 이후 / writing-plans pre-flight)
- CLAUDE.md `<*-context>` wiring (3겹 redundancy)
- 1주 trial protocol + 평가 기준 + Day 0 dry-run
- rollback.sh + install marker
- Things 중간 평가 태스크 (이미 등록된 것은 그대로 유지 — 어차피 도구 검증에 활용 가능)
- Cucumber-JVM 통합 (이 도구는 `.feature` 파일만 생성. 사용자가 Java 프로젝트에서 step definitions 작성은 별도)
- Mutation Testing (Uncle Bob acceptance pipeline)
- Two-Stream Mapping (Acceptance ↔ Unit)
- Self-review 4-point의 코드화된 검증 (sub-agent prompt에 자연어 가이드로만 포함)

향후 이 도구가 효익을 입증한 후 별도 spec으로 검토.

---

## 9. 의존성 / 검증 가능성

- **Bash**: `mkdir -p`, `open <file>` 가능
- **html-review template**: `~/.claude/skills/html-review/assets/template.html` 존재 확인 필요
- **sub-agent 생성 가능 여부**: `~/.claude/templates/delegation.md` 변형 A 패턴 가능 확인됨 (기존 html-review-builder 등 다수 존재)

---

## 10. Status

- [x] Design (이 문서)
- [ ] Spec self-review
- [ ] User reviews spec
- [ ] Transition to writing-plans (구현 계획 작성)
- [ ] Implementation
- [ ] **Dogfooding**: 이 spec 자체를 새 도구로 변환하여 HTML 리뷰 — 핵심 가치 검증

---

**End of Design Spec**
