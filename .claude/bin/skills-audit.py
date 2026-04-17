#!/usr/bin/env python3
"""Skill audit: usage log + catalog → top/unused/overlap report."""

from __future__ import annotations

import json
from collections import defaultdict
from datetime import datetime, timedelta, timezone
from pathlib import Path


def load_usage(path: Path) -> list[dict]:
    """Load JSONL usage log, skipping malformed lines."""
    if not path.exists():
        return []
    events = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            events.append(json.loads(line))
        except json.JSONDecodeError:
            continue
    return events


def aggregate(events: list[dict]) -> dict[str, dict]:
    """Aggregate events by skill name. Returns {skill: {calls, last}}."""
    result: dict[str, dict] = defaultdict(lambda: {"calls": 0, "last": None})
    for event in events:
        skill = event.get("skill")
        ts = event.get("ts")
        if not skill:
            continue
        result[skill]["calls"] += 1
        if ts and (result[skill]["last"] is None or ts > result[skill]["last"]):
            result[skill]["last"] = ts
    return dict(result)


def _parse_ts(ts: str | None) -> datetime | None:
    if not ts:
        return None
    try:
        return datetime.fromisoformat(ts.replace("Z", "+00:00"))
    except ValueError:
        return None


def _now(now: str | None) -> datetime:
    if now:
        dt = _parse_ts(now)
        if dt:
            return dt
    return datetime.now(tz=timezone.utc)


def compute_top(agg: dict[str, dict], n: int = 10) -> list[dict]:
    """Return top-N skills sorted by call count desc."""
    items = [
        {"skill": skill, "calls": stats["calls"], "last": stats["last"]}
        for skill, stats in agg.items()
    ]
    items.sort(key=lambda x: (-x["calls"], x["skill"]))
    return items[:n]


def _catalog_skill_id(skill: dict) -> str:
    """Reconstruct the skill id as logged (plugin:name or plain name)."""
    if skill.get("plugin"):
        return f"{skill['plugin']}:{skill['name']}"
    return skill["name"]


def compute_unused(agg: dict, catalog: dict, days: int = 30, now: str | None = None) -> list[dict]:
    """Return catalog skills with no call or last call > days ago."""
    cutoff = _now(now) - timedelta(days=days)
    result = []
    for skill in catalog.get("skills", []):
        skill_id = _catalog_skill_id(skill)
        stats = agg.get(skill_id)
        last = _parse_ts(stats["last"]) if stats else None
        if last is None or last < cutoff:
            result.append({
                "skill": skill_id,
                "last": stats["last"] if stats else None,
                "mtime": skill.get("mtime"),
            })
    return result


def compute_stale(agg: dict, catalog: dict, months: int = 6, now: str | None = None) -> list[dict]:
    """Return catalog skills whose mtime is older than N months AND have zero calls."""
    cutoff = _now(now) - timedelta(days=months * 30)
    result = []
    for skill in catalog.get("skills", []):
        skill_id = _catalog_skill_id(skill)
        if skill_id in agg and agg[skill_id]["calls"] > 0:
            continue
        mtime = _parse_ts(skill.get("mtime"))
        if mtime is None or mtime < cutoff:
            result.append({
                "skill": skill_id,
                "mtime": skill.get("mtime"),
                "calls": 0,
            })
    return result


if __name__ == "__main__":
    import sys
    print("Not implemented yet", file=sys.stderr)
    sys.exit(1)
