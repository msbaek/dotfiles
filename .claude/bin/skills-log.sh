#!/usr/bin/env bash
# Append Skill tool call event to JSONL log.
# Input: JSON payload on stdin (Claude Code hook format).
# Output: appends 1 line to $SKILLS_LOG_PATH (or ~/.claude/logs/skills-usage.jsonl).
# Safety: always exits 0, never blocks parent tool.

set +e

LOG_PATH="${SKILLS_LOG_PATH:-$HOME/.claude/logs/skills-usage.jsonl}"
mkdir -p "$(dirname "$LOG_PATH")" 2>/dev/null

TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
PAYLOAD=$(cat)

# Validity gate: skip malformed JSON (don't pollute log)
if command -v jq >/dev/null 2>&1; then
    if ! printf '%s' "$PAYLOAD" | jq -e . >/dev/null 2>&1; then
        exit 0
    fi
fi

# Try parsing with jq; fall back to raw string
if command -v jq >/dev/null 2>&1; then
    SKILL=$(echo "$PAYLOAD" | jq -r '.tool_input.skill // .tool_input.command // "unknown"' 2>/dev/null)
    CWD=$(echo "$PAYLOAD" | jq -r '.cwd // ""' 2>/dev/null)
else
    SKILL="unknown"
    CWD=""
fi

# Normalize
[[ -z "$SKILL" || "$SKILL" == "null" ]] && SKILL="unknown"
CWD="${CWD/#$HOME/\~}"

# Append JSONL (simple manual construction, no jq dependency for output)
printf '{"ts":"%s","skill":"%s","project":"%s","trigger":"auto"}\n' \
    "$TS" "$SKILL" "$CWD" >> "$LOG_PATH" 2>/dev/null

exit 0
