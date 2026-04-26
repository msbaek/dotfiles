#!/usr/bin/env python3
"""PreToolUse hook: 스킬/Tool별 권장 모델 알림 (non-blocking)."""
import json
import sys

ROUTING = {
    ("Skill", "superpowers:brainstorming"): "claude-opus-4-7",
    ("Skill", "superpowers:writing-plans"): "claude-sonnet-4-6",
    ("Skill", "superpowers:executing-plans"): "claude-sonnet-4-6",
    ("Skill", "superpowers:subagent-driven-development"): "claude-sonnet-4-6",
    ("ExitPlanMode", None): "claude-sonnet-4-6",
}


def parse_skill_name(tool_input):
    for k in ("skill", "skillName", "name"):
        v = tool_input.get(k)
        if v:
            return v
    return None


def main():
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        sys.exit(0)

    tool_name = payload.get("tool_name", "")
    tool_input = payload.get("tool_input", {}) or {}

    try:
        with open("/tmp/skill-hook-debug.json", "a") as f:
            f.write(json.dumps(payload) + "\n")
    except OSError:
        pass

    skill_name = parse_skill_name(tool_input) if tool_name == "Skill" else None
    key = (tool_name, skill_name) if tool_name == "Skill" else (tool_name, None)
    model = ROUTING.get(key)
    if not model:
        sys.exit(0)

    label = skill_name or tool_name
    msg = f"권장 모델: /model {model} (trigger: {label})"
    print(f"⚠️  {msg}", file=sys.stderr)
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "additionalContext": f"사용자에게 `/model {model}` 전환을 안내하라 (trigger: {label}). 이미 해당 모델이면 안내 불필요."
        }
    }))


if __name__ == "__main__":
    main()
