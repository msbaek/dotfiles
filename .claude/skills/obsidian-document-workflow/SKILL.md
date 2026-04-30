---
name: obsidian-document-workflow
description: |
  Use when creating or updating an Obsidian markdown document (anywhere — vault dir or other projects).
  Adds Forward Related Notes section (top-5 hybrid search results) to the document after creation.
  Triggers on: "obsidian 문서 생성", "vault에 저장", "001-INBOX에 작성", "Obsidian markdown 작성",
  "Related Notes 추가", "vault 정리 후 백링크". Backward Related Notes는 별도 vis-backlink-trigger
  스킬이 처리하므로 이 스킬은 Forward만 책임진다.
---

# Obsidian Document Workflow (Forward Related Notes)

Obsidian 문서 A를 생성·정리한 직후 자동 실행.

## Forward Related Notes 추가 절차

1. **검색**: vault-intelligence hybrid search 호출

   ```bash
   curl -s --get --data-urlencode "query=<A-title>" \
     "http://localhost:8741/search?search_method=hybrid&rerank=true&top_k=10"
   ```

   서버 미실행 시 fallback: `vis search "<A-title>" --rerank --top-k 10`

   _A-title 결정_: frontmatter `title` 필드 우선, 없으면 첫 `# 헤딩` 텍스트.

2. **선별**: 결과에서 다음 제외

   - 자기 자신 (A 문서 본인)
   - daily notes (`notes/dailies/`)
   - 관련도 점수 0 이하

3. **상위 5개 자동 추가** (사용자가 inbox 검토 시 수정하므로 별도 승인 불필요)

4. **문서 하단 형식**:

   ```markdown
   ## Related Notes

   - [[Note-Title-1]] — 한 줄 맥락 설명
   - [[Note-Title-2]] — 한 줄 맥락 설명
   ```

5. **frontmatter `related:` 필드**: 명시 요청 시에만 업데이트 (기본은 본문 섹션만 추가)

## Backward Related Notes (이 스킬 책임 아님)

Backward(다른 문서들이 A를 가리키도록)는 `/obsidian:add-tag` 또는 `/obsidian:add-tag-and-move-file`이
마지막 단계에서 `vis-backlink-trigger` 스킬로 처리한다.
상세: `~/git/vault-intelligence/docs/superpowers/specs/2026-04-26-vis-backlink-smart-trigger-design.md`
