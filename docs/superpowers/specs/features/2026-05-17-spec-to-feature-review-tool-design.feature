# Generated from docs/superpowers/specs/2026-05-17-spec-to-feature-review-tool-design.md by /spec-to-feature-review on 2026-05-17
# 영어 키워드 + 한국어 본문 규칙 적용.
# 주의: 이 도구는 리뷰 가독성을 우선하여 여러 Feature 블록을 단일 파일에 직렬화한다.
#       Cucumber/Behave 등 일부 runner는 single-feature-per-file을 전제하므로,
#       실행이 필요하면 사용자가 use case별로 별도 파일로 분리해야 한다.

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
