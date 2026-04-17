import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

import importlib.util
spec = importlib.util.spec_from_file_location(
    "skills_scan",
    str(Path(__file__).parent.parent / "skills-scan.py")
)
skills_scan = importlib.util.module_from_spec(spec)
spec.loader.exec_module(skills_scan)

FIXTURES = Path(__file__).parent / "fixtures"


class TestParseFrontmatter(unittest.TestCase):
    def test_valid_frontmatter(self):
        result = skills_scan.parse_frontmatter(FIXTURES / "valid" / "SKILL.md")
        self.assertEqual(result["name"], "sample-valid")
        self.assertIn("frontmatter parsing", result["description"])
        self.assertFalse(result["parse_error"])

    def test_malformed_returns_error(self):
        result = skills_scan.parse_frontmatter(FIXTURES / "malformed" / "SKILL.md")
        self.assertTrue(result["parse_error"])

    def test_no_frontmatter_returns_error(self):
        result = skills_scan.parse_frontmatter(FIXTURES / "no_frontmatter" / "SKILL.md")
        self.assertTrue(result["parse_error"])


class TestFindSkillFiles(unittest.TestCase):
    def test_finds_fixture_skills(self):
        paths = skills_scan.find_skill_files([FIXTURES])
        names = {p.parent.name for p in paths}
        self.assertIn("valid", names)
        self.assertIn("malformed", names)
        self.assertIn("no_frontmatter", names)

    def test_empty_root_returns_empty(self):
        import tempfile
        with tempfile.TemporaryDirectory() as tmp:
            paths = skills_scan.find_skill_files([Path(tmp)])
            self.assertEqual(paths, [])

    def test_nonexistent_root_skipped(self):
        paths = skills_scan.find_skill_files([Path("/nonexistent/xyz123")])
        self.assertEqual(paths, [])


class TestInferCategory(unittest.TestCase):
    def test_prefix_obsidian(self):
        self.assertEqual(
            skills_scan.infer_category("obsidian:summarize-article", "..."),
            "obsidian"
        )

    def test_prefix_databricks(self):
        self.assertEqual(
            skills_scan.infer_category("databricks-jobs", "..."),
            "databricks"
        )

    def test_prefix_tdd(self):
        self.assertEqual(
            skills_scan.infer_category("msbaek-tdd:tdd-rgb", "..."),
            "tdd"
        )

    def test_keyword_in_description(self):
        self.assertEqual(
            skills_scan.infer_category("random-name", "Helps with git workflow and commits"),
            "git"
        )

    def test_unknown_returns_uncategorized(self):
        self.assertEqual(
            skills_scan.infer_category("xyz", "something weird"),
            "uncategorized"
        )


if __name__ == "__main__":
    unittest.main()
