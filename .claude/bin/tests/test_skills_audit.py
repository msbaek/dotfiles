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


if __name__ == "__main__":
    unittest.main()
