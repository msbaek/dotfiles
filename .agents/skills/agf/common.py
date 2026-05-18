#!/usr/bin/env python3
"""agf common - shared utilities for agf skill scripts"""

import json, os, datetime, re

HISTORY = os.path.expanduser("~/.claude/history.jsonl")
PROJECTS_DIR = os.path.expanduser("~/.claude/projects")


def load_history(date=None):
    """Load history.jsonl entries, optionally filtered by date string (YYYY-MM-DD).
    Returns list of parsed JSON objects."""
    if not os.path.exists(HISTORY):
        return []
    with open(HISTORY) as f:
        lines = f.readlines()
    if date is None:
        return [json.loads(line) for line in lines]
    y, m, d = int(date[:4]), int(date[5:7]), int(date[8:10])
    t_start = datetime.datetime(y, m, d).timestamp() * 1000
    t_end = t_start + 86400000
    results = []
    for line in lines:
        obj = json.loads(line)
        if t_start <= obj.get("timestamp", 0) < t_end:
            results.append(obj)
    return results


def project_dir_name(project_path):
    """Convert project path to directory name (non-alphanumeric -> '-')."""
    return re.sub(r'[^a-zA-Z0-9]', '-', project_path)


def session_file_path(proj_dir, sid):
    """Return full path to session JSONL file."""
    return os.path.join(PROJECTS_DIR, proj_dir, f"{sid}.jsonl")


def file_meta(path):
    """Return file metadata dict: created, modified, duration_str, size_str.
    Returns None if file doesn't exist."""
    if not os.path.exists(path):
        return None
    stat = os.stat(path)
    created = datetime.datetime.fromtimestamp(stat.st_birthtime)
    modified = datetime.datetime.fromtimestamp(stat.st_mtime)
    delta = modified - created
    hours, remainder = divmod(int(delta.total_seconds()), 3600)
    minutes = remainder // 60
    size_mb = stat.st_size / (1024 * 1024)
    return {
        "created": created,
        "modified": modified,
        "duration_str": f"{hours}h {minutes:02d}m",
        "size_str": f"{size_mb:.1f}MB",
        "start_time": created.strftime("%H:%M"),
    }
