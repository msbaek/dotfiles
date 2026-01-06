---
name: obsidian-vault
description: Obsidian vault 작업 시 사용. vault 경로, 태그 체계, vault-intelligence CLI 사용법,
  파일 처리 지침 제공. Obsidian, vault, 태그, 노트 정리, zettelkasten 관련 작업 시 자동 적용.
---

# Obsidian Vault 작업 가이드

## 경로

- vault-intelligence: `~/git/vault-intelligence/`
- vault: `~/DocumentsLocal/msbaek_vault/`

## 태그 체계

- Hierarchical tags: `#category/subcategory/detail`
- 5가지 카테고리: Topic, Document Type, Source, Status, Project
- Zettelkasten: 000-SLIPBOX (개인 인사이트), 001-INBOX (수집), 003-RESOURCES (참고자료)
- 상세 가이드: vault_root/vault-analysis/improved-hierarchical-tags-guide.md

## vault-intelligence CLI

```bash
cd ~/git/vault-intelligence
python -m src search --query "검색어" --search-method hybrid --top-k 10
```

**주요 옵션:**
- `--search-method`: semantic | keyword | hybrid (권장) | colbert
- `--rerank`: 재순위화로 정확도 향상
- `--expand`: 쿼리 확장 (동의어 + HyDE)

**자주 실수하는 옵션:**

| 잘못된 옵션 | 올바른 옵션 |
|------------|------------|
| `--method` | `--search-method` |
| `--k` | `--top-k` |
| `--output-file` | `--output` |
| `--reranking` | `--rerank` |

**상세 가이드:** ~/git/vault-intelligence/CLAUDE.md

## 파일 처리 오류 시

- 읽기 오류 파일은 UNPROCESSED-FILES.md에 기록
- Canvas 파일(.canvas)과 이미지 파일은 태그 적용 제외
