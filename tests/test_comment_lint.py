import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

KIT = Path(__file__).resolve().parents[1]
LINT = KIT / "guard" / "comment_lint.py"


class CommentLintTest(unittest.TestCase):
    def run_lint(self, files):
        with tempfile.TemporaryDirectory() as name:
            root = Path(name)
            subprocess.run(["git", "init", "-q", str(root)], check=True)
            subprocess.run(["git", "-C", str(root), "config", "user.email", "test@example.com"], check=True)
            subprocess.run(["git", "-C", str(root), "config", "user.name", "test"], check=True)
            for relative, content in files.items():
                path = root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(content, encoding="utf-8")
            subprocess.run(["git", "-C", str(root), "add", "."], check=True)
            return subprocess.run(
                [sys.executable, str(LINT), "--root", str(root), "--staged"],
                capture_output=True,
                text=True,
            )

    def test_python_comment_blocks(self):
        result = self.run_lint({"mod.py": "value = 1\n# explanation\n"})
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("COMMENT", result.stdout)

    def test_python_directive_is_allowed(self):
        result = self.run_lint({"mod.py": "value = 1  # noqa\nother = 2  # type: ignore\n"})
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_python_docstring_is_not_a_comment(self):
        result = self.run_lint({"mod.py": '"""Documented function."""\nvalue = 1\n'})
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_xml_comment_blocks(self):
        result = self.run_lint({"view.xml": "<root>\n<!-- explanation -->\n</root>\n"})
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)

    def test_javascript_comment_blocks(self):
        result = self.run_lint({"app.js": "const value = 1; // explanation\n"})
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)

    def test_clean_file_passes(self):
        result = self.run_lint({"app.js": "const value = 1;\n"})
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
