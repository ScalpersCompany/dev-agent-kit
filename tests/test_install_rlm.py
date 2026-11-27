import subprocess
import unittest
from pathlib import Path

KIT = Path(__file__).resolve().parents[1]
SCRIPT = KIT / "scripts" / "install-rlm.sh"


class RlmInstallerTest(unittest.TestCase):
    def test_dry_run_prints_the_optional_commands(self):
        result = subprocess.run(
            ["bash", str(SCRIPT), "--dry-run", "--agents", "hermes,opencode"],
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("npm install -g rlm-agent@", result.stdout)
        self.assertIn("--editor hermes", result.stdout)
        self.assertIn("--editor opencode", result.stdout)

    def test_rejects_an_unknown_agent(self):
        result = subprocess.run(
            ["bash", str(SCRIPT), "--dry-run", "--agents", "unknown"],
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("omitido: unknown", result.stdout)

    def test_check_changes_nothing(self):
        result = subprocess.run(
            ["bash", str(SCRIPT), "--check"],
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("rlm:", result.stdout)


if __name__ == "__main__":
    unittest.main()
