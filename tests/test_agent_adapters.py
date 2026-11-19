import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "install-agent-adapters.sh"


class AgentAdaptersTest(unittest.TestCase):
    def test_opencode_and_claude_adapters_are_generated(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = subprocess.run(
                ["bash", str(SCRIPT), tmp, "--agents", "opencode,claude"],
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            target = Path(tmp)
            self.assertTrue((target / ".opencode" / "skills" / "dev-verify" / "SKILL.md").is_file())
            self.assertTrue((target / ".opencode" / "agent" / "judge.md").is_file())
            self.assertTrue((target / ".claude" / "skills" / "dev-verify" / "SKILL.md").is_file())
            self.assertTrue((target / ".claude" / "commands" / "verify.md").is_file())

    def test_unknown_agent_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = subprocess.run(
                ["bash", str(SCRIPT), tmp, "--agents", "unknown"],
                capture_output=True,
                text=True,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("unknown agent", result.stderr)


if __name__ == "__main__":
    unittest.main()
