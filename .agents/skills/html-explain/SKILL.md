---
name: html-explain
description: 현재 세션에서 한 작업(또는 주어진 텍스트·파일)을 비전문가·미래의 자신도 이해하도록 쉽게 풀어 설명하는 인터랙티브 HTML 페이지 생성. 목차·단계별 펼침접힘·핵심요약·용어풀이 포함. ~/Desktop 저장 후 자동 오픈. 트리거: "쉽게 설명", "정리해줘", "복기", "풀어서 설명", "이해하기 쉽게", "설명해줘", "요약해줘".
license: MIT
metadata:
  version: "1.0"
  author: msbaek
model: sonnet
argument-hint: "[easy|middle|hard] [@file | text]"
---

# HTML Explain Skill

## 실행 모델 (필수)

**~/.claude/templates/delegation.md 변형 A 적용** — `subagent_type`은 **`html-explain-builder`** 사용 (전용 sub-agent).
(model="sonnet", run_in_background=false, args=skill 호출 인자)

main context에서 직접 실행 금지.

## 개요

세션 작업 내용 또는 주어진 텍스트를 쉽게 풀어 설명하는 light-themed 단일 HTML 파일을 생성하는 skill.

- **목적**: 이해·복기 (의사결정 아님)
- **UI**: 목차 / `<details>` 펼침접힘 / 핵심 요약 박스 / 용어 풀이 — 액션 버튼 없음
- **저장 위치**: `~/Desktop/claude-explain-{날짜}-{슬러그}.html`
- **자동 열기**: `open` 명령으로 브라우저 실행

## 사용법

| 호출 방식 | 설명 |
|----------|------|
| `/html-explain` | 이번 세션 작업 내용을 쉽게 풀어 설명 (depth=easy) |
| `/html-explain easy` | 초보자 수준 깊이로 세션 내용 설명 |
| `/html-explain hard` | 전문가 수준 압축 설명 |
| `/html-explain @plan.md` | 파일 내용 설명 (depth=easy) |
| `/html-explain middle @plan.md` | 파일 내용을 중간 깊이로 설명 |
| `/html-explain "오늘 한 일"` | 지정 제목으로 세션 내용 설명 |

## Argument parsing 규약

첫 번째 positional 인자가 `easy|middle|hard` 중 하나면 → **depth로 해석**.
그 외 → **title** 또는 **`@file`**로 해석. 미지정 시 → **`easy`** (default — html-review와 다름).

의도적으로 "easy"를 title로 쓰려면 `"easy way"`처럼 quote로 감쌀 것.

## 세션 캡처 책임 분담 (핵심)

**sub-agent는 현재 세션 JSONL에 접근 불가** → 인자 없이 호출하거나 `@file` 없이 호출한 경우,
**main context(= 이 skill을 실행하는 현재 컨텍스트)가** "이번 세션에서 한 일"을 직접 요약하여
`content` 필드로 html-explain-builder agent에 전달한다.

요약 방법:
1. 현재 대화에서 수행한 작업을 시간 순으로 파악
2. 주제별로 묶어서 1,000~3,000자 분량의 마크다운 텍스트로 정리
3. 이것을 `content`로 위임

`@file` 지정 시에는 파일 경로를 그대로 전달하고, agent가 직접 Read한다.

## 위임 절차

Main context가 할 일:
1. 인자 파싱 — depth / `@file` / title 추출
2. `@file` 없으면 세션 내용 직접 요약 → `content` 생성
3. `html-explain-builder` agent에 위임
4. agent 결과로 받은 파일 경로를 사용자에게 보고

## 위임 시 전달할 정보

```
explain_title: <제목 또는 추론된 제목>
output_slug:   <kebab-case 슬러그 (영어, 날짜 제외)>
depth_level:   easy | middle | hard   (미지정 시 easy)
content:       <설명할 마크다운/텍스트 전문>
```

## HTML 디자인 시스템

`~/.claude/skills/html-explain/assets/` 에 HTML 템플릿 저장. agent가 Read 도구로 참조.

### 색상 팔레트 (CSS variables) — Light theme
- `--bg: #f7f8fa` / `--bg-elev: #ffffff` / `--bg-elev-2: #f3f4f6`
- `--summary: #4f46e5` (요약 박스 — indigo) / `--glossary: #0d9488` (용어풀이 — teal)
- `--info: #0284c7` (일반 강조 — sky)
- `--text: #111827` / `--text-dim: #4b5563` / `--text-faint: #9ca3af`
- `--shadow-sm: 0 1px 2px rgba(0,0,0,0.06)` / `--shadow-md: 0 2px 8px rgba(0,0,0,0.08)`

### 폰트
JetBrains Mono (monospace) + 시스템 sans-serif (Pretendard, Apple SD Gothic Neo)

### 레이아웃
- 2-column grid: 280px sidebar (TOC) + main content
- sticky sidebar, 980px 이하 반응형

## 설명 구조 패턴

**철학**: 독자가 "무엇을 / 왜 / 어떻게"를 차례로 이해하도록 안내한다.
액션 버튼 없음 — 의사결정이 아닌 이해가 목적.

**규칙**:
1. **섹션 = 주제 단위** — 독립적으로 이해 가능해야 함
2. **항목 = 무엇+왜+어떻게** — 3단 구조
3. **요약 박스** — 각 섹션 상단에 핵심 1~2문장 (callout)
4. **용어 풀이** — 비전문가가 막힐 법한 단어는 `glossary` 항목 추가
5. **`<details>` 펼침접힘** — "어떻게" 부분은 기본 접힘으로

## EXPLAIN_DATA 구조

```js
const EXPLAIN_DATA = [
  {
    id: 's1',
    title: '주제 섹션 제목',
    summary: '이 섹션 핵심 한두 줄 (요약 박스로 렌더)',
    items: [
      {
        id: 's1-1',
        title: '무엇을 했나 (명사구)',
        body: `
          <p><b>무엇:</b> ...</p>
          <p><b>왜:</b> ...</p>
          <details><summary>어떻게 (자세히)</summary><p>...</p></details>
        `,
        glossary: [ { term: '용어', desc: '평이한 설명' } ]
      }
    ]
  }
];
```

## Depth 규칙

`depth_level`에 따라 설명 밀도·예시·비유 사용이 달라집니다.

**`easy`** (default) — 배경지식 약하다고 가정:
- 비전문 용어 인라인 정의 (괄호 또는 추가 문장)
- 비유·analogies 적극 사용
- 단계별 풀이, concrete example 포함
- glossary 항목 풍부하게

**`middle`** — working familiarity 가정:
- 비표준 용어만 정의; 표준 용어는 생략
- 설명 간결, 핵심 중심
- 예시는 의미를 강화할 때만

**`hard`** — domain expert 가정:
- 용어 정의·비유·remedial 설명 금지
- 압축 설명, jargon OK
- glossary 최소화 또는 생략

## Failure Conditions

- 설명할 내용이 비어있거나 구조화 불가능한 경우 → 사용자에게 내용 제공 요청
- `~/Desktop/` 쓰기 권한 없음 → 에러 보고
