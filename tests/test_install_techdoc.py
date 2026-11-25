import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "install-techdoc.sh"


class InstallTechdocTest(unittest.TestCase):
    def make_repo(self, path: Path, remote: str) -> Path:
        path.mkdir()
        subprocess.run(["git", "-C", str(path), "init", "-q"], check=True)
        subprocess.run(["git", "-C", str(path), "remote", "add", "origin", remote], check=True)
        (path / "AGENTS.md").write_text("# norm\n", encoding="utf-8")
        subprocess.run(["git", "-C", str(path), "add", "AGENTS.md"], check=True)
        subprocess.run(
            ["git", "-C", str(path), "-c", "user.name=Test", "-c", "user.email=test@example.com", "commit", "-q", "-m", "init"],
            check=True,
        )
        return path

    def test_links_agents_and_html(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            techdoc = self.make_repo(root / "techdoc", "git@github.com:ScalpersCompany/scalpers-tech-doc.git")
            html = techdoc / "books" / "scalpers-methodology" / "build" / "single-html" / "doc.html"
            html.parent.mkdir(parents=True)
            html.write_text("<html>doc</html>\n", encoding="utf-8")
            target = root / "target"
            target.mkdir()
            subprocess.run(["git", "-C", str(target), "init", "-q"], check=True)
            agents = root / "agents"
            env = os.environ.copy()
            env["AGENTS_HOME"] = str(agents)
            result = subprocess.run(
                ["bash", str(SCRIPT), str(target), "--techdoc-path", str(techdoc)],
                capture_output=True,
                text=True,
                env=env,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue((target / "docs" / "TECHDOC.md").is_file())
            self.assertTrue((target / "docs" / "techdoc.html").is_symlink())
            self.assertEqual((target / "docs" / "techdoc.html").resolve(), html.resolve())
            self.assertEqual((agents / "AGENTS.md").resolve(), (techdoc / "AGENTS.md").resolve())

    def test_missing_agents_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            techdoc = self.make_repo(root / "techdoc", "git@github.com:ScalpersCompany/scalpers-tech-doc.git")
            (techdoc / "AGENTS.md").unlink()
            target = root / "target"
            target.mkdir()
            subprocess.run(["git", "-C", str(target), "init", "-q"], check=True)
            result = subprocess.run(
                ["bash", str(SCRIPT), str(target), "--techdoc-path", str(techdoc)],
                capture_output=True,
                text=True,
                env={**os.environ, "AGENTS_HOME": str(root / "agents")},
            )
            self.assertEqual(result.returncode, 1)
            self.assertIn("falta", result.stderr)


if __name__ == "__main__":
    unittest.main()
