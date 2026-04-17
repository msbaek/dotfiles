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


def format_report(report: dict, mode: str = "text") -> str:
    if mode == "json":
        return json.dumps(report, indent=2, ensure_ascii=False)

    lines = [
        f"# Skills Audit — last {report['period_days']} days",
        f"Total calls: {report['total_calls']}",
        "",
        "## Top Skills",
    ]
    if not report["top"]:
        lines.append("  (none)")
    for item in report["top"]:
        lines.append(f"  {item['calls']:4d}  {item['skill']}  (last: {item['last']})")

    lines.append("")
    lines.append("## Unused")
    if not report["unused"]:
        lines.append("  (none)")
    for item in report["unused"]:
        last = item["last"] or "never"
        lines.append(f"  - {item['skill']}  (last: {last})")

    lines.append("")
    lines.append("## Overlap")
    if not report["overlap"]:
        lines.append("  (none)")
    for item in report["overlap"]:
        a, b = item["pair"]
        lines.append(f"  {item['similarity']:.2f}  {a} ↔ {b}  shared: {', '.join(item['shared_keywords'])}")

    lines.append("")
    lines.append("## Stale (mtime > 6mo + 0 calls)")
    if not report["stale"]:
        lines.append("  (none)")
    for item in report["stale"]:
        lines.append(f"  - {item['skill']}  (mtime: {item['mtime']})")

    return "\n".join(lines)


USAGE_PATH = Path.home() / ".claude" / "logs" / "skills-usage.jsonl"
INDEX_PATH = Path.home() / ".claude" / "skills-index.json"


def _build_report(days: int, threshold: float) -> dict:
    events = load_usage(USAGE_PATH)
    agg = aggregate(events)

    catalog = {"skills": []}
    if INDEX_PATH.exists():
        catalog = json.loads(INDEX_PATH.read_text(encoding="utf-8"))

    return {
        "period_days": days,
        "total_calls": sum(s["calls"] for s in agg.values()),
        "top": compute_top(agg, n=10),
        "unused": compute_unused(agg, catalog, days=days),
        "overlap": compute_overlap(catalog, threshold=threshold),
        "stale": compute_stale(agg, catalog, months=6),
    }


if __name__ == "__main__":
    import argparse
    import sys
    parser = argparse.ArgumentParser(description="Skill usage audit")
    parser.add_argument("--days", type=int, default=30, help="lookback window in days")
    parser.add_argument("--overlap-threshold", type=float, default=0.7)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--unused-only", action="store_true")
    args = parser.parse_args()

    report = _build_report(args.days, args.overlap_threshold)

    if args.unused_only:
        report = {k: v for k, v in report.items() if k in ("period_days", "unused")}
        report["top"] = []
        report["overlap"] = []
        report["stale"] = []
        report["total_calls"] = 0

    print(format_report(report, mode="json" if args.json else "text"))
    sys.exit(0)
