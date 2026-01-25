# Obsidian Vault 작업 섹션을 Skill로 분리

## 배경

### 현재 상태
- `~/.claude/CLAUDE.md`의 "Obsidian Vault 작업" 섹션 (약 40줄)
- `~/.claude/commands/obsidian/` - 18개의 슬래시 명령어 존재
- `~/.claude/agents/obsidian-ops-team/` - 5개의 에이전트 존재
- `~/.claude/skills/` - obsidian 관련 skill **없음**

### Skills vs Commands 차이
| 구분 | Skills | Commands |
|------|--------|----------|
| 호출 | Claude가 자동 선택 (description 기반) | `/command`로 명시적 호출 |
| 용도 | 전문 지식/컨텍스트 제공 | 특정 작업 수행 |

## 분리 대상 (CLAUDE.md "Obsidian Vault 작업" 섹션)

```
## Obsidian Vault 작업

### 경로
- vault-intelligence: `~/git/vault-intelligence/`
- vault: `~/DocumentsLocal/msbaek_vault/`

### 태그 체계
- Hierarchical tags: `#category/subcategory/detail`
- 5가지 카테고리: Topic, Document Type, Source, Status, Project
- Zettelkasten: 000-SLIPBOX, 001-INBOX, 003-RESOURCES
- 상세 가이드: vault_root/vault-analysis/improved-hierarchical-tags-guide.md

### vault-intelligence CLI
(CLI 사용법, 옵션, 자주 실수하는 옵션 등)

### 파일 처리 오류 시
(오류 처리 지침)
```

## 계획

### 1. Skill 생성
**경로:** `~/.claude/skills/obsidian-vault/SKILL.md`

**구조:**
```yaml
---
name: obsidian-vault
description: Obsidian vault 작업 시 사용. vault 경로, 태그 체계, vault-intelligence CLI 사용법,
  파일 처리 지침 제공. Obsidian, vault, 태그, 노트 정리 관련 작업 시 자동 적용.
---

# Obsidian Vault 작업 가이드

## 경로
(내용)

## 태그 체계
(내용)

## vault-intelligence CLI
(내용)

## 파일 처리 오류 시
(내용)
```

### 2. CLAUDE.md에서 섹션 제거
- "## Obsidian Vault 작업" 전체 섹션 삭제 (110~146줄)

## 수정 파일
1. **생성:** `~/.claude/skills/obsidian-vault/SKILL.md`
2. **수정:** `~/.claude/CLAUDE.md` - Obsidian Vault 작업 섹션 제거

## 예상 효과
- CLAUDE.md 약 40줄 감소 → 더 간결한 글로벌 설정
- Obsidian 작업 시에만 관련 컨텍스트 로드
- 기존 commands/agents와 함께 사용 가능
