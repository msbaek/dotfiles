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


def find_skill_files(roots: list[Path]) -> list[Path]:
    """Walk roots recursively, return all SKILL.md files found."""
    results = []
    for root in roots:
        if not root.exists():
            continue
        for path in root.rglob("SKILL.md"):
            if path.is_file():
                results.append(path)
    return sorted(results)


CATEGORY_PREFIXES = {
    "obsidian": ["obsidian:", "obsidian-"],
    "databricks": ["databricks-", "databricks:"],
    "tdd": ["tdd-", ":tdd-", "msbaek-tdd:", "tdp:"],
    "superpowers": ["superpowers:"],
    "mlflow": ["mlflow-", "-mlflow"],
    "plugin-dev": ["plugin-dev:"],
    "augmented": ["augmented:"],
    "caveman": ["caveman", ":caveman"],
    "atlassian": ["atlassian:", "jira"],
    "github": ["github", "gh"],
}

CATEGORY_KEYWORDS = {
    "git": ["git", "commit", "branch"],
    "test": ["test", "unittest", "pytest"],
    "docs": ["documentation", "readme", "api reference"],
    "debug": ["debug", "troubleshoot"],
}


def infer_category(name: str, description: str) -> str:
    """Infer category from skill name prefix or description keywords."""
    lower_name = name.lower()
    for category, prefixes in CATEGORY_PREFIXES.items():
        if any(lower_name.startswith(p) or p in lower_name for p in prefixes):
            return category

    lower_desc = description.lower()
    for category, keywords in CATEGORY_KEYWORDS.items():
        if any(kw in lower_desc for kw in keywords):
            return category

    return "uncategorized"


if __name__ == "__main__":
    import sys
    print("Not implemented yet", file=sys.stderr)
    sys.exit(1)
