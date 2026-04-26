#!/usr/bin/env bash
# SessionStart hook — 3개 소스에서 컨텍스트를 수집해 additionalContext로 주입.
# Sources: Active Plans (.claude/plans/INDEX.md) + 현재 월 일기 마지막 30줄 + 프로젝트 ai-learnings.md
# 세션 목록은 v1에서 제외 (agf list가 --since 미지원, 일기로 대체 가능).
# 어제 vault 문서 §4.2 (Claude-Code-세션-메모리-효율화-전략-claude-mem-대안.md) 기반.

set +e

PARTS=()

INDEX="$PWD/.claude/plans/INDEX.md"
if [ -f "$INDEX" ]; then
  ACTIVE=$(awk '/^## Active/{flag=1; next} /^## /{flag=0} flag' "$INDEX" 2>/dev/null | sed '/^[[:space:]]*$/d' | head -10)
  if [ -n "$ACTIVE" ]; then
    PARTS+=("### Active Plans (.claude/plans/INDEX.md)")
    PARTS+=("$ACTIVE")
    PARTS+=("")
  fi
fi

JOURNAL="$HOME/.claude/journals/$(date +%Y-%m).journal.md"
if [ -f "$JOURNAL" ]; then
  RECENT=$(tail -15 "$JOURNAL" 2>/dev/null)
  if [ -n "$RECENT" ]; then
    PARTS+=("### Recent Journal (last 15 lines, $(basename "$JOURNAL"))")
    PARTS+=("$RECENT")
    PARTS+=("")
  fi
fi

LEARNINGS="$PWD/ai-learnings.md"
if [ -f "$LEARNINGS" ]; then
  LRN=$(head -20 "$LEARNINGS" 2>/dev/null)
  if [ -n "$LRN" ]; then
    PARTS+=("### Project Learnings (ai-learnings.md, head 20)")
    PARTS+=("$LRN")
    PARTS+=("")
  fi
fi

if [ ${#PARTS[@]} -eq 0 ]; then
  echo '{}'
  exit 0
fi

OUTPUT="## SessionStart 자동 컨텍스트"
for p in "${PARTS[@]}"; do
  OUTPUT="${OUTPUT}
${p}"
done

if [ ${#OUTPUT} -gt 4000 ]; then
  OUTPUT="${OUTPUT:0:4000}
... (truncated at 4KB)"
fi

ESCAPED=$(printf '%s' "$OUTPUT" | python3 -c "import sys, json; print(json.dumps(sys.stdin.read()))" 2>/dev/null)

if [ -z "$ESCAPED" ]; then
  echo '{}'
  exit 0
fi

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": ${ESCAPED}
  }
}
EOF
