import os
import subprocess
import tempfile
import unittest
from pathlib import Path

KIT = Path(__file__).resolve().parents[1]
SCRIPT = KIT / "scripts" / "review-gga.sh"


class ReviewGgaTest(unittest.TestCase):
    def make_repo(self, status):
        root = Path(tempfile.mkdtemp())
        repo = root / "repo"
        repo.mkdir()
        (repo / ".gga").write_text("PROVIDER=claude\n", encoding="utf-8")
        bin_dir = root / "bin"
        bin_dir.mkdir()
        gga = bin_dir / "gga"
        gga.write_text(
            "#!/usr/bin/env bash\n"
            "printf 'STATUS: %s\\n'\n"
            "if [ '%s' = 'FAILED' ]; then printf 'a.py:1 - RULE - issue\\n'; fi\n"
            % (status, status),
            encoding="utf-8",
        )
        gga.chmod(0o755)
        return repo, bin_dir

    def run_script(self, repo, bin_dir, *args):
        env = dict(os.environ)
        env["PATH"] = str(bin_dir) + ":/usr/bin:/bin"
        return subprocess.run(
            ["bash", str(SCRIPT), str(repo), *args],
            capture_output=True,
            text=True,
            env=env,
        )

    def test_failed_is_blocking(self):
        repo, bin_dir = self.make_repo("FAILED")
        result = self.run_script(repo, bin_dir, "--blocking")
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("blocking review failed", result.stderr)

    def test_passed_is_green(self):
        repo, bin_dir = self.make_repo("PASSED")
        result = self.run_script(repo, bin_dir, "--blocking")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("blocking review passed", result.stdout)

    def test_advisory_does_not_block(self):
        repo, bin_dir = self.make_repo("FAILED")
        result = self.run_script(repo, bin_dir, "--advisory")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_missing_config_fails_closed(self):
        repo, bin_dir = self.make_repo("PASSED")
        (repo / ".gga").unlink()
        result = self.run_script(repo, bin_dir, "--blocking")
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
