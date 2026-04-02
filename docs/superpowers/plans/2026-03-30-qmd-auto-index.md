# QMD Auto-Index on Search Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `qmd-search` 래퍼 스크립트를 만들어 검색 시 자동으로 색인 갱신을 처리하고, 관련 스킬에서 이를 참조하도록 수정한다.

**Architecture:** `bin/qmd-search` 셸 스크립트가 실제 파일 수와 qmd 인덱스 파일 수를 비교하여 새 파일이 있으면 `qmd update && qmd embed`를 실행한 뒤 `qmd query`를 호출한다. 스킬 파일 3개에서 기존 freshness 체크 로직을 제거하고 `qmd-search`를 참조한다.

**Tech Stack:** Bash, qmd CLI, fd

---

## File Structure

| File | Action | Responsibility |
|------|--------|---------------|
| `bin/qmd-search` | Create | Freshness 체크 + 자동 갱신 + qmd query 래핑 |
| `.claude/skills/agf/SKILL.md` | Modify | `qmd query` → `qmd-search`, freshness 텍스트 제거 |
| `.claude/skills/recall/SKILL.md` | Modify | qmd 관련 설명을 `qmd-search` 참조로 변경 |
| `.claude/skills/recall/workflows/recall.md` | Modify | Step 2B.0 제거, `qmd query` → `qmd-search` |

---

### Task 1: `bin/qmd-search` 래퍼 스크립트 생성

**Files:**
- Create: `bin/qmd-search`

- [ ] **Step 1: 스크립트 파일 생성**

```bash
#!/usr/bin/env bash
# qmd-search: Auto-index wrapper for qmd query
# Compares actual session file count with qmd index count,
# runs qmd update && qmd embed if new files exist, then searches.

set -euo pipefail

SESSIONS_DIR="$HOME/git/claude-sessions"
SKIP_UPDATE=false

# Parse --skip-update flag
if [[ "${1:-}" == "--skip-update" ]]; then
  SKIP_UPDATE=true
  shift
fi

# Validate: search query required
if [[ $# -eq 0 ]]; then
  echo "Usage: qmd-search [--skip-update] <query>" >&2
  exit 1
fi

# Check qmd binary exists
if ! command -v qmd &>/dev/null; then
  echo "Error: qmd not found in PATH" >&2
  exit 1
fi

# Freshness check (skip if --skip-update)
if [[ "$SKIP_UPDATE" == false ]]; then
  if [[ -d "$SESSIONS_DIR" ]]; then
    actual_count=$(fd -e md . "$SESSIONS_DIR" 2>/dev/null | wc -l | tr -d ' ')
    indexed_count=$(qmd collection list 2>/dev/null | grep "Files:" | awk '{print $2}' || echo "0")

    if [[ "$actual_count" -gt "$indexed_count" ]]; then
      new_files=$((actual_count - indexed_count))
      echo "qmd-search: ${new_files} new files detected (actual: ${actual_count}, indexed: ${indexed_count}). Updating index..." >&2
      if ! qmd update 2>/dev/null; then
        echo "qmd-search: Warning: qmd update failed, searching with existing index" >&2
      elif ! qmd embed 2>/dev/null; then
        echo "qmd-search: Warning: qmd embed failed, searching with existing index" >&2
      fi
    fi
  else
    echo "qmd-search: Warning: $SESSIONS_DIR not found, skipping freshness check" >&2
  fi
fi

# Execute search
exec qmd query "$@"
```

- [ ] **Step 2: 실행 권한 부여**

Run: `chmod +x bin/qmd-search`

- [ ] **Step 3: stow 배포 확인**

Run: `stow . && which qmd-search`
Expected: `~/bin/qmd-search`

- [ ] **Step 4: 기본 동작 테스트 — 색인 갱신 트리거**

Run: `qmd-search "TDD" 2>&1 | head -25`
Expected: "N new files detected" 메시지 (stderr) + 검색 결과 (stdout). 현재 210개 차이가 있으므로 갱신이 실행되어야 함.

- [ ] **Step 5: --skip-update 테스트**

Run: `qmd-search --skip-update "TDD" 2>&1 | head -10`
Expected: 갱신 메시지 없이 바로 검색 결과만 출력.

- [ ] **Step 6: 인자 없이 실행 테스트**

Run: `qmd-search 2>&1; echo "exit: $?"`
Expected: usage 메시지 + `exit: 1`

- [ ] **Step 7: 커밋**

```bash
git add bin/qmd-search
git commit -m "feat(qmd): add qmd-search wrapper with auto-index on search"
```

---

### Task 2: `.claude/skills/agf/SKILL.md` 수정

**Files:**
- Modify: `.claude/skills/agf/SKILL.md`

- [ ] **Step 1: freshness 체크 섹션을 `qmd-search` 참조로 교체**

현재 파일의 `## qmd 병행 검색` 섹션(line 171~193)을 아래로 교체:

```markdown
## qmd 병행 검색 (세션 탐색 시 권장)

세션을 키워드로 검색할 때 agf `search --deep`과 함께 **qmd semantic 검색을 병행**하면 키워드 매칭에 안 걸리는 세션도 발견할 수 있습니다.

### qmd 검색

```bash
# qmd-search가 색인 신선도를 자동 확인하고 필요 시 갱신 후 검색합니다
qmd-search "검색어" 2>/dev/null | head -20
```

agf 결과와 qmd 결과를 합쳐서 중복 제거 후 분석합니다.
```

제거되는 내용:
- "qmd 색인 신선도 확인" 하위 섹션 전체 (`qmd collection list`, `qmd update && qmd embed` 블록)
- `qmd query` 명령을 `qmd-search`로 교체

- [ ] **Step 2: 변경 확인**

Run: `grep -n "qmd-search\|qmd query\|색인 신선도" .claude/skills/agf/SKILL.md`
Expected: `qmd-search`만 존재, `qmd query`와 `색인 신선도`는 없음.

- [ ] **Step 3: 커밋**

```bash
git add .claude/skills/agf/SKILL.md
git commit -m "refactor(agf): replace manual qmd freshness check with qmd-search"
```

---

### Task 3: `.claude/skills/recall/SKILL.md` 수정

**Files:**
- Modify: `.claude/skills/recall/SKILL.md`

- [ ] **Step 1: qmd 관련 설명 수정**

Line 16의 설명을 수정:

현재:
```markdown
- **Topic queries** ("authentication", "TDD"): vis semantic search (vault 전체) + qmd semantic search (세션 전용) 병행. qmd 색인이 1일 이상 경과 시 자동 갱신.
```

변경:
```markdown
- **Topic queries** ("authentication", "TDD"): vis semantic search (vault 전체) + qmd semantic search (세션 전용) 병행. `qmd-search`가 색인 신선도를 자동 관리.
```

Line 20의 설명을 수정:

현재:
```markdown
Topic recall은 vis + qmd를 병행합니다. qmd 색인이 오래된 경우 `qmd update && qmd embed`로 자동 갱신합니다.
```

변경:
```markdown
Topic recall은 vis + qmd를 병행합니다. `qmd-search`가 색인 신선도를 자동으로 확인하고 필요 시 갱신합니다.
```

- [ ] **Step 2: 변경 확인**

Run: `grep -n "qmd-search\|qmd update\|qmd embed\|1일 이상" .claude/skills/recall/SKILL.md`
Expected: `qmd-search`만 존재, `qmd update`, `qmd embed`, `1일 이상`은 없음.

- [ ] **Step 3: 커밋**

```bash
git add .claude/skills/recall/SKILL.md
git commit -m "refactor(recall): update qmd references to use qmd-search"
```

---

### Task 4: `.claude/skills/recall/workflows/recall.md` 수정

**Files:**
- Modify: `.claude/skills/recall/workflows/recall.md`

- [ ] **Step 1: Step 2B.0 전체 제거**

Line 54~68의 "Step 2B.0: qmd 색인 신선도 확인" 블록 전체를 삭제:

```markdown
**Step 2B.0: qmd 색인 신선도 확인**

qmd 검색 전 반드시 색인 신선도를 확인합니다:

\`\`\`bash
qmd collection list 2>/dev/null | grep -A1 "claude-sessions"
\`\`\`

출력에서 `Updated:` 값이 **1일 이상 경과**하면 자동으로 색인을 갱신합니다:

\`\`\`bash
qmd update && qmd embed
\`\`\`

> **주의:** `qmd embed`은 신규 문서 수에 따라 수십 초~수 분 소요될 수 있습니다. 색인이 최신이면 이 단계를 건너뜁니다.
```

- [ ] **Step 2: Step 2B.1에서 qmd query를 qmd-search로 교체**

현재 (line 79):
```markdown
# qmd: 세션 의미 검색 (병렬 실행)
qmd query "QUERY" 2>/dev/null | head -20
```

변경:
```markdown
# qmd: 세션 의미 검색 (qmd-search가 색인 자동 갱신 후 검색)
qmd-search "QUERY" 2>/dev/null | head -20
```

- [ ] **Step 3: Notes 섹션의 qmd 색인 언급 수정**

현재 (line 201):
```markdown
- **qmd 색인 신선도**: `qmd collection list`의 Updated 값이 1일 이상이면 `qmd update && qmd embed` 실행
```

변경:
```markdown
- **qmd 색인 신선도**: `qmd-search`가 파일 수 비교로 자동 관리 (수동 갱신 불필요)
```

- [ ] **Step 4: 변경 확인**

Run: `grep -n "qmd-search\|qmd query\|2B.0\|색인 신선도 확인\|qmd update\|qmd embed" .claude/skills/recall/workflows/recall.md`
Expected: `qmd-search`와 수정된 "색인 신선도" 라인만 존재. `qmd query`, `2B.0`, `qmd update`, `qmd embed`는 없음.

- [ ] **Step 5: 커밋**

```bash
git add .claude/skills/recall/workflows/recall.md
git commit -m "refactor(recall): remove manual freshness check, use qmd-search"
```

---

### Task 5: 통합 검증

- [ ] **Step 1: 전체 파일에서 stale 패턴 검색**

Run: `grep -rn "qmd query\|qmd update\|qmd embed\|색인 신선도 확인" .claude/skills/`
Expected: 결과 없음 (모든 참조가 `qmd-search`로 교체됨)

- [ ] **Step 2: qmd-search 실제 검색 테스트**

Run: `qmd-search "TDD 리팩토링" 2>/dev/null | head -10`
Expected: 검색 결과가 정상 출력됨. 이전 Task 1에서 색인이 갱신됐으므로 이번에는 갱신 메시지 없이 바로 결과 출력.

- [ ] **Step 3: qmd 색인 상태 확인**

Run: `qmd collection list 2>/dev/null | grep "Files:"`
Expected: `Files: 1822` (또는 현재 실제 파일 수와 일치)
