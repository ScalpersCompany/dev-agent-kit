import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "check-techdoc.sh"


def make_repo(root: Path) -> Path:
    repo = root / "scalpers-tech-doc"
    repo.mkdir()
    subprocess.run(["git", "-C", str(repo), "init", "-q"], check=True)
    subprocess.run(["git", "-C", str(repo), "remote", "add", "origin", "git@github.com:ScalpersCompany/scalpers-tech-doc.git"], check=True)
    (repo / "AGENTS.md").write_text("# norm\n", encoding="utf-8")
    subprocess.run(["git", "-C", str(repo), "add", "AGENTS.md"], check=True)
    subprocess.run(
        ["git", "-C", str(repo), "-c", "user.name=Test", "-c", "user.email=test@example.com", "commit", "-q", "-m", "init"],
        check=True,
    )
    return repo


class CheckTechdocTest(unittest.TestCase):
    def run_check(self, *args: str) -> subprocess.CompletedProcess:
        return subprocess.run(["bash", str(SCRIPT), *args], capture_output=True, text=True)

    def test_clean_repo_passes(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = make_repo(Path(tmp))
            result = self.run_check("--path", str(repo))
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("remote:", result.stdout)

    def test_dirty_repo_fails_closed(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = make_repo(Path(tmp))
            (repo / "AGENTS.md").write_text("# changed\n", encoding="utf-8")
            result = self.run_check("--path", str(repo))
            self.assertEqual(result.returncode, 1)
            self.assertIn("dirty", result.stderr)

    def test_allow_dirty(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = make_repo(Path(tmp))
            (repo / "AGENTS.md").write_text("# changed\n", encoding="utf-8")
            result = self.run_check("--path", str(repo), "--allow-dirty")
            self.assertEqual(result.returncode, 0, result.stderr)

    def test_wrong_remote_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = make_repo(Path(tmp))
            subprocess.run(["git", "-C", str(repo), "remote", "set-url", "origin", "git@example.com:other/repo.git"], check=True)
            result = self.run_check("--path", str(repo))
            self.assertEqual(result.returncode, 1)
            self.assertIn("wrong remote", result.stderr)


if __name__ == "__main__":
    unittest.main()
