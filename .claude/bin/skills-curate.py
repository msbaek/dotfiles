#!/usr/bin/env python3
"""Skill curate: interactive cleanup based on audit report."""

from __future__ import annotations

import re
from pathlib import Path


DECISION_RE = re.compile(r"^- \[(\w+)\] ([^—]+?)\s+—", re.MULTILINE)


def append_decision(path: Path, date: str, decision: str, skill: str, note: str) -> None:
    """Append a decision entry to decisions log. Reuses date header if present."""
    path.parent.mkdir(parents=True, exist_ok=True)
    header = f"## {date}"
    line = f"- [{decision}] {skill} — {note}"

    if path.exists():
        existing = path.read_text(encoding="utf-8")
    else:
        existing = "# Skill Curation Log\n"

    if header in existing:
        idx = existing.rindex(header)
        end = existing.find("\n## ", idx + len(header))
        if end == -1:
            updated = existing.rstrip() + f"\n{line}\n"
        else:
            updated = existing[:end].rstrip() + f"\n{line}\n" + existing[end:]
    else:
        separator = "" if existing.endswith("\n\n") else ("\n" if existing.endswith("\n") else "\n\n")
        updated = existing + f"{separator}{header}\n{line}\n"

    path.write_text(updated, encoding="utf-8")


def load_decisions(path: Path) -> dict[str, str]:
    """Parse decisions log → {skill: last_decision}. Later entries override earlier."""
    if not path.exists():
        return {}
    result: dict[str, str] = {}
    for match in DECISION_RE.finditer(path.read_text(encoding="utf-8")):
        decision = match.group(1)
        skill = match.group(2).strip()
        result[skill] = decision
    return result


if __name__ == "__main__":
    import sys
    print("Not implemented yet", file=sys.stderr)
    sys.exit(1)
