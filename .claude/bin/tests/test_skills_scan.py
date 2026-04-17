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


if __name__ == "__main__":
    unittest.main()
