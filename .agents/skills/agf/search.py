#!/usr/bin/env python3
"""agf search - search Claude Code sessions by query"""

import json, os, sys, re, datetime
from common import HISTORY, PROJECTS_DIR, project_dir_name, session_file_path, file_meta


def search_display(query):
    """Search history.jsonl display field. Returns {sid: {project, project_path, first_ts, matched}}."""
    if not os.path.exists(HISTORY):
        print("ERROR: ~/.claude/history.jsonl 파일을 찾을 수 없습니다.")
        raise SystemExit(1)
    pattern = re.compile(re.escape(query), re.IGNORECASE)
    with open(HISTORY) as f:
        lines = f.readlines()
    sessions = {}
    for line in lines:
        obj = json.loads(line)
        sid = obj.get("sessionId", "")
        if not sid:
            continue
        proj = obj.get("project", "unknown")
        display = obj.get("display", "").strip()
        ts = obj.get("timestamp", 0)
        if not display:
            continue
        proj_name = proj.split("/")[-1] if "/" in proj else proj
        if sid not in sessions:
            sessions[sid] = {"project": proj_name, "project_path": proj, "first_ts": ts, "matched": []}
        if ts < sessions[sid]["first_ts"]:
            sessions[sid]["first_ts"] = ts
        if pattern.search(display) and len(sessions[sid]["matched"]) < 2:
            sessions[sid]["matched"].append(display[:100].replace("|", "/").replace("\n", " "))
    return {sid: info for sid, info in sessions.items() if info["matched"]}


def search_deep(query, exclude_sids):
    """Search inside session JSONL files for user/assistant messages.
    Returns {sid: {project, project_path, first_ts, matched}}."""
    pattern = re.compile(re.escape(query), re.IGNORECASE)
    results = {}
    for dirpath, dirnames, filenames in os.walk(PROJECTS_DIR):
        for fname in filenames:
            if not fname.endswith(".jsonl"):
                continue
            sid = fname.replace(".jsonl", "")
            if sid in exclude_sids:
                continue
            fpath = os.path.join(dirpath, fname)
            proj_dir = os.path.basename(dirpath)
            matched = []
            try:
                with open(fpath) as f:
                    for line in f:
                        obj = json.loads(line)
                        t = obj.get("type", "")
                        text = ""
                        if t == "user":
                            content = obj.get("message", {}).get("content", "")
                            if isinstance(content, str):
                                text = content
                        elif t == "assistant":
                            content = obj.get("message", {}).get("content", "")
                            if isinstance(content, list):
                                text = " ".join(b.get("text", "") for b in content if b.get("type") == "text")
                            elif isinstance(content, str):
                                text = content
                        if text and pattern.search(text) and len(matched) < 2:
                            snippet = text[:100].replace("|", "/").replace("\n", " ").strip()
                            if snippet:
                                matched.append(snippet)
            except (json.JSONDecodeError, IOError):
                continue
            if matched:
                meta = file_meta(fpath)
                first_ts = meta["created"].timestamp() * 1000 if meta else 0
                results[sid] = {
                    "project": proj_dir,
                    "project_path": proj_dir,
                    "first_ts": first_ts,
                    "matched": matched,
                }
    return results


def print_results(sessions, query, deep=False):
    """Print search results as table + matched messages."""
    results = []
    for sid, info in sessions.items():
        proj_dir = project_dir_name(info["project_path"])
        sf = session_file_path(proj_dir, sid)
        meta = file_meta(sf)
        if not meta:
            # Try direct path for deep search results
            alt_path = os.path.join(PROJECTS_DIR, info["project_path"], f"{sid}.jsonl")
            meta = file_meta(alt_path)
        start_time = datetime.datetime.fromtimestamp(info["first_ts"] / 1000).strftime("%Y-%m-%d %H:%M") if info["first_ts"] else "-"
        duration = meta["duration_str"] if meta else "-"
        size_str = meta["size_str"] if meta else "-"
        proj_name = info.get("project", "-")
        results.append((start_time, proj_name, sid[:8], duration, size_str, info["matched"]))

    results.sort(key=lambda x: x[0], reverse=True)

    mode = "deep" if deep else "display"
    print(f'## "{query}" 검색 결과 ({len(results)}개 세션, mode: {mode})\n')

    if not results:
        print("매칭되는 세션이 없습니다.")
        return

    print("| # | 프로젝트 | 세션 ID | 시작 | Duration | 크기 |")
    print("|---|----------|---------|------|----------|------|")
    for i, (start, proj, sid, dur, size, matched) in enumerate(results, 1):
        print(f"| {i} | {proj} | {sid} | {start} | {dur} | {size} |")
        for m in matched[:2]:
            print(f"|   | ↳ {m} |||||")
    print()


def main():
    args = sys.argv[1:]
    if not args:
        print("사용법: python3 search.py [--deep] <query>")
        print("  <query>       display 필드에서 검색 (대소문자 무시)")
        print("  --deep        세션 JSONL 내부까지 검색")
        raise SystemExit(0)

    deep = False
    if "--deep" in args:
        deep = True
        args.remove("--deep")

    if not args:
        print("ERROR: 검색 쿼리를 입력해주세요.")
        raise SystemExit(1)

    query = " ".join(args)

    display_results = search_display(query)

    if deep:
        deep_results = search_deep(query, set(display_results.keys()))
        all_results = {**display_results, **deep_results}
        print_results(all_results, query, deep=True)
    else:
        print_results(display_results, query)


if __name__ == "__main__":
    main()
