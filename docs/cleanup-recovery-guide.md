# Skill & MCP 정리 복구 가이드

> 작업 브랜치: `chore/cleanup-skill-mcp-2026-04-29`
> 작업 완료일: 2026-04-29
> 목적: 2026-04-29 정리 작업 시 제거한 항목을 개별 복구하기 위한 참고 문서

---

## 빠른 복구 방법 (git)

특정 커밋에서 개별 파일/디렉토리를 꺼내오는 방법:

```bash
# 특정 스킬 하나 복구 (예: jira)
git checkout 40ec01e -- .claude/skills/jira

# 특정 MCP 설정 복구 (settings.json 통째로는 위험 — 개별 항목 수동 추가 권장)
git show 1b10655:.claude/settings.json | jq '.mcpServers'

# 브랜치 전체 내역 확인
git log chore/cleanup-skill-mcp-2026-04-29 --oneline
```

커밋 해시 참고:
- `1b10655` — MCP 정리 (playwright 중복/CodeGraphContext/databricks/browser-server/markdown-oxide)
- `181b80b` — Plugin 정리 (11개 비활성화)
- `40ec01e` — 로컬 스킬 37개 제거

---

## 제거 항목 목록

### MCP 서버

| 항목 | 위치 | 제거 이유 | 복구 방법 |
|------|------|---------|---------|
| playwright (http://localhost:8931) | `~/.claude/settings.json` + `dotfiles/.claude/settings.json` | `dotfiles/.claude/mcp.json`의 npx 방식과 중복 | settings.json mcpServers에 재추가 |
| CodeGraphContext | `~/.claude/settings.json` | 사용 기록 없음 (DORMANT) | `cgc mcp start` 방식으로 재추가 |
| databricks | `~/.claude/settings.json` | 사용 기록 없음 (DORMANT) | `~/.ai-dev-kit/repo/.mcp.json` 원본 참고 |
| browser-server | `~/bin/.mcp.json` | binary 없음 (DEAD) | `pip install browser-use-mcp-server` 후 재추가 |
| markdown-oxide | `~/DocumentsLocal/msbaek_vault/.mcp.json` | 사용 기록 없음 (DORMANT) | `npx tritlo/lsp-mcp` 방식으로 재추가 |

**현재 활성 MCP**: `dotfiles/.claude/mcp.json`의 playwright (npx 방식) — 이것만 유지 중

### Plugins (비활성화, 삭제 아님)

settings.json `enabledPlugins`에서 `false`로 설정한 항목들. 다시 `true`로 바꾸면 즉시 복구.

| Plugin | 비활성화 이유 |
|--------|------------|
| `rust-analyzer@claude-code-lsps` | Rust 프로젝트 미사용 |
| `kotlin-lsp@claude-plugins-official` | `kotlin-lsp@claude-code-lsps`와 중복 |
| `github@claude-plugins-official` | `gh` CLI로 충분 |
| `feature-dev@claude-plugins-official` | superpowers로 대체 |
| `explanatory-output-style@claude-plugins-official` | 미사용 |
| `greptile@claude-plugins-official` | 미사용 |
| `Notion@claude-plugins-official` | 미사용 |
| `learning-output-style@claude-plugins-official` | 미사용 |
| `agent-architecture@context-engineering-marketplace` | 미사용 |
| `agent-evaluation@context-engineering-marketplace` | 미사용 |
| `agent-development@context-engineering-marketplace` | 미사용 |
| `cognitive-architecture@context-engineering-marketplace` | 미사용 |
| `ralph-loop@claude-plugins-official` | 미사용 |

복구: `~/.claude/settings.json`에서 해당 항목을 `false` → `true`로 수정.

### 로컬 스킬 (git rm으로 삭제)

commit `40ec01e`에서 복구 가능.

#### Group A — databricks-* (26개)

```bash
# 전체 복구
git checkout 40ec01e -- .claude/skills/databricks-academy
git checkout 40ec01e -- .claude/skills/databricks-agent-bricks
git checkout 40ec01e -- .claude/skills/databricks-aibi-dashboards
git checkout 40ec01e -- .claude/skills/databricks-app-apx
git checkout 40ec01e -- .claude/skills/databricks-app-python
git checkout 40ec01e -- .claude/skills/databricks-bundles
git checkout 40ec01e -- .claude/skills/databricks-config
git checkout 40ec01e -- .claude/skills/databricks-dbsql
git checkout 40ec01e -- .claude/skills/databricks-docs
git checkout 40ec01e -- .claude/skills/databricks-genie
git checkout 40ec01e -- .claude/skills/databricks-iceberg
git checkout 40ec01e -- .claude/skills/databricks-jobs
git checkout 40ec01e -- .claude/skills/databricks-lakebase-autoscale
git checkout 40ec01e -- .claude/skills/databricks-lakebase-provisioned
git checkout 40ec01e -- .claude/skills/databricks-metric-views
git checkout 40ec01e -- .claude/skills/databricks-mlflow-evaluation
git checkout 40ec01e -- .claude/skills/databricks-model-serving
git checkout 40ec01e -- .claude/skills/databricks-python-sdk
git checkout 40ec01e -- .claude/skills/databricks-spark-declarative-pipelines
git checkout 40ec01e -- .claude/skills/databricks-spark-structured-streaming
git checkout 40ec01e -- .claude/skills/databricks-synthetic-data-gen
git checkout 40ec01e -- .claude/skills/databricks-unity-catalog
git checkout 40ec01e -- .claude/skills/databricks-unstructured-pdf-generation
git checkout 40ec01e -- .claude/skills/databricks-vector-search
git checkout 40ec01e -- .claude/skills/databricks-zerobus-ingest
git checkout 40ec01e -- .claude/skills/databricks-ai-functions
```

#### Group B — mlflow/spark (8개)

```bash
git checkout 40ec01e -- .claude/skills/analyze-mlflow-chat-session
git checkout 40ec01e -- .claude/skills/analyze-mlflow-trace
git checkout 40ec01e -- .claude/skills/instrumenting-with-mlflow-tracing
git checkout 40ec01e -- .claude/skills/mlflow-onboarding
git checkout 40ec01e -- .claude/skills/querying-mlflow-metrics
git checkout 40ec01e -- .claude/skills/retrieving-mlflow-traces
git checkout 40ec01e -- .claude/skills/searching-mlflow-docs
git checkout 40ec01e -- .claude/skills/spark-python-data-source
```

#### Group C — 기타 (3개)

```bash
git checkout 40ec01e -- .claude/skills/agent-evaluation
git checkout 40ec01e -- .claude/skills/jira
# find-session-workspace: 개발 실험 공간이었으므로 복구 불필요
```

---

## 보존한 스킬 현황 (참고)

| 카테고리 | 스킬 목록 |
|---------|---------|
| 세션 검색 | `find-session`, `agf` |
| 문서 연결 | `vis-backlink-trigger`, `vis-backlink-status` |
| Vault | `vis`, `obsidian-jobs`, `obsidian-vault`, `capture-research` |
| Git/GitHub | `gh`, `find-skills` (symlink), `skillify` (symlink) |
| 글쓰기 | `humanize-korean`, `write-in-my-voice`, `brunch-writer`, `weekly-newsletter` |
| 개발 | `extract-sql-log`, `architecture-diagram`, `react-best-practices` |
| 생산성 | `recall`, `graphify`, `prompt-contracts`, `claude-code-release-tracker` |
| 기타 | `session-handoff`, `daily-work-logger`, `dr-jskill` (symlink) |
