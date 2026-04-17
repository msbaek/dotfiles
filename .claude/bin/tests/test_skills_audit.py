import sys
import unittest
from pathlib import Path
from datetime import datetime, timezone

sys.path.insert(0, str(Path(__file__).parent.parent))

import importlib.util
spec = importlib.util.spec_from_file_location(
    "skills_audit",
    str(Path(__file__).parent.parent / "skills-audit.py")
)
skills_audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(skills_audit)

USAGE = Path(__file__).parent / "fixtures" / "usage-sample.jsonl"


class TestLoadUsage(unittest.TestCase):
    def test_load_returns_list_of_dicts(self):
        events = skills_audit.load_usage(USAGE)
        self.assertEqual(len(events), 6)
        self.assertEqual(events[0]["skill"], "superpowers:brainstorming")

    def test_load_missing_file_returns_empty(self):
        events = skills_audit.load_usage(Path("/nonexistent.jsonl"))
        self.assertEqual(events, [])

    def test_load_skips_malformed_lines(self):
        import tempfile
        with tempfile.NamedTemporaryFile(mode="w", suffix=".jsonl", delete=False) as f:
            f.write('{"ts":"2026-04-01T00:00:00Z","skill":"ok"}\n')
            f.write("not json\n")
            f.write('{"ts":"2026-04-02T00:00:00Z","skill":"also-ok"}\n')
            path = Path(f.name)
        try:
            events = skills_audit.load_usage(path)
            self.assertEqual(len(events), 2)
        finally:
            path.unlink()


class TestAggregate(unittest.TestCase):
    def test_aggregate_counts_calls_per_skill(self):
        events = skills_audit.load_usage(USAGE)
        agg = skills_audit.aggregate(events)
        self.assertEqual(agg["superpowers:brainstorming"]["calls"], 3)
        self.assertEqual(agg["obsidian:summarize-article"]["calls"], 2)
        self.assertEqual(agg["graphify"]["calls"], 1)

    def test_aggregate_tracks_last_call(self):
        events = skills_audit.load_usage(USAGE)
        agg = skills_audit.aggregate(events)
        self.assertEqual(agg["superpowers:brainstorming"]["last"], "2026-04-15T11:00:00Z")


SAMPLE_CATALOG = {
    "skills": [
        {"id": "user/superpowers:brainstorming", "name": "superpowers:brainstorming",
         "source": "plugin", "plugin": "superpowers", "description": "x",
         "mtime": "2026-03-01T00:00:00+00:00", "parse_error": False,
         "category": "superpowers", "path": "~/.claude/..."},
        {"id": "user/graphify", "name": "graphify",
         "source": "user", "plugin": None, "description": "x",
         "mtime": "2026-01-01T00:00:00+00:00", "parse_error": False,
         "category": "uncategorized", "path": "~/.claude/..."},
        {"id": "user/unused-skill", "name": "unused-skill",
         "source": "user", "plugin": None, "description": "x",
         "mtime": "2025-10-01T00:00:00+00:00", "parse_error": False,
         "category": "uncategorized", "path": "~/.claude/..."},
        {"id": "user/obsidian:summarize-article", "name": "obsidian:summarize-article",
         "source": "plugin", "plugin": "obsidian", "description": "x",
         "mtime": "2026-02-01T00:00:00+00:00", "parse_error": False,
         "category": "obsidian", "path": "~/.claude/..."},
    ]
}


class TestComputeTop(unittest.TestCase):
    def test_top_n_by_calls(self):
        agg = skills_audit.aggregate(skills_audit.load_usage(USAGE))
        top = skills_audit.compute_top(agg, n=2)
        self.assertEqual(len(top), 2)
        self.assertEqual(top[0]["skill"], "superpowers:brainstorming")
        self.assertEqual(top[0]["calls"], 3)


class TestComputeUnused(unittest.TestCase):
    def test_unused_includes_catalog_not_in_usage(self):
        agg = skills_audit.aggregate(skills_audit.load_usage(USAGE))
        unused = skills_audit.compute_unused(agg, SAMPLE_CATALOG, days=30, now="2026-04-17T12:00:00Z")
        names = {u["skill"] for u in unused}
        self.assertIn("unused-skill", names)

    def test_unused_excludes_recently_used(self):
        agg = skills_audit.aggregate(skills_audit.load_usage(USAGE))
        unused = skills_audit.compute_unused(agg, SAMPLE_CATALOG, days=30, now="2026-04-17T12:00:00Z")
        names = {u["skill"] for u in unused}
        self.assertNotIn("superpowers:brainstorming", names)


class TestComputeStale(unittest.TestCase):
    def test_stale_mtime_old_and_no_calls(self):
        agg = skills_audit.aggregate(skills_audit.load_usage(USAGE))
        stale = skills_audit.compute_stale(agg, SAMPLE_CATALOG, months=6, now="2026-04-17T12:00:00Z")
        names = {s["skill"] for s in stale}
        self.assertIn("unused-skill", names)


OVERLAP_CATALOG = {
    "skills": [
        {"id": "a", "name": "find-session", "plugin": None, "source": "user",
         "description": "자연어로 이전 Claude Code 세션을 검색하고 요약",
         "category": "session", "mtime": "2026-04-01T00:00:00+00:00", "parse_error": False,
         "path": "..."},
        {"id": "b", "name": "agf", "plugin": None, "source": "user",
         "description": "Claude Code 세션 탐색 및 분석, 세션 검색",
         "category": "session", "mtime": "2026-04-01T00:00:00+00:00", "parse_error": False,
         "path": "..."},
        {"id": "c", "name": "unrelated", "plugin": None, "source": "user",
         "description": "Completely unrelated kitchen sink tool",
         "category": "misc", "mtime": "2026-04-01T00:00:00+00:00", "parse_error": False,
         "path": "..."},
    ]
}


class TestComputeOverlap(unittest.TestCase):
    def test_detects_similar_pair(self):
        overlap = skills_audit.compute_overlap(OVERLAP_CATALOG, threshold=0.4)
        pairs = [tuple(sorted(o["pair"])) for o in overlap]
        self.assertIn(("agf", "find-session"), pairs)

    def test_excludes_low_similarity(self):
        overlap = skills_audit.compute_overlap(OVERLAP_CATALOG, threshold=0.9)
        self.assertEqual(overlap, [])

    def test_returns_shared_keywords(self):
        overlap = skills_audit.compute_overlap(OVERLAP_CATALOG, threshold=0.3)
        self.assertGreater(len(overlap), 0)
        for entry in overlap:
            self.assertIn("similarity", entry)
            self.assertIn("shared_keywords", entry)


class TestFormatReport(unittest.TestCase):
    def test_text_report_has_sections(self):
        report = {
            "period_days": 30,
            "total_calls": 100,
            "top": [{"skill": "foo", "calls": 50, "last": "2026-04-17T00:00:00Z"}],
            "unused": [{"skill": "bar", "last": None, "mtime": "2026-01-01"}],
            "overlap": [{"pair": ["x", "y"], "similarity": 0.8, "shared_keywords": ["session"]}],
            "stale": [],
        }
        text = skills_audit.format_report(report, mode="text")
        self.assertIn("Top Skills", text)
        self.assertIn("Unused", text)
        self.assertIn("Overlap", text)

    def test_json_report_roundtrip(self):
        report = {"period_days": 30, "total_calls": 0, "top": [], "unused": [], "overlap": [], "stale": []}
        text = skills_audit.format_report(report, mode="json")
        import json as _json
        parsed = _json.loads(text)
        self.assertEqual(parsed["period_days"], 30)


if __name__ == "__main__":
    unittest.main()
