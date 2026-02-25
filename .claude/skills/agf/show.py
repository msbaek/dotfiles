#!/usr/bin/env python3
"""agf show - Claude Code 세션 상세 데이터 추출"""

import json, os, datetime, sys

PROJECTS_DIR = os.path.expanduser("~/.claude/projects")
HISTORY = os.path.expanduser("~/.claude/history.jsonl")


def main():
    if len(sys.argv) < 2:
        print("ERROR: 세션 ID prefix를 인자로 전달해주세요.")
        raise SystemExit(1)

    prefix = sys.argv[1]

    # Find session file by prefix
    matches = []
    for dirpath, dirnames, filenames in os.walk(PROJECTS_DIR):
        for f in filenames:
            if f.startswith(prefix) and f.endswith(".jsonl"):
                matches.append(os.path.join(dirpath, f))

    if not matches:
        print("ERROR: NO_MATCH")
        raise SystemExit(1)
    if len(matches) > 1:
        print("ERROR: MULTI_MATCH")
        for m in matches:
            sid = os.path.basename(m).replace(".jsonl", "")
            proj_dir = os.path.basename(os.path.dirname(m))
            print(f"  {sid[:8]} | {proj_dir}")
        raise SystemExit(1)

    session_file = matches[0]
    sid = os.path.basename(session_file).replace(".jsonl", "")
    proj_dir = os.path.basename(os.path.dirname(session_file))

    # File metadata
    stat = os.stat(session_file)
    created = datetime.datetime.fromtimestamp(stat.st_birthtime)
    modified = datetime.datetime.fromtimestamp(stat.st_mtime)
    delta = modified - created
    hours, remainder = divmod(int(delta.total_seconds()), 3600)
    minutes = remainder // 60
    size_mb = stat.st_size / (1024 * 1024)

    # Parse session JSONL
    with open(session_file) as f:
        lines = f.readlines()

    git_branch = "unknown"
    cwd = "unknown"
    user_msgs = []
    assistant_snippets = []
    user_count = 0
    asst_count = 0

    for line in lines:
        obj = json.loads(line)
        t = obj.get("type")
        if t == "progress" and obj.get("gitBranch") and git_branch == "unknown":
            git_branch = obj["gitBranch"]
            cwd = obj.get("cwd", "unknown")
        elif t == "user":
            user_count += 1
            content = obj.get("message", {}).get("content", "")
            if isinstance(content, str) and content.strip():
                text = content.strip()[:200].replace("\n", " ")
                if not text.startswith("<"):
                    user_msgs.append(text)
        elif t == "assistant":
            asst_count += 1
            content = obj.get("message", {}).get("content", "")
            if isinstance(content, list):
                texts = [b.get("text", "") for b in content if b.get("type") == "text"]
                snippet = " ".join(texts)[:100].replace("\n", " ")
            else:
                snippet = str(content)[:100].replace("\n", " ")
            if snippet.strip():
                assistant_snippets.append(snippet)

    # Get history display messages
    history_msgs = []
    with open(HISTORY) as f:
        for line in f:
            obj = json.loads(line)
            if obj.get("sessionId") == sid:
                d = obj.get("display", "").strip()
                if d:
                    history_msgs.append(d[:200])

    # Output metadata
    print("META_START")
    print(f"session_id: {sid}")
    print(f"project_dir: {proj_dir}")
    print(f"cwd: {cwd}")
    print(f"git_branch: {git_branch}")
    print(f"start: {created.strftime('%Y-%m-%d %H:%M')}")
    print(f"end: {modified.strftime('%Y-%m-%d %H:%M')}")
    print(f"duration: {hours}h {minutes:02d}m")
    print(f"user_messages: {user_count}")
    print(f"assistant_messages: {asst_count}")
    print(f"file_size: {size_mb:.1f}MB")
    print("META_END")

    # Output conversation data for AI summary (max ~4000 chars)
    print("CONV_START")
    total = 0
    for u, a in zip(user_msgs, assistant_snippets):
        entry = f"U: {u}\nA: {a}\n"
        if total + len(entry) > 4000:
            break
        print(entry)
        total += len(entry)
    print("CONV_END")

    # Output history display messages
    print("HISTORY_START")
    for i, m in enumerate(history_msgs, 1):
        print(f"{i}. {m}")
    print("HISTORY_END")


if __name__ == "__main__":
    main()
