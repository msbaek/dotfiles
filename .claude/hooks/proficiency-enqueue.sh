#!/usr/bin/env bash
# proficiency-enqueue.sh — SessionEnd hook
# Reads hook JSON from stdin, writes a lightweight marker to the pending queue.
# No LLM calls here; analysis happens at /proficiency-review time.

set -euo pipefail

PENDING_DIR="$HOME/.claude/state/proficiency/pending"
mkdir -p "$PENDING_DIR"

# Read JSON payload from stdin
RAW=$(cat)

SESSION_ID=$(echo "$RAW" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('session_id',''))" 2>/dev/null || true)
TRANSCRIPT=$(echo "$RAW" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('transcript_path',''))" 2>/dev/null || true)
CWD=$(echo "$RAW" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('cwd',''))" 2>/dev/null || true)

[ -z "$SESSION_ID" ] && exit 0
[ -z "$TRANSCRIPT" ] && exit 0

# Derive project key from cwd (basename, sanitized)
PROJECT_KEY=$(basename "$CWD" | tr ' /' '_-' | tr -cd '[:alnum:]_-')
[ -z "$PROJECT_KEY" ] && PROJECT_KEY="unknown"

MARKER="$PENDING_DIR/${SESSION_ID}.json"

# Atomic write: temp file → rename
TMPFILE=$(mktemp "$PENDING_DIR/.tmp.XXXXXX")
python3 -c "
import json, sys
data = {
    'session_id': sys.argv[1],
    'transcript': sys.argv[2],
    'cwd': sys.argv[3],
    'project_key': sys.argv[4],
    'enqueued_at': __import__('datetime').datetime.now().isoformat()
}
print(json.dumps(data, ensure_ascii=False))
" "$SESSION_ID" "$TRANSCRIPT" "$CWD" "$PROJECT_KEY" > "$TMPFILE"
mv "$TMPFILE" "$MARKER"

exit 0
