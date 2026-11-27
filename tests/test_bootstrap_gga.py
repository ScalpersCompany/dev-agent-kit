import subprocess
import tempfile
import unittest
from pathlib import Path

KIT = Path(__file__).resolve().parents[1]
SCRIPT = KIT / "scripts" / "bootstrap.sh"


class BootstrapGgaTest(unittest.TestCase):
    def test_bootstrap_copies_core_gga_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "repo"
            target.mkdir()
            subprocess.run(["git", "-C", str(target), "init", "-q"], check=True)
            result = subprocess.run(
                ["bash", str(SCRIPT), str(target)],
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertTrue((target / "gga" / "project.gga.example").is_file())
            self.assertTrue((target / "gga" / "REVIEW-RULES.md").is_file())


if __name__ == "__main__":
    unittest.main()
