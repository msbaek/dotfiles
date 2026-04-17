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


from collections import defaultdict
from datetime import datetime, timezone


def _classify_source(path: Path) -> tuple[str, str | None]:
    """Determine (source, plugin_name) from path."""
    parts = path.parts
    if "plugins" in parts and "cache" in parts:
        try:
            idx = parts.index("cache")
            plugin = parts[idx + 2] if idx + 2 < len(parts) else None
            return "plugin", plugin
        except (ValueError, IndexError):
            return "plugin", None
    return "user", None


def build_index(roots: list[Path]) -> dict:
    """Scan roots and build the full skill index dict."""
    paths = find_skill_files(roots)
    skills = []
    source_counts: dict[str, int] = defaultdict(int)

    for path in paths:
        parsed = parse_frontmatter(path)
        source, plugin = _classify_source(path)
        source_counts[source] += 1

        name = parsed.get("name") or path.parent.name
        description = parsed.get("description") or ""
        prefixed_name = f"{plugin}:{name}" if plugin else name

        skills.append({
            "id": f"{source}/{prefixed_name}",
            "name": name,
            "source": source,
            "plugin": plugin,
            "path": str(path).replace(str(Path.home()), "~"),
            "description": description,
            "category": infer_category(prefixed_name, description),
            "mtime": datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc).isoformat(),
            "parse_error": parsed.get("parse_error", False),
        })

    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "total": len(skills),
        "sources": dict(source_counts),
        "skills": skills,
    }


def render_markdown(index: dict) -> str:
    """Render index dict to markdown catalog."""
    lines = [
        "# Skills Index",
        "",
        f"_Generated: {index['generated_at']}_",
        f"_Total: {index['total']} skills_",
        "",
    ]

    by_category: dict[str, list] = defaultdict(list)
    for skill in index["skills"]:
        by_category[skill["category"]].append(skill)

    for category in sorted(by_category):
        lines.append(f"## {category}")
        lines.append("")
        for skill in sorted(by_category[category], key=lambda s: s["name"]):
            prefix = "⚠️ " if skill["parse_error"] else ""
            desc_preview = skill["description"][:120]
            if len(skill["description"]) > 120:
                desc_preview += "..."
            lines.append(f"- **{prefix}{skill['name']}** ({skill['source']}) — {desc_preview}")
        lines.append("")

    return "\n".join(lines)


DEFAULT_ROOTS = [
    Path.home() / ".claude" / "skills",
    Path.home() / ".claude" / "plugins" / "cache",
]
INDEX_JSON = Path.home() / ".claude" / "skills-index.json"
INDEX_MD = Path.home() / ".claude" / "SKILLS-INDEX.md"


def _cmd_default(args) -> int:
    index = build_index(DEFAULT_ROOTS)
    import json
    INDEX_JSON.write_text(json.dumps(index, indent=2, ensure_ascii=False), encoding="utf-8")
    INDEX_MD.write_text(render_markdown(index), encoding="utf-8")
    print(f"Wrote {INDEX_MD} ({index['total']} skills)")
    return 0


def _cmd_json(args) -> int:
    import json
    index = build_index(DEFAULT_ROOTS)
    print(json.dumps(index, indent=2, ensure_ascii=False))
    return 0


def _cmd_diff(args) -> int:
    import json
    if not INDEX_JSON.exists():
        print("No previous index. Run scanner first.")
        return 1
    prev = json.loads(INDEX_JSON.read_text(encoding="utf-8"))
    curr = build_index(DEFAULT_ROOTS)
    prev_ids = {s["id"] for s in prev["skills"]}
    curr_ids = {s["id"] for s in curr["skills"]}
    added = sorted(curr_ids - prev_ids)
    removed = sorted(prev_ids - curr_ids)
    print(f"Added ({len(added)}):")
    for s in added:
        print(f"  + {s}")
    print(f"Removed ({len(removed)}):")
    for s in removed:
        print(f"  - {s}")
    return 0


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Skill catalog scanner")
    parser.add_argument("--json", action="store_true", help="print JSON to stdout")
    parser.add_argument("--diff", action="store_true", help="compare with previous index")
    args = parser.parse_args()

    import sys
    if args.json:
        sys.exit(_cmd_json(args))
    if args.diff:
        sys.exit(_cmd_diff(args))
    sys.exit(_cmd_default(args))
