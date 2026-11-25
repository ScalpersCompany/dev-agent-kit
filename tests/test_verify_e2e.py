import json
import subprocess
import tempfile
import unittest
from pathlib import Path

KIT = Path(__file__).resolve().parents[1]
SCRIPT = KIT / "verify" / "run.sh"


class VerifyE2ETest(unittest.TestCase):
    def make_root(self, config):
        root = Path(tempfile.mkdtemp())
        (root / "verify").mkdir()
        (root / "verify" / "config.env").write_text(config, encoding="utf-8")
        return root

    def run_verify(self, root):
        return subprocess.run(
            ["bash", str(SCRIPT)],
            cwd=root,
            capture_output=True,
            text=True,
            env={
                "VERIFY_ROOT": str(root),
                "VERIFY_EVIDENCE": str(root / "evidence"),
                "PATH": "/usr/bin:/bin",
            },
        )

    def test_e2e_runs_after_tests_and_writes_evidence(self):
        root = self.make_root(
            'SMOKE_CMD="printf smoke"\n'
            'TEST_CMD="printf tests"\n'
            'E2E_BASE_URL="http://127.0.0.1:8000"\n'
            'E2E_CMD=\'test -n "$PLAYWRIGHT_OUTPUT_DIR" && printf e2e > '
            '"$PLAYWRIGHT_OUTPUT_DIR/trace.txt"\'\n'
        )
        result = self.run_verify(root)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        evidence = next((root / "evidence").iterdir())
        summary = json.loads((evidence / "summary.json").read_text(encoding="utf-8"))
        self.assertEqual(summary["e2e"], "pass")
        self.assertTrue((evidence / "e2e" / "test-results" / "trace.txt").is_file())
        self.assertEqual((evidence / "e2e.exit").read_text().strip(), "0")

    def test_e2e_alone_is_enough(self):
        root = self.make_root('E2E_CMD="printf e2e"\n')
        result = self.run_verify(root)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        evidence = next((root / "evidence").iterdir())
        summary = json.loads((evidence / "summary.json").read_text(encoding="utf-8"))
        self.assertEqual(summary["e2e"], "pass")
        self.assertEqual(summary["tests"], "skipped")

    def test_failing_e2e_fails_verify(self):
        root = self.make_root('E2E_CMD="exit 7"\n')
        result = self.run_verify(root)
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        evidence = next((root / "evidence").iterdir())
        summary = json.loads((evidence / "summary.json").read_text(encoding="utf-8"))
        self.assertEqual(summary["e2e"], "fail")
        self.assertEqual((evidence / "e2e.exit").read_text().strip(), "7")

    def test_e2e_is_skipped_when_absent(self):
        root = self.make_root('TEST_CMD="printf tests"\n')
        result = self.run_verify(root)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        evidence = next((root / "evidence").iterdir())
        summary = json.loads((evidence / "summary.json").read_text(encoding="utf-8"))
        self.assertEqual(summary["e2e"], "skipped")


if __name__ == "__main__":
    unittest.main()
