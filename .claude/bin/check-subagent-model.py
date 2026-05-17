#!/usr/bin/env python3
"""Audit recent sub-agent JSONL files and show which model was actually used.

Usage:
    check-subagent-model.py [project-path] [-f NAME] [--last N] [--no-color]

Options:
    project-path     Optional Claude project key path (default: scan all projects)
    -f, --folder     Filter by cwd substring (e.g. "BO-query", "vault-intelligence")
    --last N         Number of most recent sub-agent files to inspect (default 10)
    --no-color       Disable ANSI colors (also honors NO_COLOR env var)
"""

import argparse
import glob
import json
import os
import re
import sys
from datetime import datetime

PROJECT_ROOT = "/Users/msbaek/.claude/projects"
HOME = os.path.expanduser("~")

# Cache of main JSONL timeline: path -> [(timestamp, model), ...]
_MAIN_TIMELINE_CACHE: dict[str, list[tuple[str | None, str]]] = {}


def make_palette(enabled: bool):
    """Return an ANSI color palette. Empty strings when disabled."""
    if not enabled:
        keys = ["R", "B", "D", "I", "RED", "GRN", "YEL", "BLU", "MAG", "CYN",
                "GRY", "BR_GRN", "BR_YEL", "BR_CYN", "BR_MAG"]
        return {k: "" for k in keys}
    return {
        "R": "\033[0m", "B": "\033[1m", "D": "\033[2m", "I": "\033[3m",
        "RED": "\033[31m", "GRN": "\033[32m", "YEL": "\033[33m",
        "BLU": "\033[34m", "MAG": "\033[35m", "CYN": "\033[36m",
        "GRY": "\033[90m",
        "BR_GRN": "\033[92m", "BR_YEL": "\033[93m",
        "BR_CYN": "\033[96m", "BR_MAG": "\033[95m",
    }


def short_path(p: str) -> str:
    if not p:
        return "?"
    return ("~" + p[len(HOME):]) if p.startswith(HOME) else p


def model_chip(model: str, c) -> str:
    if "sonnet" in model:
        ver = model.split("sonnet-")[-1].split("-")[0]
        return f"{c['BR_GRN']}{c['B']}✅ sonnet-{ver}{c['R']}"
    if "opus" in model:
        ver = model.split("opus-")[-1].split("-")[0]
        return f"{c['BR_YEL']}{c['B']}⚠️  opus-{ver}{c['R']}"
    if "haiku" in model:
        ver = model.split("haiku-")[-1].split("-")[0]
        return f"{c['BR_CYN']}ℹ️  haiku-{ver}{c['R']}"
    return f"{c['GRY']}{model}{c['R']}"


def _get_cwd_fast(path: str) -> str | None:
    """Scan up to N initial JSONL lines for cwd.

    Sub-agent JSONLs have cwd on line 1, but main JSONLs may start with
    a `permission-mode` meta entry that lacks cwd; the real cwd appears on
    a later line. We bound the read to avoid pathological cases.
    """
    try:
        with open(path) as f:
            for _ in range(20):
                line = f.readline()
                if not line:
                    return None
                try:
                    d = json.loads(line)
                except json.JSONDecodeError:
                    continue
                cwd = d.get("cwd")
                if cwd:
                    return cwd
    except OSError:
        pass
    return None


def collect_files(project_path: str | None, folder_filter: str | None,
                  last_n: int, include_main: bool
                  ) -> list[tuple[str, str]]:
    """Return list of (path, kind) where kind is 'sub' or 'main'."""
    if project_path:
        base = project_path.rstrip("/")
        sub_patterns = [f"{base}/subagents/agent-*.jsonl",
                        f"{base}/*/subagents/agent-*.jsonl"]
        main_patterns = [f"{base}/*.jsonl"]
    else:
        sub_patterns = [f"{PROJECT_ROOT}/*/subagents/agent-*.jsonl",
                        f"{PROJECT_ROOT}/*/*/subagents/agent-*.jsonl"]
        main_patterns = [f"{PROJECT_ROOT}/*/*.jsonl"]

    pairs: list[tuple[str, str]] = []
    seen = set()
    for pat in sub_patterns:
        for p in glob.glob(pat):
            if p not in seen:
                seen.add(p); pairs.append((p, "sub"))
    if include_main:
        for pat in main_patterns:
            for p in glob.glob(pat):
                # Skip sub-agent files that the */*.jsonl glob may also catch
                if "/subagents/" in p or p in seen:
                    continue
                seen.add(p); pairs.append((p, "main"))

    pairs.sort(key=lambda x: os.path.getmtime(x[0]), reverse=True)

    if folder_filter:
        matched: list[tuple[str, str]] = []
        for p, kind in pairs:
            cwd = _get_cwd_fast(p)
            if cwd and folder_filter in cwd:
                matched.append((p, kind))
                if len(matched) >= last_n:
                    break
        return matched

    return pairs[:last_n]


def parse_jsonl(path: str) -> dict:
    """Extract first-seen metadata + model set + first user task from a JSONL file."""
    info = {"models": set(), "cwd": None, "git_branch": None, "slug": None,
            "first_task": None, "first_ts": None, "session_id": None}
    try:
        with open(path) as f:
            for line in f:
                try:
                    d = json.loads(line)
                except json.JSONDecodeError:
                    continue
                m = d.get("model") or (d.get("message") or {}).get("model")
                if m:
                    info["models"].add(m)
                if info["cwd"] is None:
                    info["cwd"] = d.get("cwd")
                    info["git_branch"] = d.get("gitBranch")
                    info["slug"] = d.get("slug")
                    info["first_ts"] = d.get("timestamp")
                    info["session_id"] = d.get("sessionId")
                if info["first_task"] is None and d.get("type") == "user":
                    msg = d.get("message", {})
                    content = msg.get("content") if isinstance(msg, dict) else None
                    if isinstance(content, str):
                        info["first_task"] = content
                    elif isinstance(content, list):
                        for block in content:
                            if isinstance(block, dict) and block.get("type") == "text":
                                info["first_task"] = block.get("text", "")
                                break
    except OSError as e:
        info["models"].add(f"(읽기 실패: {e})")
    return info


def _main_jsonl_path(sub_path: str) -> str:
    """Derive main session JSONL path from sub-agent JSONL path.

    {project_dir}/{sessionId}/subagents/agent-XXX.jsonl
        → {project_dir}/{sessionId}.jsonl
    """
    return re.sub(r"/subagents/agent-[^/]+\.jsonl$", ".jsonl", sub_path)


def _load_main_timeline(main_path: str) -> list[tuple[str | None, str]]:
    """Return cached (timestamp, model) timeline from a main JSONL."""
    if main_path in _MAIN_TIMELINE_CACHE:
        return _MAIN_TIMELINE_CACHE[main_path]
    timeline: list[tuple[str | None, str]] = []
    if os.path.exists(main_path):
        try:
            with open(main_path) as f:
                for line in f:
                    try:
                        d = json.loads(line)
                    except json.JSONDecodeError:
                        continue
                    m = d.get("model") or (d.get("message") or {}).get("model")
                    if m:
                        timeline.append((d.get("timestamp"), m))
        except OSError:
            pass
    _MAIN_TIMELINE_CACHE[main_path] = timeline
    return timeline


def get_main_model(sub_path: str, before_ts: str | None) -> str | None:
    """Find the main-agent model in effect immediately before `before_ts`."""
    timeline = _load_main_timeline(_main_jsonl_path(sub_path))
    last_model = None
    for ts, model in timeline:
        if before_ts and ts and ts > before_ts:
            break
        last_model = model
    # If no before_ts or no match yet, fall back to the latest known model
    return last_model or (timeline[-1][1] if timeline else None)


def render(files: list[tuple[str, str]], last_n: int,
           folder_filter: str | None, include_main: bool, c) -> None:
    print()
    print(f"{c['D']}{'─' * 70}{c['R']}")
    title = "Agent Model Audit" if include_main else "Sub-agent Model Audit"
    header = f"  {c['B']}{title}{c['R']}  {c['D']}(latest {last_n}"
    if folder_filter:
        header += f", folder ~ {c['R']}{c['MAG']}{folder_filter}{c['D']}"
    if include_main:
        header += ", main+sub"
    header += f"){c['R']}"
    print(header)
    print(f"{c['D']}{'─' * 70}{c['R']}")
    print()

    if not files:
        print("  JSONL 파일을 찾을 수 없습니다.\n")
        return

    for i, (path, kind) in enumerate(files, 1):
        info = parse_jsonl(path)
        mtime = datetime.fromtimestamp(os.path.getmtime(path)).strftime("%m-%d %H:%M")

        if kind == "sub":
            agent_id = os.path.basename(path).replace("agent-", "").replace(".jsonl", "")[:12]
            kind_tag = f"{c['CYN']}[sub] {c['R']}"
            sub_models = ", ".join(model_chip(m, c) for m in sorted(info["models"])) \
                if info["models"] else f"{c['GRY']}(없음){c['R']}"
            main_model = get_main_model(path, info["first_ts"])
            main_chip = model_chip(main_model, c) if main_model else f"{c['GRY']}(없음){c['R']}"
            model_line = (f"       {c['D']}main{c['R']} {main_chip}  "
                          f"{c['D']}→ sub{c['R']} {sub_models}")
        else:  # main
            agent_id = os.path.basename(path).replace(".jsonl", "")[:12]
            kind_tag = f"{c['MAG']}[main]{c['R']}"
            models_str = ", ".join(model_chip(m, c) for m in sorted(info["models"])) \
                if info["models"] else f"{c['GRY']}(없음){c['R']}"
            model_line = f"       {c['D']}main{c['R']} {models_str}"

        task_line = ""
        if info["first_task"]:
            first = info["first_task"].strip().splitlines()[0]
            task_line = first[:80] + ("…" if len(first) > 80 else "")

        proj = short_path(info["cwd"]) if info["cwd"] else "?"
        branch = (f" {c['MAG']}({info['git_branch']}){c['R']}"
                  if info["git_branch"] and info["git_branch"] != "main" else "")

        print(f"  {c['D']}{i:>2}.{c['R']} {c['GRY']}{mtime}{c['R']}  "
              f"{kind_tag} {c['D']}{agent_id}{c['R']}")
        print(model_line)
        print(f"       {c['BLU']}📁 {proj}{c['R']}{branch}")
        if task_line:
            print(f"       {c['D']}└─{c['R']} {c['I']}{task_line}{c['R']}")
        print()


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Audit recent sub-agent calls and report actual model used."
    )
    parser.add_argument("project_path", nargs="?", default=None,
                        help="Optional Claude project key path "
                             "(default: scan all projects)")
    parser.add_argument("-f", "--folder", default=None,
                        help="Filter by cwd substring "
                             "(e.g. 'BO-query', 'vault-intelligence')")
    parser.add_argument("--last", type=int, default=10,
                        help="Number of recent sub-agent files (default 10)")
    parser.add_argument("--include-main", action="store_true",
                        help="Also include main session JSONLs (not just sub-agents). "
                             "Useful when a project had main-only activity today.")
    parser.add_argument("--no-color", action="store_true",
                        help="Disable ANSI colors")
    args = parser.parse_args()

    color_enabled = (not args.no_color
                     and "NO_COLOR" not in os.environ
                     and sys.stdout.isatty())
    palette = make_palette(color_enabled)
    files = collect_files(args.project_path, args.folder, args.last,
                          args.include_main)
    render(files, args.last, args.folder, args.include_main, palette)
    return 0


if __name__ == "__main__":
    sys.exit(main())
