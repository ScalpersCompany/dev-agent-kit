import subprocess
import tempfile
import unittest
from pathlib import Path

KIT = Path(__file__).resolve().parents[1]
SCRIPT = KIT / "scripts" / "install-e2e.sh"


class InstallE2ETest(unittest.TestCase):
    def test_installs_playwright_harness_without_network(self):
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "repo"
            target.mkdir()
            result = subprocess.run(
                ["bash", str(SCRIPT), str(target)],
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertTrue((target / "e2e" / "playwright.config.ts").is_file())
            self.assertTrue((target / "e2e" / "tests" / "health.spec.ts").is_file())
            self.assertTrue((target / "e2e" / "package.json").is_file())
            self.assertNotIn("npm install", result.stdout)


if __name__ == "__main__":
    unittest.main()
