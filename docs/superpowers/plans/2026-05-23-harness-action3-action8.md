# Harness Action 3 + Action 8 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Statusline에 오늘 friction count 표시 + hooks 유효성 검증 스크립트 추가로 harness closed-loop을 완성한다.

**Architecture:**
- Action 3: `~/claude-config/bin/claude-statusline-combined`에 friction count를 추가. `/tmp/friction-today-cache.txt` 5분 캐시로 402개 파일 스캔 오버헤드 제거. `0✗ 0⊘`이면 표시 생략.
- Action 8: `~/.claude/bin/validate-hooks.sh` — settings.json hook 항목의 파일 존재·timeout·run-hook-with-timeout.sh 미사용 여부를 Python으로 파싱해 경고 출력.

**Tech Stack:** bash, Python 3.11, `~/.claude/bin/friction-audit.py` (기존), `~/.claude/settings.json` (기존)

**Scope 제외:** Actions 4, 5 (Strategic — langfuse, MCP Server)는 별도 plan 필요. 이 문서에서 다루지 않음.

---

## 파일 맵

| 파일 | 역할 | 변경 유형 |
|------|------|-----------|
| `~/claude-config/bin/claude-statusline-combined` | friction count 노출 | Modify |
| `~/.claude/bin/validate-hooks.sh` | hooks 유효성 검증 | Create |

---

## Task 1: Statusline에 friction signal 추가 (Action 3)

**Files:**
- Modify: `~/claude-config/bin/claude-statusline-combined`

### 배경 지식

`claude-statusline-combined`는 Claude Code가 statusline 갱신마다 JSON을 stdin으로 전달한다. 현재 구조:

```
stdin JSON → ccstatusline (model/tokens/cost) + claude-usage-statusline (quota)
→ "opus-4-7 | 1234t $0.05 | 5h:72% 7d:45%"
```

추가 목표:

```
"opus-4-7 | 1234t $0.05 | 5h:72% 7d:45% | 30✗ 17⊘"
```

`friction-audit.py --count-only`가 매번 402개 파일을 스캔하면 200ms+ 걸릴 수 있으므로 5분 캐시 필수.

### 구현 설계

```bash
# 5분 캐시를 사용하는 friction count 조회
get_friction_count() {
  local cache="/tmp/friction-today-cache.txt"
  local cache_age_limit=300  # 5 minutes

  if [[ -f "$cache" ]]; then
    local cache_mtime now age
    cache_mtime=$(python3 -c "import os; print(int(os.path.getmtime('$cache')))" 2>/dev/null || echo 0)
    now=$(date +%s)
    age=$(( now - cache_mtime ))
    if [[ $age -lt $cache_age_limit ]]; then
      cat "$cache"
      return 0
    fi
  fi

  python3 "$HOME/.claude/bin/friction-audit.py" --today --count-only \
    > "$cache" 2>/dev/null || echo "" > "$cache"
  cat "$cache"
}
```

- [ ] **Step 1: 현재 스크립트 읽기 및 백업**

```bash
cp ~/claude-config/bin/claude-statusline-combined \
   ~/claude-config/bin/claude-statusline-combined.bak
cat ~/claude-config/bin/claude-statusline-combined
```

기대: 현재 내용이 출력됨 (get_friction_count 함수 없음).

- [ ] **Step 2: `get_friction_count` 함수 추가**

`# Get quota output` 블록 바로 위에 다음을 삽입한다:

```bash
# Get friction count (cached 5 min to avoid scanning 400+ telemetry files each tick)
get_friction_count() {
  local cache="/tmp/friction-today-cache.txt"
  local cache_age_limit=300

  if [[ -f "$cache" ]]; then
    local cache_mtime now age
    cache_mtime=$(python3 -c "import os; print(int(os.path.getmtime('$cache')))" 2>/dev/null || echo 0)
    now=$(date +%s)
    age=$(( now - cache_mtime ))
    if [[ $age -lt $cache_age_limit ]]; then
      cat "$cache"
      return 0
    fi
  fi

  python3 "$HOME/.claude/bin/friction-audit.py" --today --count-only \
    > "$cache" 2>/dev/null || true
  [[ -f "$cache" ]] && cat "$cache" || true
}
```

- [ ] **Step 3: friction_output 변수 추가 및 최종 출력 로직 수정**

현재 마지막 `# Combine` 블록:

```bash
# Combine
if [[ -n "$cc_output" && -n "$quota_output" ]]; then
  echo "${cc_output} | ${quota_output}"
elif [[ -n "$cc_output" ]]; then
  echo "$cc_output"
elif [[ -n "$quota_output" ]]; then
  echo "$quota_output"
fi
```

를 다음으로 교체한다:

```bash
# Get friction count (non-blocking, cached)
friction_output=$(get_friction_count 2>/dev/null) || friction_output=""
# Only show if non-zero
if [[ "$friction_output" == "0✗ 0⊘" || -z "$friction_output" ]]; then
  friction_output=""
fi

# Combine
parts=()
[[ -n "$cc_output" ]]      && parts+=("$cc_output")
[[ -n "$quota_output" ]]   && parts+=("$quota_output")
[[ -n "$friction_output" ]] && parts+=("$friction_output")

if [[ ${#parts[@]} -gt 0 ]]; then
  printf '%s' "${parts[0]}"
  for part in "${parts[@]:1}"; do
    printf ' | %s' "$part"
  done
  echo
fi
```

- [ ] **Step 4: smoke test — 직접 실행**

```bash
echo '{}' | ~/claude-config/bin/claude-statusline-combined
```

기대: 에러 없이 출력됨. friction이 오늘 없으면 기존 출력과 동일.

- [ ] **Step 5: 캐시 무효화 후 friction 강제 출력 확인**

```bash
rm -f /tmp/friction-today-cache.txt
# 전체 기간 count가 0이 아님을 먼저 확인
python3 ~/.claude/bin/friction-audit.py --count-only
```

기대: `30✗ 17⊘` (오늘 0이면 숫자가 다를 수 있음 — 오늘 데이터가 없는 것은 정상).

- [ ] **Step 6: 백업 제거 후 commit**

```bash
rm ~/claude-config/bin/claude-statusline-combined.bak
cd ~/claude-config
git add bin/claude-statusline-combined
git status
```

커밋 메시지 파일 생성 후 커밋:

```bash
cat > /tmp/commit_msg.txt << 'HEREDOC'
feat(statusline): 오늘 friction count 표시 추가 (Action 3)

- get_friction_count 함수: /tmp/friction-today-cache.txt 5분 캐시
- 0✗ 0⊘ 이면 표시 생략 (노이즈 제거)
- Combine 로직 배열 기반으로 리팩토링 (가변 파트 지원)

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
HEREDOC
git commit -F /tmp/commit_msg.txt
rm /tmp/commit_msg.txt
```

---

## Task 2: Hook 검증 스크립트 (Action 8)

**Files:**
- Create: `~/.claude/bin/validate-hooks.sh`

### 배경 지식

현재 settings.json hooks 분석 결과:

```
[PostToolUse] timeout=None | sh -c '... skills-log.sh ...'   ← timeout 없음 + wrapper 없음 ⚠️
[Stop]        timeout=None | run-hook-with-timeout.sh ...    ← wrapper가 대신 처리 → OK
[PreToolUse]  timeout=5    | python3 skill-model-advisor.py  ← timeout 있음 → OK
```

검증 규칙:
1. **파일 존재**: 명령어에서 `$HOME` 확장 후 파일 경로 추출 → `os.path.exists()` 확인
2. **timeout 누락 경고**: `run-hook-with-timeout.sh`를 사용하지 않고 timeout도 없는 hook
3. **하드코딩 경로**: `/Users/` 또는 `/home/` 포함 시 경고

### 스크립트 설계

```python
#!/usr/bin/env python3
"""Validate ~/.claude/settings.json hooks."""
import json, os, re, sys
from pathlib import Path

HOME = Path.home()
settings = json.loads((HOME / ".claude/settings.json").read_text())
hooks = settings.get("hooks", {})

errors, warnings = [], []

for event, entries in hooks.items():
    for entry in entries:
        for hook in entry.get("hooks", []):
            cmd = hook.get("command", "")
            timeout = hook.get("timeout")
            cmd_expanded = cmd.replace("$HOME", str(HOME))

            # Rule 1: extract script path and check existence
            for part in cmd_expanded.split():
                if part.startswith("/") and not part.startswith("/tmp"):
                    if "." in Path(part).name and not Path(part).exists():
                        errors.append(f"[{event}] 파일 없음: {part}")
                    break

            # Rule 2: timeout check (skip if uses wrapper)
            uses_wrapper = "run-hook-with-timeout.sh" in cmd
            if not uses_wrapper and timeout is None:
                warnings.append(f"[{event}] timeout 없음 (wrapper도 없음): {cmd[:70]}")

            # Rule 3: hardcoded paths
            if re.search(r'/Users/\w|/home/\w', cmd):
                warnings.append(f"[{event}] 하드코딩 경로: {cmd[:70]}")
```

- [x] **Step 1: 스크립트 파일 생성**

`~/.claude/bin/validate-hooks.sh` 를 다음 내용으로 생성한다:

```bash
#!/usr/bin/env bash
# Validate ~/.claude/settings.json hooks for missing files, missing timeouts, hardcoded paths.
# Exit 0: no errors. Exit 1: errors found. Warnings are non-fatal.
set -euo pipefail

python3 - << 'PYEOF'
import json, os, re, sys
from pathlib import Path

HOME = Path.home()
settings = json.loads((HOME / ".claude/settings.json").read_text())
hooks = settings.get("hooks", {})

errors, warnings = [], []

for event, entries in hooks.items():
    for entry in entries:
        for hook in entry.get("hooks", []):
            cmd = hook.get("command", "")
            timeout = hook.get("timeout")
            cmd_expanded = cmd.replace("$HOME", str(HOME))

            # Rule 1: check script file exists
            for part in cmd_expanded.split():
                if part.startswith("/") and not part.startswith("/tmp"):
                    p = Path(part)
                    if p.suffix and not p.exists():
                        errors.append(f"[{event}] 파일 없음: {part}")
                    break

            # Rule 2: no timeout and no wrapper
            uses_wrapper = "run-hook-with-timeout.sh" in cmd
            if not uses_wrapper and timeout is None:
                warnings.append(
                    f"[{event}] timeout 없음 (wrapper 미사용): {cmd[:70]}"
                )

            # Rule 3: hardcoded absolute user paths
            if re.search(r'/Users/\w|/home/\w', cmd):
                warnings.append(f"[{event}] 하드코딩 경로 → \$HOME 치환 권장: {cmd[:70]}")

if errors:
    print("❌ ERRORS:")
    for e in errors:
        print(f"  {e}")
if warnings:
    print("⚠️  WARNINGS:")
    for w in warnings:
        print(f"  {w}")
if not errors and not warnings:
    print("✅ All hooks valid")

sys.exit(1 if errors else 0)
PYEOF
```

- [x] **Step 2: 실행 권한 부여**

```bash
chmod +x ~/.claude/bin/validate-hooks.sh
```

- [x] **Step 3: smoke test — 실행 후 출력 확인**

```bash
~/.claude/bin/validate-hooks.sh; echo "exit: $?"
```

기대 출력 (현재 settings.json 기준):

```
⚠️  WARNINGS:
  [PostToolUse] timeout 없음 (wrapper 미사용): sh -c '[ -f "$HOME/.claude/bin/skills-log.sh" ] && ...
exit: 0
```

(errors가 없으면 exit 0, warnings만 있으면 exit 0 — 경고는 비치명적)

- [x] **Step 4: 경고 항목 수동 수정 여부 결정**

`skills-log.sh` hook에 timeout을 추가하거나 wrapper로 감쌀지 결정한다.

**간단한 수정**: `settings.json`의 해당 hook에 `"timeout": 5` 추가

```json
{
  "matcher": "Skill",
  "hooks": [
    {
      "type": "command",
      "command": "sh -c '[ -f \"$HOME/.claude/bin/skills-log.sh\" ] && \"$HOME/.claude/bin/skills-log.sh\"; exit 0'",
      "timeout": 5
    }
  ]
}
```

수정 후 재실행:

```bash
~/.claude/bin/validate-hooks.sh; echo "exit: $?"
```

기대: `✅ All hooks valid` + `exit: 0`

- [x] **Step 5: commit**

```bash
cd ~/.claude
git add bin/validate-hooks.sh settings.json
```

커밋:

```bash
cat > /tmp/commit_msg.txt << 'HEREDOC'
feat(bin): validate-hooks.sh — hook 유효성 검증 스크립트 추가 (Action 8)

- 파일 존재·timeout 누락·하드코딩 경로 3가지 규칙 검증
- run-hook-with-timeout.sh wrapper 사용 시 timeout 경고 면제
- skills-log.sh hook에 timeout: 5 추가 (⚠️ 수정 결과)

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
HEREDOC
git commit -F /tmp/commit_msg.txt
rm /tmp/commit_msg.txt
```

---

## 전략적 Action 참고 (별도 plan 필요)

### Action 4: Skill Golden Test Harness
복잡도 높음. `/commit` skill을 대상으로 golden input/output 쌍 정의, langfuse OTLP trace 수집 포함. **별도 brainstorming 세션 권장**.

### Action 5: Self-reflection MCP Server
Python FastAPI + Claude Code MCP protocol 구현. telemetry/history.jsonl/journals 통합. **별도 brainstorming 세션 권장**.

---

## Self-Review Checklist

- [x] **Spec coverage**: Action 3 (statusline 표시), Action 8 (validate 스크립트) — 모두 커버
- [x] **Placeholder scan**: TBD/TODO 없음, 모든 코드 블록 완성
- [x] **Type consistency**: bash 변수명 일관 (`friction_output`, `parts`), Python 변수명 일관 (`errors`, `warnings`)
- [x] **경계 조건**: `0✗ 0⊘` 이면 표시 생략, cache 파일 없을 때 fallback, validate-hooks exit code 구분

---

## Resume Point

**다음 시작**: Task 1 Step 1 — `claude-statusline-combined` 백업 및 읽기부터.
