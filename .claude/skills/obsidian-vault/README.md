# obsidian-vault

> Obsidian vault 작업 시 LSP 기반 효율적인 검색, 백링크 탐색, 태그 관리를 제공하는 스킬

## 만든 배경

CLAUDE.md에 포함되어 있던 Obsidian vault 작업 가이드(경로, 태그 체계, vault-intelligence CLI 사용법)를 독립 스킬로 추출하여 중앙 집중식 관리 및 재사용성을 높이기 위해 2026-01-06 생성. Obsidian, 마크다운, 노트 정리, Zettelkasten 관련 키워드 사용 시 자동 적용됨.

## 사용법

### 호출 방법

```bash
/obsidian-vault
```

또는 Obsidian, vault, 마크다운, 태그, 백링크, wiki-link, PKM 등의 키워드를 포함한 질문 시 자동 적용.

### 예시

```
# LSP 기반 백링크 검색
"TDD 노트를 참조하는 모든 노트 찾아줘"

# 태그 검색
"#project/active 태그가 있는 노트들 목록 보여줘"

# 시맨틱 검색
"vis search로 Kubernetes 관련 노트 10개 찾아줘"

# 깨진 링크 확인
"vault에서 깨진 링크가 있는 노트 확인해줘"
```

## 주요 기능

### 1. markdown-oxide LSP 우선 활용
- **Go to Definition**: `[[링크]]` → 해당 파일 이동
- **Find References**: 백링크 검색 (특정 노트를 참조하는 모든 노트)
- **Tag Search**: `#태그` 위치 검색
- **Diagnostics**: 깨진 링크/존재하지 않는 노트 감지
- **Completion**: 링크, 태그, 프로퍼티 자동완성

검색 우선순위: `markdown-oxide LSP` → `vis CLI` (시맨틱 검색) → `ripgrep` (단순 텍스트)

### 2. Hierarchical Tags 체계
- 형식: `#category/subcategory/detail`
- 5가지 카테고리: Topic, Document Type, Source, Status, Project
- 상세 가이드: `$VAULT_ROOT/vault-analysis/improved-hierarchical-tags-guide.md`

### 3. Zettelkasten 폴더 구조

| 폴더 | 용도 | 작업 권한 |
|------|------|-----------|
| `000-SLIPBOX` | 개인 인사이트 | 읽기/쓰기 |
| `001-INBOX` | 수집함 | 읽기/쓰기 |
| `003-RESOURCES` | 참고자료 | 주로 읽기 |
| `archive` | 보관 자료 | **접근 금지** |

### 4. vault-intelligence CLI (vis)

```bash
# 기본 사용법 (pipx 전역 설치로 어디서든 실행 가능)
vis search "검색어" --search-method hybrid --top-k 10 --rerank
```

| 옵션 | 값 | 설명 |
|------|-----|------|
| `--search-method` | semantic, keyword, hybrid, colbert | hybrid 권장 |
| `--rerank` | (플래그) | 재순위화로 정확도 향상 |
| `--expand` | (플래그) | 쿼리 확장 (동의어 + HyDE) |
| `--top-k` | 숫자 | 반환 결과 수 |

**자주 실수하는 옵션**

| ❌ 잘못된 사용 | ✅ 올바른 사용 |
|---------------|---------------|
| `--method` | `--search-method` |
| `--k` | `--top-k` |
| `--output-file` | `--output` |
| `--reranking` | `--rerank` |
| `vis search --query "TDD"` | `vis search "TDD"` (positional) |
| `vis collect --topic "TDD"` | `vis collect "TDD"` (positional) |

### 5. 토큰 최적화 전략

**작업 원칙**
1. 한 번에 10개 이하 파일 처리
2. `archive`, `.obsidian` 폴더 무시
3. MOC 노트 먼저 읽고 관련 노트만 선택적 로드
4. 20회 반복 후 `/compact` 또는 `/clear`

**효율적인 요청 패턴**
```
# ❌ 비효율적
"vault의 모든 파일을 분석해줘"

# ✅ 효율적
"003-RESOURCES에서 'kubernetes' 태그가 있는 노트 목록만 보여줘"
```

**컨텍스트 관리**

| 명령어 | 용도 | 시점 |
|--------|------|------|
| `/compact` | 히스토리 압축 | 70% 사용 시 |
| `/clear` | 초기화 | 새 작업 시작 |
| `/cost` | 토큰 확인 | 수시 |

**제외 대상**: `.obsidian/`, `archive/`, `.canvas`, 이미지 파일

## 의존성

| 도구/서비스 | 용도 |
|------------|------|
| markdown-oxide LSP | 백링크, 태그, 링크 검색 및 진단 |
| vault-intelligence (vis) | 시맨틱 검색 (`~/git/vault-intelligence/`) |
| ripgrep | 단순 텍스트 매칭 폴백 |
| `$VAULT_ROOT` | 글로벌 CLAUDE.md에서 정의된 vault 경로 |

## 참고

- vault-intelligence 상세 가이드: `~/git/vault-intelligence/CLAUDE.md`
- 태그 체계 가이드: `$VAULT_ROOT/vault-analysis/improved-hierarchical-tags-guide.md`
- 검색 도구 선택: LSP (백링크/태그) → vis (시맨틱) → ripgrep (키워드)
