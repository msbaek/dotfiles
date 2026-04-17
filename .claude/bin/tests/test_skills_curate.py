import sys
import unittest
import tempfile
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


if __name__ == "__main__":
    unittest.main()
