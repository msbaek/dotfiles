#!/usr/bin/env python3
"""agf list - Claude Code 세션 목록 조회"""

import json, os, datetime, re, sys

HISTORY = os.path.expanduser("~/.claude/history.jsonl")
PROJECTS_DIR = os.path.expanduser("~/.claude/projects")


def main():
    target = sys.argv[1] if len(sys.argv) > 1 else datetime.date.today().isoformat()

    if not os.path.exists(HISTORY):
        print("ERROR: ~/.claude/history.jsonl 파일을 찾을 수 없습니다.")
        raise SystemExit(1)

    y, m, d = int(target[:4]), int(target[5:7]), int(target[8:10])
    t_start = datetime.datetime(y, m, d).timestamp() * 1000
    t_end = t_start + 86400000

    with open(HISTORY) as f:
        lines = f.readlines()

    sessions = {}
    for line in lines:
        obj = json.loads(line)
        ts = obj.get("timestamp", 0)
        if t_start <= ts < t_end:
            sid = obj.get("sessionId", "")
            if not sid:
                continue
            proj = obj.get("project", "unknown")
            display = obj.get("display", "").strip()
            if not display:
                continue
            proj_name = proj.split("/")[-1] if "/" in proj else proj
            if sid not in sessions:
                sessions[sid] = {"project": proj_name, "project_path": proj, "messages": [], "first_ts": ts}
            sessions[sid]["messages"].append(display)
            if ts < sessions[sid]["first_ts"]:
                sessions[sid]["first_ts"] = ts

    results = []
    for sid, info in sessions.items():
        proj_dir = re.sub(r'[^a-zA-Z0-9]', '-', info["project_path"])
        session_file = os.path.join(PROJECTS_DIR, proj_dir, f"{sid}.jsonl")
        duration = "-"
        size_str = "-"
        start_time = datetime.datetime.fromtimestamp(info["first_ts"] / 1000).strftime("%H:%M")
        if os.path.exists(session_file):
            stat = os.stat(session_file)
            created = datetime.datetime.fromtimestamp(stat.st_birthtime)
            modified = datetime.datetime.fromtimestamp(stat.st_mtime)
            delta = modified - created
            hours, remainder = divmod(int(delta.total_seconds()), 3600)
            minutes = remainder // 60
            duration = f"{hours}h {minutes:02d}m"
            start_time = created.strftime("%H:%M")
            size_mb = stat.st_size / (1024 * 1024)
            size_str = f"{size_mb:.1f}MB"
        first_msg = info["messages"][0][:50].replace("|", "/").replace("\n", " ")
        results.append((start_time, info["project"], sid[:8], duration, size_str, first_msg, len(info["messages"])))

    results.sort(key=lambda x: x[0])

    print(f"## {target} 세션 목록 ({len(results)}개 세션)\n")
    print("| # | 프로젝트 | 세션 ID | 시작 | Duration | 크기 | 메시지 수 | 첫 메시지 |")
    print("|---|----------|---------|------|----------|------|-----------|-----------|")
    for i, (start, proj, sid, dur, size, msg, cnt) in enumerate(results, 1):
        print(f"| {i} | {proj} | {sid} | {start} | {dur} | {size} | {cnt} | {msg} |")


if __name__ == "__main__":
    main()
