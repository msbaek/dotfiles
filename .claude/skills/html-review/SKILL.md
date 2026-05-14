---
name: html-review
description: Claude의 응답(브레인스토밍·분석·계획·결정사항 등)을 인터랙티브 HTML 리뷰 페이지로 변환. 각 항목에 👍채택/🤔의문/🔁수정/❌거절 버튼, 코멘트, LocalStorage 자동저장, Markdown·프롬프트 export 기능 포함. ~/Desktop에 저장 후 브라우저로 자동 열림.
license: MIT
metadata:
  version: "1.0"
  author: msbaek
model: sonnet
---

# HTML Interactive Review Skill

## 실행 모델 (필수)

**~/.claude/templates/delegation.md 변형 A 적용** — 단, `subagent_type`은 `general-purpose` 대신 **`html-review-builder`** 사용 (전용 sub-agent).
(model="sonnet", run_in_background=false, args=skill 호출 인자)

main context에서 직접 실행 금지.

## 개요

Claude Code의 응답·분석·계획을 dark-themed 단일 HTML 파일로 변환하는 skill.

- **각 항목**: 👍 채택 / 🤔 의문 / 🔁 수정 / ❌ 거절 버튼 + 코멘트
- **자동저장**: LocalStorage (날짜-슬러그 key)
- **Export**: Markdown / "Copy as next prompt" (피드백 → Claude 재요청)
- **저장 위치**: `~/Desktop/claude-review-{날짜}-{슬러그}.html`
- **자동 열기**: `open` 명령으로 브라우저 실행

## 사용법

| 호출 방식 | 설명 |
|----------|------|
| `/html-review` | 마지막 assistant 응답을 리뷰 페이지로 변환 |
| `/html-review <제목>` | 지정 제목으로 현재 대화 맥락 기반 리뷰 생성 |
| `/html-review @/path/to/file.md` | 파일 내용을 리뷰 페이지로 변환 |

## 위임 절차

Main context가 할 일:
1. 인자 파싱 — `@file` 이면 파일 경로, 아니면 제목/키워드 추출
2. 현재 대화 맥락(리뷰할 내용)과 함께 `html-review-builder` agent에 위임
3. agent 결과로 받은 파일 경로를 사용자에게 보고

## 위임 시 전달할 정보

```
review_title: <제목 또는 추론된 제목>
output_slug: <kebab-case 슬러그 (영어, 날짜 제외)>
content: <리뷰할 마크다운/텍스트 전문>
```

## HTML 디자인 시스템

`~/.claude/skills/html-review/assets/` 에 CSS 템플릿 저장. agent가 Read 도구로 참조.

### 색상 팔레트 (CSS variables)
- `--bg: #0a0e1a` / `--bg-elev: #131826` / `--bg-elev-2: #1a2032`
- `--accept: #10b981` / `--question: #f59e0b` / `--modify: #3b82f6` / `--reject: #ef4444`
- `--text: #e5e7eb` / `--text-dim: #9ca3af` / `--text-faint: #6b7280`

### 폰트
JetBrains Mono (monospace) + 시스템 sans-serif (Pretendard, Apple SD Gothic Neo)

### 레이아웃
- 2-column grid: 280px sidebar (TOC + filter) + main content
- sticky sidebar, bottom export bar (fixed)

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
        title: '항목 제목',
        body: `<p>항목 설명 HTML</p>`  // 신뢰된 HTML, innerHTML로 렌더링
      }
    ]
  }
];
```

## Failure Conditions

- 리뷰할 내용이 비어있거나 구조화 불가능한 경우 → 사용자에게 내용 제공 요청
- `~/Desktop/` 쓰기 권한 없음 → 에러 보고
