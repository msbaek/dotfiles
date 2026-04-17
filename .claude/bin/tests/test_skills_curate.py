import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

import importlib.util
spec = importlib.util.spec_from_file_location(
    "skills_curate",
    str(Path(__file__).parent.parent / "skills-curate.py")
)
skills_curate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(skills_curate)


class TestDecisionsLog(unittest.TestCase):
    def test_append_decision_creates_file(self):
        with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
            path = Path(f.name)
        path.unlink()
        try:
            skills_curate.append_decision(path, "2026-04-17", "keep", "foo", "manual note")
            text = path.read_text(encoding="utf-8")
            self.assertIn("## 2026-04-17", text)
            self.assertIn("[keep] foo — manual note", text)
        finally:
            if path.exists():
                path.unlink()

    def test_append_second_decision_same_date_reuses_header(self):
        with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
            path = Path(f.name)
        path.unlink()
        try:
            skills_curate.append_decision(path, "2026-04-17", "keep", "foo", "n1")
            skills_curate.append_decision(path, "2026-04-17", "archive", "bar", "n2")
            text = path.read_text(encoding="utf-8")
            self.assertEqual(text.count("## 2026-04-17"), 1)
            self.assertIn("[keep] foo", text)
            self.assertIn("[archive] bar", text)
        finally:
            if path.exists():
                path.unlink()

    def test_load_decisions_reads_history(self):
        with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
            f.write("# Log\n\n## 2026-04-01\n- [keep] foo — reason\n- [archive] bar — old\n")
            path = Path(f.name)
        try:
            decisions = skills_curate.load_decisions(path)
            self.assertEqual(decisions["foo"], "keep")
            self.assertEqual(decisions["bar"], "archive")
        finally:
            path.unlink()


class TestPrompters(unittest.TestCase):
    def test_prompt_unused_keep(self):
        item = {"skill": "foo", "last": None, "mtime": "2026-01-01"}
        decision, note = skills_curate.prompt_unused(item, responder=lambda _: "k")
        self.assertEqual(decision, "keep")

    def test_prompt_unused_archive(self):
        item = {"skill": "foo", "last": None, "mtime": "2026-01-01"}
        decision, note = skills_curate.prompt_unused(item, responder=lambda _: "a")
        self.assertEqual(decision, "archive")

    def test_prompt_unused_note_collected(self):
        item = {"skill": "foo", "last": None, "mtime": "2026-01-01"}
        responses = iter(["n", "연 2회 사용"])
        decision, note = skills_curate.prompt_unused(item, responder=lambda _: next(responses))
        self.assertEqual(decision, "note")
        self.assertEqual(note, "연 2회 사용")

    def test_prompt_overlap_distinct(self):
        item = {"pair": ["a", "b"], "similarity": 0.8, "shared_keywords": ["x"]}
        decision, note = skills_curate.prompt_overlap(item, responder=lambda _: "d")
        self.assertEqual(decision, "distinct")

    def test_prompt_skip_returns_none(self):
        item = {"skill": "foo", "last": None, "mtime": "2026-01-01"}
        decision, note = skills_curate.prompt_unused(item, responder=lambda _: "s")
        self.assertIsNone(decision)


class TestState(unittest.TestCase):
    def test_save_and_load_state(self):
        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
            path = Path(f.name)
        path.unlink()
        try:
            state = {"cursor": 5, "processed": ["a", "b"]}
            skills_curate.save_state(path, state)
            loaded = skills_curate.load_state(path)
            self.assertEqual(loaded, state)
        finally:
            if path.exists():
                path.unlink()

    def test_load_missing_returns_empty(self):
        loaded = skills_curate.load_state(Path("/nonexistent/state.json"))
        self.assertEqual(loaded, {"cursor": 0, "processed": []})

    def test_clear_state_removes_file(self):
        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
            path = Path(f.name)
        skills_curate.save_state(path, {"cursor": 1, "processed": []})
        skills_curate.clear_state(path)
        self.assertFalse(path.exists())


class TestBatchMode(unittest.TestCase):
    def test_batch_processes_items_and_writes_decisions(self):
        with tempfile.TemporaryDirectory() as tmp:
            batch_path = Path(tmp) / "batch.json"
            decisions_path = Path(tmp) / "decisions.md"
            state_path = Path(tmp) / "state.json"

            batch = {
                "items": [
                    {"kind": "unused", "data": {"skill": "old-tool", "last": None, "mtime": "2025-10-01"}},
                    {"kind": "overlap", "data": {"pair": ["a", "b"], "similarity": 0.8, "shared_keywords": ["x"]}},
                ],
                "responses": [
                    "a",       # archive for unused
                    "old 6mo", # note for archive
                    "d",       # distinct for overlap
                    "different roles",  # note
                ],
            }
            batch_path.write_text(json.dumps(batch), encoding="utf-8")

            # patch module-level paths
            orig_decisions = skills_curate.DECISIONS_PATH
            orig_state = skills_curate.STATE_PATH
            skills_curate.DECISIONS_PATH = decisions_path
            skills_curate.STATE_PATH = state_path
            try:
                responses = iter(batch["responses"])
                state = {"cursor": 0, "processed": []}
                skills_curate._interactive_loop(
                    batch["items"], state, responder=lambda _: next(responses)
                )
                text = decisions_path.read_text(encoding="utf-8")
                self.assertIn("[archive] old-tool", text)
                self.assertIn("[distinct] a ↔ b", text)
            finally:
                skills_curate.DECISIONS_PATH = orig_decisions
                skills_curate.STATE_PATH = orig_state


if __name__ == "__main__":
    unittest.main()
