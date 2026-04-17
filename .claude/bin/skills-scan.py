#!/usr/bin/env python3
"""Skill scanner: SKILL.md 파일 → JSON index + markdown catalog."""

from __future__ import annotations

import re
from pathlib import Path


FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)


def parse_frontmatter(path: Path) -> dict:
    """Parse SKILL.md frontmatter. Returns dict with name/description/parse_error."""
    try:
        content = path.read_text(encoding="utf-8")
    except OSError as exc:
        return {"name": None, "description": None, "parse_error": True, "error": str(exc)}

    match = FRONTMATTER_RE.match(content)
    if not match:
        return {"name": None, "description": None, "parse_error": True, "error": "no frontmatter"}

    block = match.group(1)
    fields = {}
    for line in block.splitlines():
        if ":" not in line:
            continue
        key, _, value = line.partition(":")
        fields[key.strip()] = value.strip()

    if "name" not in fields:
        return {"name": None, "description": None, "parse_error": True, "error": "missing name"}

    return {
        "name": fields.get("name"),
        "description": fields.get("description", ""),
        "parse_error": False,
    }


if __name__ == "__main__":
    import sys
    print("Not implemented yet", file=sys.stderr)
    sys.exit(1)
