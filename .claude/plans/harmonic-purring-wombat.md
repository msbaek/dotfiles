# MCP 서버 오류 해결 계획

## 문제 요약

| MCP 서버 | 상태 | 원인 | 해결 방법 |
|----------|------|------|-----------|
| **jdtls** | 실패 | MCP 설정 오류 | MCP 설정 제거, 플러그인 사용 |
| **markdown-oxide** | 실패 | `tritlo/lsp-mcp` 미설치 | 직접 바이너리 호출로 변경 |

---

## 실행 계획

### Step 1: markdown-oxide 설정 수정

**파일**: `/Users/msbaek/.claude/claude_desktop_config.json`

**현재 (줄 90-93)**:
```json
"markdown-oxide": {
  "command": "npx",
  "args": ["tritlo/lsp-mcp", "markdown", "markdown-oxide"]
}
```

**변경**:
```json
"markdown-oxide": {
  "command": "/opt/homebrew/bin/markdown-oxide"
}
```

---

### Step 2: jdtls MCP 설정 제거

**파일**: `/Users/msbaek/.claude/claude_desktop_config.json`

**현재 (줄 94-101)** - 삭제:
```json
"jdtls": {
  "type": "stdio",
  "command": "jdtls",
  "args": ["--JVMarg=-Dosgi.requiredJavaVersion=11", "--JVMarg=-Xmx1G"],
  "env": {
    "WORKSPACE": "${CLAUDE_WORKSPACE}"
  }
}
```

> jdtls는 `jdtls-lsp@claude-plugins-official` 플러그인으로 사용 (이미 활성화됨)

---

### Step 3: 검증

```bash
# Claude Code 재시작 후
/mcp
```

**예상 결과**:
- `markdown-oxide`: 정상 연결
- `jdtls`: 목록에서 제거됨 (플러그인으로 대체)

---

## 수정 파일 목록

| 파일 | 수정 내용 |
|------|-----------|
| `~/.claude/claude_desktop_config.json` | markdown-oxide 설정 변경, jdtls 설정 제거 |

---

## Uncertainty Map

| 항목 | 신뢰도 | 비고 |
|------|--------|------|
| markdown-oxide 해결 | 높음 | 바이너리 존재 확인됨 |
| jdtls 플러그인 동작 | 중간 | 플러그인 정상 작동 가정 |
