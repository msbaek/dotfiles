# Obsidian Flavored Markdown (OFM) 규칙 — SSOT

이 파일은 vault 전체의 OFM 규약 단일 출처(SSOT)입니다.
- **LLM 소비자**: obsidian agent, shared-rules.md 가 이 파일을 텍스트 지침으로 참조한다.
- **코드 소비자**: `vis` Python 코드(`src/utils/ofm.py`)는 이 파일을 런타임 파싱하지 않는다.
  규칙을 코드로 구현하고, `tests/test_ofm.py`로 동기화를 고정한다.

---

## 1. Wikilink

**형식**: `[[folder/basename]]`
- vault root 기준 상대경로, `.md` 확장자 없음
- 절대경로 접두사(`/Users/...`) 금지
- basename만 쓰면 vault 내 중복 시 모호 → vault-relative 경로 고정
- Obsidian은 표시 시 basename만 보여줌 (경로는 소스뷰에서만 보임)
- alias 형식: `[[folder/basename|표시텍스트]]`

**예시 (vis 출력 기준)**:

| 변환 전 (비표준) | 변환 후 (표준) |
|-----------------|---------------|
| `[[/Users/msbaek/DocumentsLocal/msbaek_vault/997-BOOKS/개발자로 살아남기.md]]` | `[[997-BOOKS/개발자로 살아남기]]` |
| `[[개발자로 살아남기]]` (basename만) | `[[997-BOOKS/개발자로 살아남기]]` |
| `[[Clean Code.md]]` | `[[997-BOOKS/Clean Code]]` |

---

## 2. Frontmatter (Properties)

```yaml
---
id: 원문 제목 (영문)
aliases:
  - 한국어 제목
tags:
  - domain/subdomain/leaf
author: author-name-lowercase-hyphenated
created_at: YYYY-MM-DD HH:MM
related: []
source: https://...
---
```

- `created_at` / `updated_at`: **평문 문자열** `YYYY-MM-DD HH:MM`. `[[YYYY-MM-DD HH:mm]]` 형식(wikilink) 금지 — Obsidian이 날짜 타입으로 인식 못 함.
- `tags`: 계층형 슬래시 구분 `domain/subdomain`, 모두 소문자.
- 임시 파일 면제: `*-progress.md`, WIP 산출물 등 frontmatter 의무 없음.

---

## 3. Callout

```markdown
> [!note] 선택적 제목
> 본문 내용

> [!warning]- 접힌 callout (기본값)
> 내용
```

공통 타입: `note`, `tip`, `warning`, `info`, `example`, `quote`, `bug`, `danger`.

---

## 4. Embed

```markdown
![[folder/document]]          전체 노트 임베드
![[folder/document#섹션]]      섹션 임베드
![[image.png|400]]            이미지 임베드 (width)
```

---

## 5. 태그

- 인라인: `#domain/subdomain`
- frontmatter `tags` 배열 권장
- 숫자로 시작 금지, 공백 금지

---

## 6. vis 적용 범위 (Python `ofm.py` 구현 대상)

| OFM 요소 | vis가 생성하는가 | `ofm.py` 구현 |
|----------|----------------|--------------|
| wikilink `[[...]]` | ✅ collect/moc/related/summarize | ✅ `to_wikilink()` |
| frontmatter timestamp | ✅ 일부 출력물 | ✅ `format_frontmatter_timestamp()` |
| callout `> [!type]` | ❌ | ❌ (YAGNI) |
| embed `![[...]]` | ❌ | ❌ (YAGNI) |
| 태그 | ❌ (vis tag는 Obsidian MCP 경유) | ❌ |

---

## 7. cross-repo 동기화 (Accepted Risk)

이 파일(SSOT)은 `~/.claude/commands/obsidian/`(user-global),
Python 코드는 `vault-intelligence/`(repo)에 존재한다.
자동 동기화 트리거 없음 — SSOT 규칙 변경 시 `ofm.py`/`test_ofm.py` 수동 갱신 필요.
규칙 변경 빈도가 낮아 수용 가능한 리스크.
