import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VALIDATE = ROOT / "scripts" / "validate-profile.py"
GENERATE = ROOT / "scripts" / "new-profile.sh"


def run(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run([sys.executable, str(VALIDATE), *args], capture_output=True, text=True)


class ValidateProfileTest(unittest.TestCase):
    def test_template_is_valid(self):
        result = run(str(ROOT / "profiles" / "_template"))
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_missing_guard_is_reported(self):
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "profiles" / "sample"
            subprocess.run(
                ["bash", str(GENERATE), "sample", "--language", "python", "--repo", tmp],
                capture_output=True,
                text=True,
                check=True,
            )
            contract = json.loads((target / "profile.json").read_text(encoding="utf-8"))
            contract["guard"] = ["guard/missing.sh"]
            (target / "profile.json").write_text(json.dumps(contract), encoding="utf-8")
            result = run(str(target))
            self.assertEqual(result.returncode, 1)
            self.assertIn("guard file not found", result.stderr)

    def test_generated_profile_is_valid(self):
        with tempfile.TemporaryDirectory() as tmp:
            subprocess.run(
                ["bash", str(GENERATE), "sample", "--language", "python", "--repo", tmp],
                capture_output=True,
                text=True,
                check=True,
            )
            result = run(str(Path(tmp) / "profiles" / "sample"))
            self.assertEqual(result.returncode, 0, result.stderr)

    def test_missing_profile_gga_rules_are_reported(self):
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "profiles" / "sample"
            subprocess.run(
                ["bash", str(GENERATE), "sample", "--language", "python", "--repo", tmp],
                capture_output=True,
                text=True,
                check=True,
            )
            (target / "gga" / "REVIEW-RULES.md").unlink()
            result = run(str(target))
            self.assertEqual(result.returncode, 1)
            self.assertIn("missing gga/REVIEW-RULES.md", result.stderr)


if __name__ == "__main__":
    unittest.main()
