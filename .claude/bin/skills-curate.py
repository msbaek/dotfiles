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


UNUSED_CHOICES = {
    "k": ("keep", False),
    "a": ("archive", False),
    "d": ("delete", False),
    "n": ("note", True),     # requires follow-up text
    "s": (None, False),
}

OVERLAP_CHOICES = {
    "m": ("merge", False),
    "k1": ("keep_first", False),
    "k2": ("keep_second", False),
    "d": ("distinct", True),    # note recommended
    "s": (None, False),
}


def _ask(responder, question: str) -> str:
    return responder(question).strip().lower()


def prompt_unused(item: dict, responder=input) -> tuple[str | None, str]:
    """Prompt user about one unused skill. Returns (decision, note)."""
    prompt = (
        f"Unused: {item['skill']}\n"
        f"  last call: {item.get('last') or 'never'}\n"
        f"  mtime:     {item.get('mtime')}\n"
        f"  (k)eep  (a)rchive  (d)elete  (n)ote  (s)kip\n"
        f"> "
    )
    choice = _ask(responder, prompt)
    if choice not in UNUSED_CHOICES:
        return None, ""

    decision, needs_note = UNUSED_CHOICES[choice]
    note = ""
    if decision is not None:
        note_raw = responder("  note (enter to skip): ") if not needs_note else responder("  note: ")
        note = note_raw.strip()
        if decision == "note" and not note:
            note = "(no note)"
    return decision, note


def prompt_overlap(item: dict, responder=input) -> tuple[str | None, str]:
    """Prompt user about one overlap pair. Returns (decision, note)."""
    a, b = item["pair"]
    prompt = (
        f"Overlap: {a} ↔ {b}  (similarity: {item['similarity']:.2f})\n"
        f"  shared: {', '.join(item.get('shared_keywords', []))}\n"
        f"  (m)erge  (k1) keep {a}  (k2) keep {b}  (d)istinct  (s)kip\n"
        f"> "
    )
    choice = _ask(responder, prompt)
    if choice not in OVERLAP_CHOICES:
        return None, ""

    decision, needs_note = OVERLAP_CHOICES[choice]
    note = ""
    if decision is not None:
        note_raw = responder("  note (enter to skip): ") if not needs_note else responder("  note: ")
        note = note_raw.strip()
    return decision, note


if __name__ == "__main__":
    import sys
    print("Not implemented yet", file=sys.stderr)
    sys.exit(1)
