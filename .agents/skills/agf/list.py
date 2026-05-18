#!/usr/bin/env python3
"""agf list - Claude Code session list"""

import sys, datetime
from common import load_history, project_dir_name, session_file_path, file_meta


def main():
    target = sys.argv[1] if len(sys.argv) > 1 else datetime.date.today().isoformat()
    entries = load_history(date=target)

    sessions = {}
    for obj in entries:
        sid = obj.get("sessionId", "")
        if not sid:
            continue
        proj = obj.get("project", "unknown")
        display = obj.get("display", "").strip()
        if not display:
            continue
        ts = obj.get("timestamp", 0)
        proj_name = proj.split("/")[-1] if "/" in proj else proj
        if sid not in sessions:
            sessions[sid] = {"project": proj_name, "project_path": proj, "messages": [], "first_ts": ts}
        sessions[sid]["messages"].append(display)
        if ts < sessions[sid]["first_ts"]:
            sessions[sid]["first_ts"] = ts

    results = []
    for sid, info in sessions.items():
        proj_dir = project_dir_name(info["project_path"])
        sf = session_file_path(proj_dir, sid)
        meta = file_meta(sf)
        start_time = datetime.datetime.fromtimestamp(info["first_ts"] / 1000).strftime("%H:%M")
        duration = "-"
        size_str = "-"
        if meta:
            start_time = meta["start_time"]
            duration = meta["duration_str"]
            size_str = meta["size_str"]
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
