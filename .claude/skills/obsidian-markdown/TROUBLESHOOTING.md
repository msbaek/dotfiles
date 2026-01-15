# Obsidian Markdown Skill - Troubleshooting

일반적인 문제와 해결 방법.

## LSP 연결 문제

### markdown-oxide가 동작하지 않음

**증상**: LSP 기능(백링크 검색 등)이 작동하지 않음

**확인 사항**:

1. **markdown-oxide 설치 확인**

   ```bash
   which markdown-oxide
   markdown-oxide --version
   ```

2. **환경 변수 확인**

   ```bash
   echo $ENABLE_LSP_TOOL
   # 1이 출력되어야 함
   ```

3. **MCP 서버 상태 확인**
   ```bash
   claude mcp list
   # markdown-oxide가 목록에 있어야 함
   ```

**해결**:

```bash
# 환경 변수 설정
export ENABLE_LSP_TOOL=1

# MCP 서버 재등록
claude mcp remove markdown-oxide
claude mcp add-json "markdown-oxide" '{
  "type": "stdio",
  "command": "npx",
  "args": ["tritlo/lsp-mcp", "markdown", "markdown-oxide"]
}'

# Claude Code 재시작
```

### "Executable not found" 오류

**원인**: markdown-oxide 바이너리가 PATH에 없음

**해결**:

```bash
# Homebrew 설치 경로 확인
brew --prefix markdown-oxide

# PATH에 추가 (필요시)
export PATH="/opt/homebrew/bin:$PATH"

# 또는 절대 경로 사용
claude mcp add-json "markdown-oxide" '{
  "type": "stdio",
  "command": "npx",
  "args": ["tritlo/lsp-mcp", "markdown", "/opt/homebrew/bin/markdown-oxide"]
}'
```

### tritlo/lsp-mcp 오류

**증상**: npx 실행 시 오류

**해결**:

```bash
# 캐시 클리어
npx clear-npx-cache

# 직접 설치
npm install -g @anthropic/lsp-mcp

# 로컬 설치 후 사용
npm install tritlo/lsp-mcp
claude mcp add-json "markdown-oxide" '{
  "type": "stdio",
  "command": "node",
  "args": ["./node_modules/tritlo/lsp-mcp/bin/cli.js", "markdown", "markdown-oxide"]
}'
```

## Vault 인식 문제

### Multi-file 모드 비활성화

**증상**: 다른 파일의 링크가 인식되지 않음

**원인**: `.moxide.toml` 또는 `.marksman.toml` 없음

**해결**:

```bash
# vault 루트에 설정 파일 생성
touch /path/to/vault/.moxide.toml
```

### 특정 폴더가 무시됨

**확인**: `.moxide.toml`의 ignore 설정

```toml
# .moxide.toml
ignore = [
  ".git",
  ".obsidian",
  # 이 목록에 있는 폴더는 무시됨
]
```

### Daily Notes 인식 안됨

**원인**: 날짜 형식 불일치

**해결**:

```toml
# .moxide.toml
# 실제 사용하는 형식으로 변경
dailynote = "%Y-%m-%d"  # 2025-01-13
# 또는
dailynote = "%Y/%m/%d"  # 2025/01/13
```

## 검색 문제

### 백링크가 일부만 찾아짐

**가능한 원인**:

1. 별칭(alias)으로 링크된 경우
2. 대소문자 불일치
3. 확장자 포함/미포함 차이

**해결**: 수동 검색 병행

```bash
# 모든 변형 검색
grep -riE "\[\[(노트명|Alias1|alias2)\]\]" --include="*.md" .
```

### 태그 검색 누락

**원인**: frontmatter 태그와 인라인 태그 형식 차이

**해결**:

```bash
# 두 형식 모두 검색
grep -rE "(^tags:.*태그|#태그)" --include="*.md" .
```

### 검색이 너무 느림

**원인**: vault 크기가 너무 크거나 인덱싱 문제

**해결**:

1. 불필요한 폴더 제외 (`.moxide.toml`)
2. LSP 서버 재시작
3. 특정 폴더로 범위 한정
   ```bash
   grep -r "검색어" --include="*.md" ./specific-folder/
   ```

## 토큰 관련 문제

### 세션이 너무 빨리 종료됨

**원인**: 대량 파일 로드로 컨텍스트 소진

**해결**:

1. `/compact` 자주 실행
2. 한 번에 로드하는 파일 수 제한
3. MOC 우선 접근 방식 사용
4. Repomix로 사전 요약 생성

### "/compact 후에도 컨텍스트 부족"

**해결**:

```bash
# 새 세션 시작
/clear

# 또는 Claude Code 재시작
exit
claude
```

## Skill 인식 문제

### Skill이 자동으로 활성화되지 않음

**확인 사항**:

1. **파일 위치 확인**

   ```bash
   ls ~/.claude/skills/obsidian-markdown/SKILL.md
   # 또는
   ls .claude/skills/obsidian-markdown/SKILL.md
   ```

2. **YAML 문법 검증**

   ```bash
   head -20 ~/.claude/skills/obsidian-markdown/SKILL.md
   # --- 로 시작하고 --- 로 닫혀야 함
   ```

3. **description 확인**
   - "obsidian", "markdown", "vault" 등 트리거 키워드 포함 여부

**해결**:

```bash
# Skill 다시 로드
# Claude Code 재시작
exit
claude
```

### 다른 Skill과 충돌

**증상**: 의도한 것과 다른 Skill이 활성화됨

**해결**: description을 더 구체적으로 수정

```yaml
# 너무 일반적
description: 마크다운 작업

# 구체적
description: Obsidian vault의 마크다운 문서 작업을 위한 Skill.
백링크 검색, 태그 탐색, 위키링크([[link]]) 분석 시 사용.
```

## 플랫폼별 문제

### macOS

**Homebrew 경로 문제** (Apple Silicon):

```bash
# PATH 확인
echo $PATH | grep homebrew

# 없으면 추가
export PATH="/opt/homebrew/bin:$PATH"
```

### Linux

**권한 문제**:

```bash
# 실행 권한 확인
chmod +x $(which markdown-oxide)
```

### Windows (WSL)

**경로 변환 문제**:

```bash
# Windows 경로 대신 WSL 경로 사용
/mnt/c/Users/... → ~/...
```

## 디버그 모드

문제 원인 파악을 위한 디버그:

```bash
# Claude Code 디버그 모드
claude --debug

# LSP 서버 로그 확인
RUST_LOG=debug markdown-oxide 2>&1 | tee lsp.log
```

## 도움 요청

위 방법으로 해결되지 않을 경우:

1. **GitHub Issues**

   - [markdown-oxide](https://github.com/Feel-ix-343/markdown-oxide/issues)
   - [Claude Code](https://github.com/anthropics/claude-code/issues)

2. **커뮤니티**

   - Anthropic Discord
   - Obsidian Forum

3. **정보 수집**

   ```bash
   # 버전 정보
   claude --version
   markdown-oxide --version
   node --version

   # 환경 정보
   echo $ENABLE_LSP_TOOL
   claude mcp list
   ```
