#!/usr/bin/env python3
"""Skill audit: usage log + catalog → top/unused/overlap report."""

from __future__ import annotations

import json
import re
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


STOPWORDS = {
    "the", "a", "an", "and", "or", "for", "to", "of", "in", "on", "at",
    "is", "are", "was", "were", "be", "been", "with", "from", "use", "used",
    "this", "that", "these", "those", "it", "its", "as", "by", "can", "not",
    "및", "등", "으로", "에서", "하는", "하고", "또는",
}


def _tokenize(text: str) -> set[str]:
    tokens = re.findall(r"[\w가-힣]+", text.lower())
    return {t for t in tokens if len(t) >= 3 and t not in STOPWORDS}


def _jaccard(a: set, b: set) -> float:
    if not a and not b:
        return 0.0
    return len(a & b) / len(a | b)


def compute_overlap(catalog: dict, threshold: float = 0.7) -> list[dict]:
    """Find skill pairs whose description token overlap ≥ threshold."""
    skills = catalog.get("skills", [])
    results = []
    tokens_cache = {
        _catalog_skill_id(s): _tokenize(s.get("description", ""))
        for s in skills
    }

    ids = sorted(tokens_cache)
    for i, a_id in enumerate(ids):
        a_tokens = tokens_cache[a_id]
        for b_id in ids[i + 1:]:
            b_tokens = tokens_cache[b_id]
            sim = _jaccard(a_tokens, b_tokens)
            if sim >= threshold:
                shared = sorted(a_tokens & b_tokens)[:8]
                results.append({
                    "pair": [a_id, b_id],
                    "similarity": round(sim, 3),
                    "shared_keywords": shared,
                })
    results.sort(key=lambda x: -x["similarity"])
    return results


if __name__ == "__main__":
    import sys
    print("Not implemented yet", file=sys.stderr)
    sys.exit(1)
