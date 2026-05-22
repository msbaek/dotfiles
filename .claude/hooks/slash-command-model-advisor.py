#!/usr/bin/env python3
"""UserPromptSubmit hook with two responsibilities:
  (a) Detect execution-class slash command invocations → recommend model switch
      (but only when the session's actual current model is NOT already Sonnet —
      decided by reading the session JSONL, not by Claude self-judgment).
  (b) Detect 'keep Opus' intent right after a recommendation → write stickiness.
      Pending-marker gate prevents false positives in unrelated code-review chatter.

Failure mode previously observed: additionalContext said "이미 해당 모델이면 안내 불필요",
Claude misjudged its own model, silently skipped the recommendation. Fix: hook itself
reads the JSONL and only fires when actually needed — no escape clause delegated.
Fail-open: any JSONL read error → fire anyway.
"""
import glob
import json
import os
import re
import sys

STATE_FILE_FMT = "/tmp/claude-model-decision-{session}.json"
PENDING_MARKER_FMT = "/tmp/claude-model-pending-{session}.json"
PROJECTS_DIR = os.path.expanduser("~/.claude/projects")

# Execution-class slash commands under ~/.claude/commands/*.md
EXEC_COMMANDS = {
    "commit", "wrap-up", "skills-audit", "skills-catalog",
    "check-subagent-model", "skills-curate", "coffee-time",
    "conventional-review", "check-security", "update-claude-md",
    "vis-backlink-toggle", "meeting-minutes", "markitdown-convert",
}
RESET_COMMANDS = {"brainstorming"}  # rare via slash command; safety net

# Harness-generated prefix when user approves a plan and implementation begins.
# Anchored via re.match so occurrences inside the plan body don't trigger.
PLAN_IMPL_PATTERN = re.compile(r"\s*Implement the following plan:", re.IGNORECASE)


def is_plan_implementation(prompt):
    """True iff this prompt is the harness-generated plan-implementation entry."""
    return bool(PLAN_IMPL_PATTERN.match(prompt))

# 'Keep Opus' intent patterns — case-insensitive Korean + English.
# Must co-occur with a model context keyword (opus/sonnet/모델) to avoid silent matches.
KEEP_OPUS_PATTERNS = [
    r"opus\s*(유지|그대로|계속|stay|keep)",
    r"(유지|그대로|계속)\s*opus",
    r"(no|아니|괜찮)[,.\s]+opus",
    r"sonnet\s*(말고|아니|안|싫)",
    r"모델\s*(유지|그대로|바꾸지\s*마)",
]


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
    """
    if not sid or sid == "default":
        return None
    matches = glob.glob(os.path.join(PROJECTS_DIR, "*", f"{sid}.jsonl"))
    if not matches:
        return None
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
            continue
        if e.get("type") == "assistant":
            m = e.get("message", {}).get("model")
            if m:
                return m
    return None


def family_match(recommended, current):
    if not current:
        return False
    if "sonnet" in recommended and "sonnet" in current:
        return True
    if "opus" in recommended and "opus" in current:
        return True
    if "haiku" in recommended and "haiku" in current:
        return True
    return False


def extract_slash_commands(prompt):
    """Return the leading slash command in the prompt, if any.

    Slash commands appear only at the very beginning of user input. Anchoring with
    ^ via re.match prevents false positives like `https://x.com/commit/...` or
    `/commit` inside code blocks from triggering a pending marker.
    """
    m = re.match(r"\s*/([a-zA-Z][a-zA-Z0-9_-]*)", prompt)
    return {m.group(1)} if m else set()


def pending_marker_exists(sid):
    return os.path.exists(PENDING_MARKER_FMT.format(session=sid))


def clear_pending_marker(sid):
    try:
        os.unlink(PENDING_MARKER_FMT.format(session=sid))
    except OSError:
        pass


def reset_sticky(sid):
    for path in (STATE_FILE_FMT.format(session=sid), PENDING_MARKER_FMT.format(session=sid)):
        try:
            os.unlink(path)
        except OSError:
            pass


def main():
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        sys.exit(0)

    prompt = payload.get("prompt") or payload.get("user_prompt") or ""
    if not prompt:
        sys.exit(0)

    sid = session_id(payload)
    commands = extract_slash_commands(prompt)

    # Reset trigger
    if commands & RESET_COMMANDS:
        reset_sticky(sid)

    # (a) Sticky decision — only honoured when a pending marker exists
    if pending_marker_exists(sid):
        for pat in KEEP_OPUS_PATTERNS:
            if re.search(pat, prompt, re.IGNORECASE):
                try:
                    with open(STATE_FILE_FMT.format(session=sid), "w") as f:
                        json.dump({"keep_opus": True, "matched": pat}, f)
                    clear_pending_marker(sid)
                    print(f"📌 stickiness set (pending matched: {pat}) — session: {sid[:8]}", file=sys.stderr)
                except OSError:
                    pass
                break

    # (b) Slash command or plan-implementation entry — recommend Sonnet
    exec_hit = commands & EXEC_COMMANDS
    plan_impl = is_plan_implementation(prompt)
    if not exec_hit and not plan_impl:
        sys.exit(0)

    # Skip if already sticky
    try:
        with open(STATE_FILE_FMT.format(session=sid)) as f:
            if json.load(f).get("keep_opus"):
                sys.exit(0)
    except (OSError, json.JSONDecodeError):
        pass

    # JSONL-based model gate — silent if already on Sonnet family. Fail-open.
    recommended = "claude-sonnet-4-6"
    current = current_model_from_jsonl(sid)
    if family_match(recommended, current):
        sys.exit(0)

    label = f"/{sorted(exec_hit)[0]}" if exec_hit else "plan 구현 진입"

    # Pending marker — next user input may confirm stickiness
    try:
        with open(PENDING_MARKER_FMT.format(session=sid), "w") as f:
            json.dump({"model": recommended, "label": label}, f)
    except OSError:
        pass

    detected = f" (detected: {current})" if current else ""
    print(f"⚠️  권장 모델: /model {recommended} (trigger: {label}){detected}", file=sys.stderr)

    if exec_hit:
        ctx = (
            f"사용자가 실행 계열 slash command `{label}`를 호출했다. "
            f"`/model {recommended}` 전환을 권장하라. "
            f"이 안내문을 그대로 출력한 후 본문을 진행하라. "
            f"hook이 이미 현재 모델을 JSONL에서 확인했으므로 self-skip 금지. "
            f"사용자가 'opus 유지' 답변 시 같은 세션에서 재안내 금지."
        )
    else:
        ctx = (
            f"plan 승인 후 구현 단계에 진입했다. <when-plan-complete> 트리거 1에 해당한다. "
            f"/model {recommended} 전환을 권장하라. "
            f"이 안내문을 그대로 출력한 후 본문을 진행하라. "
            f"hook이 JSONL에서 현재 모델을 확인했으므로 self-skip 금지. "
            f"사용자가 'opus 유지' 답변 시 같은 세션에서 재안내 금지."
        )
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": ctx
        }
    }))


if __name__ == "__main__":
    main()
