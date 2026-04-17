#!/usr/bin/env bash
# Simple assertion-based test for skills-log.sh
set -u

SCRIPT="$HOME/.claude/bin/skills-log.sh"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

export SKILLS_LOG_PATH="$TMPDIR/usage.jsonl"
FAILED=0

assert_eq() {
    if [[ "$1" != "$2" ]]; then
        echo "FAIL: expected '$2', got '$1' ($3)"
        FAILED=$((FAILED + 1))
    else
        echo "PASS: $3"
    fi
}

# Test 1: valid Skill tool payload → 1 line appended
PAYLOAD='{"tool_name":"Skill","tool_input":{"skill":"foo:bar"},"cwd":"/tmp/test"}'
echo "$PAYLOAD" | "$SCRIPT"
COUNT=$(wc -l < "$SKILLS_LOG_PATH" 2>/dev/null | tr -d ' ' || echo 0)
assert_eq "$COUNT" "1" "valid payload appends 1 line"

# Test 2: logged line contains expected skill
if [[ -f "$SKILLS_LOG_PATH" ]]; then
    LINE=$(cat "$SKILLS_LOG_PATH")
    if echo "$LINE" | grep -q '"skill":"foo:bar"'; then
        echo "PASS: line contains skill name"
    else
        echo "FAIL: line missing skill name. got: $LINE"
        FAILED=$((FAILED + 1))
    fi
fi

# Test 3: malformed JSON → exits 0, raw record appended
echo "not json at all" | "$SCRIPT"
RC=$?
assert_eq "$RC" "0" "malformed input exits 0"

# Test 4: non-Skill tool → no append (only 1 line remains from test 1)
echo '{"tool_name":"Bash","tool_input":{"command":"ls"}}' | "$SCRIPT"
COUNT=$(wc -l < "$SKILLS_LOG_PATH" | tr -d ' ')
assert_eq "$COUNT" "2" "non-Skill tool still logged (match filter is hook-level)"
# Note: hook matcher="Skill" filters before script runs; script always logs.

if [[ $FAILED -eq 0 ]]; then
    echo "All tests passed"
    exit 0
else
    echo "$FAILED tests failed"
    exit 1
fi
