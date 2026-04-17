#!/usr/bin/env python3
"""Skill audit: usage log + catalog → top/unused/overlap report."""

from __future__ import annotations

import json
from collections import defaultdict
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


if __name__ == "__main__":
    import sys
    print("Not implemented yet", file=sys.stderr)
    sys.exit(1)
