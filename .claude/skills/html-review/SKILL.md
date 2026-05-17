---
name: html-review
description: Claude의 응답(브레인스토밍·분석·계획·결정사항 등)을 인터랙티브 HTML 리뷰 페이지로 변환. 각 항목에 👍채택/🤔의문/🔁수정/❌거절 버튼, 코멘트, LocalStorage 자동저장, Markdown·프롬프트 export 기능 포함. ~/Desktop에 저장 후 브라우저로 자동 열림.
license: MIT
metadata:
  version: "1.0"
  author: msbaek
model: sonnet
argument-hint: "[easy|middle|hard] [@file | title]"
---

# HTML Interactive Review Skill

## 실행 모델 (필수)

**~/.claude/templates/delegation.md 변형 A 적용** — 단, `subagent_type`은 `general-purpose` 대신 **`html-review-builder`** 사용 (전용 sub-agent).
(model="sonnet", run_in_background=false, args=skill 호출 인자)

main context에서 직접 실행 금지.

## 개요

Claude Code의 응답·분석·계획을 light-themed 단일 HTML 파일로 변환하는 skill.

- **각 항목 = 결정 1건 + 객관식 옵션 리스트** (정확히 하나에 ✅ 권장 마크)
- **버튼 의미**: 👍 권장안 채택 / 🤔 다른 옵션 (코멘트에 라벨) / 🔁 옵션 자체 수정 / ❌ 전부 거절
- **자동저장**: LocalStorage (날짜-슬러그 key)
- **Export**: Markdown / "Copy as next prompt" (피드백 → Claude 재요청)
- **저장 위치**: `~/Desktop/claude-review-{날짜}-{슬러그}.html`
- **자동 열기**: `open` 명령으로 브라우저 실행

## 사용법

| 호출 방식 | 설명 |
|----------|------|
| `/html-review` | 마지막 assistant 응답을 리뷰 페이지로 변환 (depth=middle) |
| `/html-review easy` | 초보자용 깊이로 마지막 응답을 리뷰 |
| `/html-review hard @plan.md` | 전문가용 깊이로 파일 내용 리뷰 |
| `/html-review middle "My Review"` | 중간 깊이로 지정 제목 리뷰 |
| `/html-review <제목>` | 지정 제목으로 현재 대화 맥락 기반 리뷰 (depth=middle) |
| `/html-review @/path/to/file.md` | 파일 내용을 리뷰 (depth=middle) |

## Argument parsing 규약

첫 번째 positional 인자가 `easy|middle|hard` 중 하나면 → **depth로 해석**.
그 외 → 기존처럼 **title** 또는 **`@file`**로 해석. 미지정 시 → `middle` (default).

의도적으로 "easy"를 title로 쓰려면 `"easy way"`처럼 quote로 감쌀 것. agent는
첫 인자가 unquoted bare word `easy|middle|hard`인 경우에만 depth로 해석합니다.

## 위임 절차

Main context가 할 일:
1. 인자 파싱 — `@file` 이면 파일 경로, 아니면 제목/키워드 추출
2. 현재 대화 맥락(리뷰할 내용)과 함께 `html-review-builder` agent에 위임
3. agent 결과로 받은 파일 경로를 사용자에게 보고

## 위임 시 전달할 정보

```
review_title: <제목 또는 추론된 제목>
output_slug:  <kebab-case 슬러그 (영어, 날짜 제외)>
depth_level:  easy | middle | hard   (미지정 시 middle)
content:      <리뷰할 마크다운/텍스트 전문>
```

## HTML 디자인 시스템

`~/.claude/skills/html-review/assets/` 에 CSS 템플릿 저장. agent가 Read 도구로 참조.

### 색상 팔레트 (CSS variables) — Light theme
- `--bg: #f7f8fa` / `--bg-elev: #ffffff` / `--bg-elev-2: #f3f4f6`
- `--accept: #059669` / `--question: #d97706` / `--modify: #4f46e5` / `--reject: #dc2626`
- `--text: #111827` / `--text-dim: #4b5563` / `--text-faint: #9ca3af`
- `--shadow-sm: 0 1px 2px rgba(0,0,0,0.06)` / `--shadow-md: 0 2px 8px rgba(0,0,0,0.08)`

### 폰트
JetBrains Mono (monospace) + 시스템 sans-serif (Pretendard, Apple SD Gothic Neo)

### 레이아웃
- 2-column grid: 280px sidebar (TOC + filter) + main content
- sticky sidebar, bottom export bar (fixed)

## 객관식 결정 패턴 (필수)

**철학**: reviewer가 의사결정 비용을 부담하지 않도록 작성자(agent)가 trade-off를 _옵션화_하고 추천 마크를 박는다. reviewer가 작성자를 신뢰하면 👍 한 번에 끝.

**규칙 (agent가 지켜야 함)**:

1. **각 item = 결정 1건** — yes/no 또는 A/B/C 중 택1.
2. **본문 구조** — 1문장 결정 컨텍스트 + 옵션 리스트 (`<ol class="options">`).
3. **권장 마크** — 옵션 중 정확히 하나에 `class="recommended"` + `<span class="rec-mark">✅ 권장</span>` + 1문장 근거.
4. **자명한 항목** — 옵션 1개만 (= 권장안). reviewer는 👍로 즉시 채택.
5. **Self-contained** — "Section X 참조", "위 표 참조" 금지. 각 항목 안에서 완결.
6. **분석/메타 흡수** — trade-off는 옵션 본문에 흡수하거나 별도 결정 항목으로 분리.

**reviewer가 답하는 방식**:
- 👍 = 권장안 그대로 채택 (코멘트 불필요)
- 🤔 = 다른 옵션 선택 — 코멘트에 라벨만 (예: "B")
- 🔁 = 옵션 자체 수정 요청 — 코멘트로 어떻게
- ❌ = 전부 거절

## REVIEW_DATA 구조

```js
const REVIEW_DATA = [
  {
    id: 's1',
    title: '섹션 제목',
    lede: '섹션 한 줄 요약',
    items: [
      {
        id: 's1-1',
        title: '항목 제목 (결정 명사구)',
        body: `
          <p>결정 컨텍스트 1문장.</p>
          <ol class="options">
            <li class="option recommended">
              <span class="rec-mark">✅ 권장</span>
              <b>A:</b> 옵션 본문. <i>근거 1문장.</i>
            </li>
            <li class="option"><b>B:</b> 대안 본문.</li>
          </ol>
        `
      }
    ]
  }
];
```

## Failure Conditions

- 리뷰할 내용이 비어있거나 구조화 불가능한 경우 → 사용자에게 내용 제공 요청
- `~/Desktop/` 쓰기 권한 없음 → 에러 보고
