#!/usr/bin/env python3
"""PreToolUse hook: skill/tool routing → recommended model notification (non-blocking).

Verified facts (2026-05-16):
- Hook payload contains: session_id, tool_name, tool_input — NO model field.
- Model identity for the session lives in the Claude Code session JSONL at
  ~/.claude/projects/<project-key>/<session_id>.jsonl on every assistant entry.
- Namespace prefix mixing: "superpowers:writing-plans" vs "writing-plans" — normalize().

Failure mode previously observed: when additionalContext included an escape clause
"이미 해당 모델이면 안내 불필요", Claude self-judged the current model wrong and
silently skipped the recommendation. The fix: the hook itself reads the JSONL,
decides whether the announcement is needed, and only fires when it actually is —
no escape clause delegated to Claude. Fail-open: any read error → fire anyway.

INVARIANT: normalize() strips plugin prefix, so two plugins sharing a suffix would
collide. When adding keys, verify with: find ~/.claude/plugins -name "<key>" -o -name "*:<key>"
"""
import glob
import json
import os
import sys

# Sonnet recommended (mechanical execution) — matched after normalize() strips prefix
EXEC_SKILLS = {
    "writing-plans",
    "executing-plans",
    "subagent-driven-development",
    "session-handoff",       # user-defined skill (~/.claude/skills/)
    "vis-backlink-status",   # user-defined skill
}
# Opus recommended (creative/design)
PLAN_SKILLS = {
    "brainstorming",
}
# Stickiness reset on entering a new planning phase
RESET_SKILLS = {
    "brainstorming",
    "writing-plans",
}

STATE_FILE_FMT = "/tmp/claude-model-decision-{session}.json"
PENDING_MARKER_FMT = "/tmp/claude-model-pending-{session}.json"
PROJECTS_DIR = os.path.expanduser("~/.claude/projects")


def parse_skill_name(tool_input):
    for k in ("skill", "skillName", "name"):
        v = tool_input.get(k)
        if v:
            return v
    return None


def normalize(skill_name):
    """'superpowers:writing-plans' → 'writing-plans'. Handles prefix mixing."""
    if not skill_name:
        return None
    return skill_name.split(":", 1)[-1] if ":" in skill_name else skill_name


def session_id(payload):
    return (
        payload.get("session_id")
        or payload.get("sessionId")
        or os.environ.get("CLAUDE_SESSION_ID")
        or "default"
    )


def current_model_from_jsonl(sid):
    """Return the most-recent assistant `model` for this session, or None.

    Reads the tail (~64KB) of ~/.claude/projects/*/<sid>.jsonl and walks lines
    in reverse to find the newest assistant entry. Fail-open: any error returns
    None so the caller fires the recommendation rather than going silent.

    Note: sub-agents have their own session_id, so this returns the sub-agent's
    model — which is correct for hook decisions about that tool call.
    """
    if not sid or sid == "default":
        return None
    matches = glob.glob(os.path.join(PROJECTS_DIR, "*", f"{sid}.jsonl"))
    if not matches:
        return None
    # If somehow >1 match, pick newest mtime
    path = max(matches, key=lambda p: os.path.getmtime(p)) if len(matches) > 1 else matches[0]
    try:
        with open(path, "rb") as f:
            try:
                f.seek(-65536, 2)
            except OSError:
                f.seek(0)
            data = f.read()
        lines = data.decode("utf-8", errors="replace").splitlines()
    except OSError:
        return None
    for line in reversed(lines):
        line = line.strip()
        if not line:
            continue
        try:
            e = json.loads(line)
        except json.JSONDecodeError:
            # Mid-line cut at the head of the tail buffer — skip
            continue
        if e.get("type") == "assistant":
            m = e.get("message", {}).get("model")
            if m:
                return m
    return None


def family_match(recommended, current):
    """True iff `current` is already in the family of `recommended`."""
    if not current:
        return False
    if "sonnet" in recommended and "sonnet" in current:
        return True
    if "opus" in recommended and "opus" in current:
        return True
    if "haiku" in recommended and "haiku" in current:
        return True
    return False


def is_sticky(sid):
    try:
        with open(STATE_FILE_FMT.format(session=sid)) as f:
            return json.load(f).get("keep_opus") is True
    except (OSError, json.JSONDecodeError):
        return False


def reset_sticky(sid):
    for path in (STATE_FILE_FMT.format(session=sid), PENDING_MARKER_FMT.format(session=sid)):
        try:
            os.unlink(path)
        except OSError:
            pass


def write_pending_marker(sid, model, label):
    """slash-command-model-advisor checks this to confirm a recent recommendation."""
    try:
        with open(PENDING_MARKER_FMT.format(session=sid), "w") as f:
            json.dump({"model": model, "label": label}, f)
    except OSError:
        pass


def lookup(tool_name, normalized_skill):
    if tool_name == "ExitPlanMode":
        return "claude-sonnet-4-6", "exec"
    if tool_name != "Skill" or not normalized_skill:
        return None, None
    if normalized_skill in EXEC_SKILLS:
        return "claude-sonnet-4-6", "exec"
    if normalized_skill in PLAN_SKILLS:
        return "claude-opus-4-7", "plan"
    return None, None


def main():
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        sys.exit(0)

    tool_name = payload.get("tool_name", "")
    tool_input = payload.get("tool_input", {}) or {}
    sid = session_id(payload)

    try:
        with open("/tmp/skill-hook-debug.json", "a") as f:
            f.write(json.dumps(payload) + "\n")
    except OSError:
        pass

    raw_skill = parse_skill_name(tool_input) if tool_name == "Skill" else None
    skill = normalize(raw_skill)

    if skill in RESET_SKILLS:
        reset_sticky(sid)

    model, category = lookup(tool_name, skill)
    if not model:
        sys.exit(0)

    if category == "exec" and is_sticky(sid):
        sys.exit(0)

    # JSONL-based model gate — silent if already on target family. Fail-open.
    current = current_model_from_jsonl(sid)
    if family_match(model, current):
        sys.exit(0)

    label = raw_skill or tool_name
    if category == "exec":
        write_pending_marker(sid, model, label)

    detected = f" (detected: {current})" if current else ""
    print(f"⚠️  권장 모델: /model {model} (trigger: {label}){detected}", file=sys.stderr)
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "additionalContext": (
                f"사용자에게 `/model {model}` 전환을 권장하라 (trigger: {label}). "
                f"이 안내문을 그대로 출력한 후 본문을 진행하라. "
                f"hook이 이미 현재 모델을 JSONL에서 확인했으므로 self-skip 금지. "
                f"사용자가 'opus 유지'·'그대로' 답변 시 같은 세션에서 재안내 금지."
            )
        }
    }))


if __name__ == "__main__":
    main()
