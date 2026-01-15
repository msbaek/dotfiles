# Obsidian Markdown Skill - Reference

상세 설정 및 고급 기능 가이드.

## MCP 서버 설정 상세

### markdown-oxide 설치

#### macOS (Homebrew)

```bash
brew install markdown-oxide
```

#### Cargo (크로스 플랫폼)

```bash
cargo install --locked markdown-oxide
```

#### 바이너리 다운로드

[GitHub Releases](https://github.com/Feel-ix-343/markdown-oxide/releases)에서 직접 다운로드.

### Claude Code MCP 연결

#### 방법 1: CLI 명령어

```bash
claude mcp add-json "markdown-oxide" '{
  "type": "stdio",
  "command": "npx",
  "args": ["tritlo/lsp-mcp", "markdown", "markdown-oxide"]
}'
```

#### 방법 2: 설정 파일 직접 편집

`~/.config/claude/settings.json` 또는 프로젝트의 `.claude/settings.json`:

```json
{
  "mcpServers": {
    "markdown-oxide": {
      "type": "stdio",
      "command": "npx",
      "args": ["tritlo/lsp-mcp", "markdown", "markdown-oxide"]
    }
  }
}
```

#### 방법 3: cclsp 사용 (대안)

```bash
npm install -g cclsp
```

`~/.config/cclsp/config.json`:

```json
{
  "servers": {
    "md": {
      "command": "markdown-oxide",
      "args": [],
      "filetypes": ["md", "markdown"]
    }
  }
}
```

### 환경 변수

```bash
# LSP 기능 활성화 (필수)
export ENABLE_LSP_TOOL=1

# 영구 설정 (~/.zshrc 또는 ~/.bashrc에 추가)
echo 'export ENABLE_LSP_TOOL=1' >> ~/.zshrc
```

## markdown-oxide 설정

### .moxide.toml

vault 루트에 생성:

```toml
# Daily notes 형식
dailynote = "%Y-%m-%d"

# 기본 헤딩 레벨 (완성 시)
heading_level = 2

# 코드블록 내 태그 무시
tags_in_codeblocks = false

# 무시할 폴더
ignore = [
  ".git",
  ".obsidian",
  "node_modules",
  ".trash"
]
```

### Daily Notes 형식 옵션

| 형식             | 결과 예시          |
| ---------------- | ------------------ |
| `%Y-%m-%d`       | 2025-01-13         |
| `%Y/%m/%Y-%m-%d` | 2025/01/2025-01-13 |
| `%Y-W%W`         | 2025-W02 (주간)    |

## LSP 기능 상세

### Find References (백링크)

특정 노트를 참조하는 모든 위치 검색.

**사용 시나리오**:

- 노트 삭제 전 영향 범위 파악
- 개념의 사용 빈도 분석
- 리팩토링 대상 식별

**LSP 불가 시 대안**:

```bash
# 기본 검색
grep -r "\[\[노트명\]\]" --include="*.md" .

# 별칭 포함 검색
grep -rE "\[\[(노트명|별칭1|별칭2)\]\]" --include="*.md" .
```

### Go to Definition

`[[링크]]`에서 실제 파일 위치로 이동.

**처리 우선순위**:

1. 정확한 파일명 매칭
2. aliases 매칭
3. 대소문자 무시 매칭

### Completion

링크, 태그, 헤딩 자동완성.

**완성 대상**:

- `[[` 입력 시: 노트 목록
- `#` 입력 시: 태그 목록
- `[[노트#` 입력 시: 해당 노트의 헤딩 목록

### Diagnostics

문제 감지 및 경고.

**감지 항목**:

- 깨진 링크 (존재하지 않는 노트)
- 중복 헤딩 (같은 노트 내)
- 순환 참조 (A→B→C→A)

## 고급 검색 패턴

### 복합 태그 검색

```bash
# 특정 태그 조합
grep -l "#project" *.md | xargs grep -l "#status/active"

# 태그 계층 검색
grep -r "#project/" --include="*.md" .
```

### 날짜 범위 검색

```bash
# 최근 7일 수정된 노트
find . -name "*.md" -mtime -7

# 특정 월의 daily notes
find . -name "2025-01-*.md"

# 올해 생성된 노트
find . -name "*.md" -newermt "2025-01-01"
```

### 프로퍼티 기반 검색

```bash
# 특정 태그가 frontmatter에 있는 노트
grep -l "^tags:" *.md | xargs grep -l "  - project"

# created 날짜로 검색
grep -r "^created: 2025-01" --include="*.md" .
```

### 링크 패턴 분석

```bash
# 가장 많이 링크된 노트 찾기
grep -roh "\[\[[^]]*\]\]" --include="*.md" . | sort | uniq -c | sort -rn | head -20

# 외부 링크 찾기
grep -rE "https?://" --include="*.md" .

# 이미지 임베드 찾기
grep -r "!\[\[" --include="*.md" .
```

## 대량 작업 패턴

### 일괄 태그 변경

```bash
# 태그 이름 변경 (dry-run)
grep -rl "#old-tag" --include="*.md" .

# 실제 변경 (주의!)
find . -name "*.md" -exec sed -i '' 's/#old-tag/#new-tag/g' {} +
```

### 링크 일괄 업데이트

```bash
# 파일명 변경 후 링크 업데이트
find . -name "*.md" -exec sed -i '' 's/\[\[Old Name\]\]/[[New Name]]/g' {} +
```

### 고아 노트 찾기

어디서도 참조되지 않는 노트:

```bash
# 모든 노트 목록
find . -name "*.md" -printf "%f\n" | sed 's/.md$//' > all_notes.txt

# 참조된 노트 목록
grep -roh "\[\[[^]|#]*" --include="*.md" . | sed 's/\[\[//' | sort -u > linked_notes.txt

# 차집합 (고아 노트)
comm -23 <(sort all_notes.txt) <(sort linked_notes.txt)
```

## 성능 최적화

### 대용량 vault 팁

1. **무시 패턴 설정**: `.moxide.toml`에 불필요한 폴더 제외
2. **증분 검색**: 전체 검색 대신 특정 폴더 한정
3. **캐시 활용**: LSP 서버 재시작 최소화

### 토큰 절약 팁

1. **MOC 우선 접근**: 전체 구조 파악 후 필요 노트만 로드
2. **요약 요청**: 전체 내용 대신 구조/개요만 요청
3. **청크 단위 작업**: 한 번에 처리할 파일 수 제한

## 다른 도구와 연계

### Repomix로 vault 요약

```bash
# 마크다운만 압축
repomix --compress --include "**/*.md" --ignore "**/archive/**" -o vault-summary.xml

# 토큰 수 확인
wc -w vault-summary.xml
```

### GitIngest 활용

```bash
# vault를 LLM 친화적 형식으로 변환
gitingest /path/to/vault --output vault-digest.txt
```

## 버전 호환성

| 도구           | 최소 버전 | 권장 버전 |
| -------------- | --------- | --------- |
| Claude Code    | 2.0.74+   | 최신      |
| markdown-oxide | 0.22+     | 최신      |
| Node.js        | 18+       | 20+       |
| tritlo/lsp-mcp | 0.1+      | 최신      |

## 참고 자료

- [markdown-oxide 공식 문서](https://github.com/Feel-ix-343/markdown-oxide)
- [Claude Code Skills 가이드](https://code.claude.com/docs/en/skills)
- [MCP 프로토콜](https://code.claude.com/docs/en/mcp)
- [tritlo/lsp-mcp](https://github.com/tritlo/lsp-mcp)
