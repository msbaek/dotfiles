---
description: spec/plan markdown 문서에서 use case별 Gherkin Feature 파일을 추출하고 인터랙티브 HTML 리뷰 페이지를 생성. 영어 Gherkin 키워드 + 한국어 본문.
argument-hint: <markdown-file-path>
allowed-tools: [Read, Write, Edit, Bash, Agent]
---

# spec-to-feature-review

spec/plan markdown(verbose) → use case 추출 → primary + alternative scenarios → Gherkin Feature 변환 → /html-review 스타일 인터랙티브 리뷰 페이지.

## 실행 모델 (필수)

**~/.claude/templates/delegation.md 변형 A 적용** — 단, `subagent_type`은 `general-purpose` 대신 **`spec-to-feature-review-builder`** 사용 (전용 sub-agent).
(model="sonnet", run_in_background=false, args=`$ARGUMENTS`)

main context에서 직접 실행 금지.

## 사용법

| 호출 방식 | 설명 |
|---|---|
| `/spec-to-feature-review <markdown-path>` | 지정 spec/plan 파일에서 Gherkin 추출 + HTML 리뷰 페이지 생성 |

예시:
```
/spec-to-feature-review docs/superpowers/specs/2026-05-17-foo-design.md
/spec-to-feature-review docs/superpowers/plans/2026-05-17-foo.md
```

## 위임 절차

Main context가 할 일:

1. `$ARGUMENTS`에서 첫 positional 인자를 `markdown_path`로 추출.
2. 인자가 없으면 사용자에게 파일 경로 요청 후 종료.
3. `spec-to-feature-review-builder` agent에 위임:
   - `subagent_type`: `spec-to-feature-review-builder` (전용 agent)
   - `model`: `sonnet`
   - `run_in_background`: false
   - prompt: `markdown_path: <추출한 경로>`
4. agent 결과를 그대로 사용자에게 보고.

## 위임 시 전달할 정보

```
markdown_path: <첫 positional 인자>
```

## 산출물

- `<spec-dir>/features/<basename>.feature` — Gherkin Feature 파일
- `~/Desktop/feature-review-<basename>-<YYYY-MM-DD>.html` — 인터랙티브 리뷰 페이지

## Failure Conditions

- 인자 미제공 → 사용자에게 파일 경로 요청
- 그 외 모든 실패는 sub-agent의 Failure Conditions 그대로 보고
