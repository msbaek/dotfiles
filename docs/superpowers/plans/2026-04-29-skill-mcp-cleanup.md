# Skill & MCP 정리 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task (inline execution 권장 — Task 2/4/6에서 사용자 라벨링 CHECKPOINT가 있음). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 불필요한 MCP 서버·Plugin·로컬 Skill을 제거하여 세션 시작 토큰을 절감하고, dead/stale 항목을 제거해 유지보수성을 높인다.

**Architecture:** 3단계 순차 실행 (MCP → Plugin → 로컬 Skill). 각 단계는 audit 테이블을 사용자에게 제시하고 라벨링 후 실행. 모든 제거 항목은 복구 가이드에 기록.

**Tech Stack:** bash, python3, jq, git

---

## 사전 파악된 현황 (audit 참고용)

### MCP 서버 현황

| 서버명 | 등록 위치 | 명령/URL | 비고 |
|--------|----------|---------|------|
| playwright | `~/.claude/settings.json` | http://localhost:8931/mcp | obsidian-summarize 핵심 |
| playwright | `dotfiles/.claude/settings.json` | 위와 동일 | 위와 중복 |
| playwright | `dotfiles/.claude/mcp.json` | npx @playwright/mcp@latest | 별개 형태 (3중) |
| CodeGraphContext | `~/.claude/settings.json` | cgc mcp start | 사용 기록 없음 |
| CodeGraphContext | `dotfiles/.claude/settings.json` | 위와 동일 | 중복 |
| databricks | `~/.claude/settings.json` | .ai-dev-kit/.venv/python | 사용 기록 없음 |
| databricks | `dotfiles/.claude/settings.json` | 위와 동일 | 중복 |
| databricks | `~/.ai-dev-kit/repo/.mcp.json` | ${CLAUDE_PLUGIN_ROOT}/.venv/python | 중복 |
| browser-server | `~/bin/.mcp.json` | browser-use-mcp-server | binary 없음 → DEAD |
| markdown-oxide | `~/DocumentsLocal/msbaek_vault/.mcp.json` | npx tritlo/lsp-mcp | 사용 기록 없음 |

### Plugin 현황 (enabledPlugins 기준)

| Plugin | Skill 수 | 현재 상태 | 비고 |
|--------|---------|---------|------|
| superpowers | 14 | enabled | PROTECT |
| msbaek-tdd | 21 | enabled | PROTECT |
| obsidian@obsidian-skills | 5 | enabled | PROTECT |
| plugin-dev | 7 | enabled | 필요시 판단 |
| pr-review-toolkit | - | enabled | 필요시 판단 |
| feature-dev | - | enabled | 필요시 판단 |
| hookify | 1 | enabled | PROTECT |
| context-engineering-fundamentals | - | enabled | 0회 사용 |
| agent-architecture | - | enabled | 0회 사용 |
| agent-evaluation | - | enabled | 0회 사용 |
| agent-development | - | enabled | 0회 사용 |
| cognitive-architecture | - | enabled | 0회 사용 |
| greptile | - | enabled | 0회 사용 |
| kotlin-lsp@plugins-official | - | enabled | lsps 계열과 중복 |
| LSP 5개 | 0 | enabled | Java/Kotlin/C# 사용 여부 따라 |
| github@plugins-official | - | **false** | 이미 비활성 |
| explanatory-output-style | - | **false** | 이미 비활성 |
| arscontexta@agenticnotetaking | 10 | **false** (local) | 이미 비활성 |

---

## Task 1: 브랜치 생성 + 스냅샷 저장

**Files:**
- Create: `docs/snapshots/2026-04-29/README.md`
- Create: `docs/snapshots/2026-04-29/` (스냅샷 파일들)

- [ ] **Step 1: 브랜치 생성**

```bash
cd $HOME/dotfiles
git checkout -b chore/cleanup-skill-mcp-2026-04-29
```

Expected: `Switched to a new branch 'chore/cleanup-skill-mcp-2026-04-29'`

- [ ] **Step 2: 스냅샷 디렉토리 생성**

```bash
mkdir -p $HOME/dotfiles/docs/snapshots/2026-04-29
```

- [ ] **Step 3: git 외부 파일 스냅샷 저장**

```bash
# global settings
cp $HOME/.claude/settings.json \
   $HOME/dotfiles/docs/snapshots/2026-04-29/settings-global.json

# settings.local.json
cp $HOME/.claude/settings.local.json \
   $HOME/dotfiles/docs/snapshots/2026-04-29/settings-local.json

# installed_plugins.json
cp $HOME/.claude/plugins/installed_plugins.json \
   $HOME/dotfiles/docs/snapshots/2026-04-29/installed_plugins.json

# bin/.mcp.json
cp $HOME/bin/.mcp.json \
   $HOME/dotfiles/docs/snapshots/2026-04-29/mcp-bin.json

# vault/.mcp.json
cp $HOME/DocumentsLocal/msbaek_vault/.mcp.json \
   $HOME/dotfiles/docs/snapshots/2026-04-29/mcp-vault.json

# ai-dev-kit/.mcp.json
cp $HOME/.ai-dev-kit/repo/.mcp.json \
   $HOME/dotfiles/docs/snapshots/2026-04-29/mcp-ai-dev-kit.json
```

- [ ] **Step 4: 스냅샷 README 작성**

`docs/snapshots/2026-04-29/README.md` 내용:
```markdown
# 정리 전 스냅샷 (2026-04-29)

| 파일 | 원본 경로 |
|------|----------|
| settings-global.json | ~/.claude/settings.json |
| settings-local.json | ~/.claude/settings.local.json |
| installed_plugins.json | ~/.claude/plugins/installed_plugins.json |
| mcp-bin.json | ~/bin/.mcp.json |
| mcp-vault.json | ~/DocumentsLocal/msbaek_vault/.mcp.json |
| mcp-ai-dev-kit.json | ~/.ai-dev-kit/repo/.mcp.json |

git 추적 파일 복원: `git checkout <commit> -- .claude/settings.json`
git 추적 파일 복원: `git checkout <commit> -- .claude/mcp.json`
```

- [ ] **Step 5: commit 1**

```bash
cd $HOME/dotfiles
git add docs/snapshots/2026-04-29/
git add docs/superpowers/specs/2026-04-29-skill-mcp-cleanup-design.md
git add docs/superpowers/plans/2026-04-29-skill-mcp-cleanup.md
```

`/commit` skill 실행: `chore: 정리 전 스냅샷 및 설계·계획 문서 저장`

---

## Task 2: MCP Audit 테이블 제시 + 사용자 라벨링 [CHECKPOINT]

**목적:** 모든 MCP 서버를 사용자에게 보여주고 keep/remove 라벨을 받는다.

- [ ] **Step 1: MCP 서버 현재 상태 확인**

```bash
# browser-server binary 재확인
which browser-use-mcp-server 2>/dev/null || echo "DEAD: binary not found"

# CodeGraphContext binary 확인
which cgc 2>/dev/null || echo "NOT FOUND"

# databricks venv 확인
ls $HOME/.ai-dev-kit/.venv/bin/python 2>/dev/null || echo "NOT FOUND"
```

- [ ] **Step 2: 사용자에게 audit 테이블 제시 후 라벨링 요청**

아래 테이블을 사용자에게 보여주고 각 행의 판정(keep/remove)을 묻는다.

| # | 서버명 | 등록 위치 | 상태 | 제안 | 판정 |
|---|--------|----------|------|------|------|
| 1 | playwright (http) | `~/.claude/settings.json` | DUPLICATE (3중) | KEEP 1개만 | ? |
| 2 | playwright (npx) | `dotfiles/.claude/mcp.json` | ACTIVE | KEEP (이게 원본) | ? |
| 3 | playwright (http) | `dotfiles/.claude/settings.json` | DUPLICATE | REMOVE | ? |
| 4 | CodeGraphContext | `~/.claude/settings.json` | DORMANT (0회) | REMOVE | ? |
| 5 | CodeGraphContext | `dotfiles/.claude/settings.json` | DUPLICATE | REMOVE | ? |
| 6 | databricks | `~/.claude/settings.json` | DORMANT (0회) | REMOVE | ? |
| 7 | databricks | `dotfiles/.claude/settings.json` | DUPLICATE | REMOVE | ? |
| 8 | browser-server | `~/bin/.mcp.json` | DEAD (binary 없음) | REMOVE | ? |
| 9 | markdown-oxide | `~/vault/.mcp.json` | DORMANT (0회) | REMOVE | ? |

**⚠ STOP — 사용자 입력 대기.** 사용자가 keep/remove 라벨을 제공하면 Task 3으로 진행.

---

## Task 3: MCP 정리 실행 (사용자 라벨링 기반)

**전제:** Task 2에서 사용자가 라벨링 완료.

- [ ] **Step 1: browser-server 제거 (~/bin/.mcp.json)**

remove 라벨 받은 경우:
```bash
# 비워서 덮어쓰기 (파일 자체는 유지, 항목만 제거)
echo '{"mcpServers": {}}' > $HOME/bin/.mcp.json
```

Expected: 파일이 `{"mcpServers": {}}` 로 변경됨

- [ ] **Step 2: settings.json에서 중복·불필요 MCP 제거**

사용자 라벨링 기반으로 `~/.claude/settings.json`의 `mcpServers` 섹션을 편집한다.

예시 — CodeGraphContext + databricks 제거, playwright(http) 유지 시:
```json
"mcpServers": {
  "playwright": {
    "url": "http://localhost:8931/mcp",
    "args": ["@playwright/mcp@0.0.70"]
  }
}
```

예시 — playwright(http) 도 제거 시 (npx 버전만 유지):
```json
"mcpServers": {}
```

dotfiles/.claude/settings.json 도 동일하게 변경 (symlink가 아닌 별도 파일인 경우).

- [ ] **Step 3: markdown-oxide 제거 (vault/.mcp.json)**

remove 라벨 받은 경우:
```bash
echo '{"mcpServers": {}}' > $HOME/DocumentsLocal/msbaek_vault/.mcp.json
```

- [ ] **Step 4: 변경 검증**

```bash
python3 -c "
import json
for f in [
    '$HOME/.claude/settings.json',
    '$HOME/dotfiles/.claude/mcp.json',
    '$HOME/bin/.mcp.json',
    '$HOME/DocumentsLocal/msbaek_vault/.mcp.json',
]:
    try:
        with open(f) as fp: d = json.load(fp)
        servers = d.get('mcpServers', {})
        print(f'{f}: {list(servers.keys())}')
    except Exception as e:
        print(f'{f}: ERROR {e}')
"
```

Expected: 제거 대상이 목록에서 빠진 것 확인

- [ ] **Step 5: commit 2**

```bash
cd $HOME/dotfiles
git add .claude/settings.json .claude/mcp.json
```

`/commit` skill: `chore: MCP 서버 정리 (dead/dormant/duplicate 제거)`

---

## Task 4: Plugin Audit 테이블 제시 + 사용자 라벨링 [CHECKPOINT]

- [ ] **Step 1: enabledPlugins 현재 상태 확인**

```bash
python3 -c "
import json
with open('$HOME/.claude/settings.json') as f:
    d = json.load(f)
ep = d.get('enabledPlugins', {})
for k, v in sorted(ep.items()):
    print(f'{\"ON\" if v else \"OFF\"}  {k}')
"
```

- [ ] **Step 2: skill-usage 로그에서 plugin별 사용 현황 확인**

```bash
python3 -c "
import json
from collections import Counter
skills = Counter()
with open('$HOME/.claude/logs/skills-usage.jsonl') as f:
    for line in f:
        try:
            line = line.strip().replace('\~', '~')
            d = json.loads(line)
            skills[d.get('skill', '')] += 1
        except: pass
print('사용된 skill 목록:')
for s, c in sorted(skills.items(), key=lambda x: -x[1]):
    print(f'  {c:3d}x {s}')
"
```

- [ ] **Step 3: 사용자에게 audit 테이블 제시 + 라벨링 요청**

| # | Plugin | Skill 수 | 현재 | 제안 | 판정 |
|---|--------|---------|------|------|------|
| 1 | context-engineering-fundamentals | ? | ON | REMOVE (0회) | ? |
| 2 | agent-architecture | ? | ON | REMOVE (0회) | ? |
| 3 | agent-evaluation | ? | ON | REMOVE (0회) | ? |
| 4 | agent-development | ? | ON | REMOVE (0회) | ? |
| 5 | cognitive-architecture | ? | ON | REMOVE (0회) | ? |
| 6 | greptile | ? | ON | REMOVE (0회) | ? |
| 7 | kotlin-lsp@plugins-official | 0 | ON | REMOVE (lsps 중복) | ? |
| 8 | jdtls@claude-code-lsps | 0 | ON | 판단 필요 (Java 쓰는지?) | ? |
| 9 | kotlin-lsp@claude-code-lsps | 0 | ON | 판단 필요 | ? |
| 10 | omnisharp@claude-code-lsps | 0 | ON | 판단 필요 (C# 쓰는지?) | ? |
| 11 | rust-analyzer@claude-code-lsps | 0 | ON | 판단 필요 (Rust 쓰는지?) | ? |
| 12 | vtsls@claude-code-lsps | 0 | ON | 판단 필요 (TS/JS 쓰는지?) | ? |
| 13 | security-guidance | ? | ON | 판단 필요 | ? |
| 14 | superpowers | 14 | ON | PROTECT | keep |
| 15 | msbaek-tdd | 21 | ON | PROTECT | keep |
| 16 | obsidian@obsidian-skills | 5 | ON | PROTECT | keep |
| 17 | hookify | 1 | ON | PROTECT | keep |
| 18 | claude-md-management | 1 | ON | PROTECT | keep |
| 19 | skill-creator | 1 | ON | PROTECT | keep |

**⚠ STOP — 사용자 입력 대기.**

---

## Task 5: Plugin 정리 실행 (사용자 라벨링 기반)

**전제:** Task 4에서 사용자가 라벨링 완료.

- [ ] **Step 1: enabledPlugins에서 REMOVE 항목을 false로 설정**

`~/.claude/settings.json`의 `enabledPlugins` 섹션에서 remove 라벨 받은 항목을 `false`로 변경한다.

예시 — context-engineering 5개 + greptile + kotlin-lsp@official REMOVE 시:
```json
"context-engineering-fundamentals@context-engineering-marketplace": false,
"agent-architecture@context-engineering-marketplace": false,
"agent-evaluation@context-engineering-marketplace": false,
"agent-development@context-engineering-marketplace": false,
"cognitive-architecture@context-engineering-marketplace": false,
"greptile@claude-plugins-official": false,
"kotlin-lsp@claude-plugins-official": false,
```

- [ ] **Step 2: 변경 검증**

```bash
python3 -c "
import json
with open('$HOME/.claude/settings.json') as f:
    d = json.load(f)
ep = d.get('enabledPlugins', {})
disabled = [(k, v) for k, v in ep.items() if not v]
print(f'비활성 plugin {len(disabled)}개:')
for k, v in disabled:
    print(f'  OFF  {k}')
"
```

Expected: REMOVE 라벨 받은 plugin이 OFF 목록에 있음

- [ ] **Step 3: commit 3**

dotfiles/.claude/settings.json 변경 반영:
```bash
cd $HOME/dotfiles
git add .claude/settings.json
```

`/commit` skill: `chore: Plugin 정리 (미사용 plugin 비활성화)`

---

## Task 6: 로컬 Skill Audit 테이블 제시 + 사용자 라벨링 [CHECKPOINT]

- [ ] **Step 1: 로컬 skill 목록 + 사용 빈도 결합**

```bash
python3 -c "
import os, json
from collections import Counter

# skill usage
usage = Counter()
try:
    with open('$HOME/.claude/logs/skills-usage.jsonl') as f:
        for line in f:
            line = line.strip().replace('\~', '~')
            try:
                d = json.loads(line)
                usage[d.get('skill', '')] += 1
            except: pass
except: pass

skills_dir = '$HOME/.claude/skills'
items = sorted(os.listdir(skills_dir))
print(f'총 {len(items)}개 로컬 skill:')
print()
for name in items:
    path = os.path.join(skills_dir, name)
    is_link = os.path.islink(path)
    link_target = os.readlink(path) if is_link else ''
    broken = is_link and not os.path.exists(path)
    count = usage.get(name, 0)
    status = 'BROKEN' if broken else ('SYMLINK' if is_link else 'local')
    print(f'{count:3d}x  [{status:7s}]  {name}' + (f' -> {link_target}' if is_link else ''))
"
```

- [ ] **Step 2: 사용자에게 audit 테이블 제시 + 라벨링 요청**

위 명령어 출력을 테이블로 정리해 사용자에게 제시한다. 0회 사용 항목이 제거 후보.

주요 판단 기준:
- `BROKEN` symlink → REMOVE 강력 추천
- 0회 사용 + plugin에서도 동일 skill 제공 → REMOVE 후보
- 0회 사용 + 로컬에만 있는 중요 skill → 사용자 판단

**⚠ STOP — 사용자 입력 대기.**

---

## Task 7: 로컬 Skill 정리 실행 (사용자 라벨링 기반)

**전제:** Task 6에서 사용자가 라벨링 완료.

- [ ] **Step 1: REMOVE 항목 삭제**

사용자가 remove 라벨 준 skill 하나씩:
```bash
# 예시: databricks-academy 제거
rm -rf $HOME/.claude/skills/databricks-academy

# 예시: broken symlink 제거
rm $HOME/.claude/skills/<broken-skill-name>
```

- [ ] **Step 2: 삭제 검증**

```bash
ls $HOME/.claude/skills/ | wc -l
# 제거 전 62개에서 제거한 수만큼 줄었는지 확인
```

- [ ] **Step 3: commit 4**

```bash
cd $HOME/dotfiles
# 로컬 skill은 dotfiles에 없으므로, 변경 내역을 문서로만 기록
# (복구 가이드 draft에 반영)
git add docs/  # 가이드 업데이트가 있으면
```

`/commit` skill: `chore: 로컬 Skill 정리 (미사용/중복/broken 제거)`

---

## Task 8: 복구 가이드 작성 + commit 5

**Files:**
- Create: `docs/cleanup-recovery-guide.md`

- [ ] **Step 1: 복구 가이드 작성**

Task 2~7에서 실제 제거한 모든 항목을 기반으로 `docs/cleanup-recovery-guide.md` 작성.

파일 구조:
```markdown
# Skill & MCP 정리 복구 가이드

작업일: 2026-04-29
브랜치: chore/cleanup-skill-mcp-2026-04-29

## 전체 복원
git log --oneline chore/cleanup-skill-mcp-2026-04-29
git revert <commit-hash>  # 특정 단계만 복원 가능

## MCP 서버 복원

### <서버명>
- **등록 파일:** `<파일 경로>`
- **복원:** 아래 JSON 블록을 해당 파일의 `mcpServers`에 추가

\`\`\`json
"<서버명>": {
  ... (원래 설정 블록 전체)
}
\`\`\`

## Plugin 복원

### <plugin명>
- **복원:** `~/.claude/settings.json`의 `enabledPlugins`에서 `false` → `true`
- 또는: 재설치 `claude plugins install <id>`

## 로컬 Skill 복원

### <skill명>
- **원래 경로:** `~/.claude/skills/<skill명>/`
- **복원:**
  \`\`\`bash
  git show <commit-hash>:path/in/repo -- .  # git 외부이므로 스냅샷에서
  # 또는 docs/snapshots/2026-04-29/ 에서 확인
  \`\`\`
```

- [ ] **Step 2: 복구 가이드에 실제 제거 항목 기입**

각 제거 항목의 원래 JSON/설정값을 docs/snapshots에서 가져와 복구 가이드에 기입.

예시 — browser-server:
```json
"browser-server": {
  "command": "browser-use-mcp-server",
  "args": ["run", "server", "--port", "8000", "--stdio", "--proxy-port", "9000"],
  "env": {"OPENAI_API_KEY": "your-api-key"}  # pragma: allowlist secret
}
```
등록 파일: `~/bin/.mcp.json`

- [ ] **Step 3: commit 5**

```bash
cd $HOME/dotfiles
git add docs/cleanup-recovery-guide.md
```

`/commit` skill: `docs: Skill·MCP 정리 복구 가이드 작성`

---

## Task 9: 마무리 — main 머지 + 검증

- [ ] **Step 1: 커밋 이력 확인**

```bash
git log --oneline chore/cleanup-skill-mcp-2026-04-29 ^main
```

Expected: commit 1~5가 순서대로 나열됨

- [ ] **Step 2: main으로 merge commit**

```bash
git checkout main
git merge --no-ff chore/cleanup-skill-mcp-2026-04-29 \
  -m "chore: Skill·MCP 정리 (토큰 절감 + 유지보수성 개선)"
```

- [ ] **Step 3: Claude 재시작 후 검증**

Claude 재시작 후 (`/exit` → 재실행):
- system reminder에서 제거한 MCP 서버가 더 이상 나타나지 않는지 확인
- `claude --version` 으로 정상 시작 확인
- obsidian-summarize 워크플로우 playwright MCP 작동 확인

- [ ] **Step 4: journal 기록**

Task 2~7 실행 후 실제 제거한 수를 채워 기록:
```bash
# 실제 제거한 수를 직접 숫자로 넣어서 실행
printf '## 2026-04-29 HH:MM | dotfiles | Skill·MCP 정리 완료\n\n제거: MCP X개, Plugin Y개, 로컬 Skill Z개\n세션 시작 토큰 절감 확인. 복구 가이드: docs/cleanup-recovery-guide.md\n\n' \
  >> $HOME/.claude/journals/2026-04.journal.md
```
(X/Y/Z는 실제 제거 수로 대체)

---

## 실행 방식 선택

이 계획은 Task 2/4/6에서 사용자 라벨링 CHECKPOINT가 있으므로 **Inline Execution (executing-plans)** 으로 실행하는 것을 권장합니다. 각 CHECKPOINT에서 Claude가 멈추고 사용자 입력을 기다립니다.
