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
            self.assertTrue((target / ".opencode" / "agents" / "judge.md").is_file())
            self.assertFalse((target / ".opencode" / "agent").exists())
            self.assertTrue((target / ".claude" / "skills" / "dev-verify" / "SKILL.md").is_file())
            self.assertTrue((target / ".claude" / "commands" / "verify.md").is_file())

    def test_legacy_singular_agent_dir_is_backed_up(self):
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp)
            legacy = target / ".opencode" / "agent"
            legacy.mkdir(parents=True)
            (legacy / "judge.md").write_text("old judge\n", encoding="utf-8")
            result = subprocess.run(
                ["bash", str(SCRIPT), tmp, "--agents", "opencode"],
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("migrated:", result.stdout)
            installed = (target / ".opencode" / "agents" / "judge.md").read_text(encoding="utf-8")
            self.assertIn("strict evaluator", installed)
            self.assertFalse((legacy / "judge.md").exists())
            backups = sorted(legacy.glob("judge.md.bak-*"))
            self.assertEqual(len(backups), 1)
            self.assertEqual(backups[0].read_text(encoding="utf-8"), "old judge\n")

    def test_judge_carries_the_opencode_v2_permissions(self):
        text = (ROOT / "agents" / "judge.md").read_text(encoding="utf-8")
        self.assertIn("permissions:", text)
        self.assertIn("action: edit", text)
        self.assertIn("action: shell", text)
        self.assertEqual(text.count("effect: deny"), 2)

    def test_profile_skills_are_merged_into_adapters(self):
        with tempfile.TemporaryDirectory() as tmp:
            profile = Path(tmp) / "profile"
            (profile / "skills" / "odoo-demo").mkdir(parents=True)
            (profile / "skills" / "odoo-demo" / "SKILL.md").write_text("# demo\n", encoding="utf-8")
            target = Path(tmp) / "target"
            target.mkdir()
            result = subprocess.run(
                ["bash", str(SCRIPT), str(target), "--agents", "opencode,claude", "--profile", str(profile)],
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue((target / ".opencode" / "skills" / "odoo-demo" / "SKILL.md").is_file())
            self.assertTrue((target / ".claude" / "skills" / "odoo-demo" / "SKILL.md").is_file())
            self.assertTrue((target / ".opencode" / "skills" / "dev-verify" / "SKILL.md").is_file())

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
