import subprocess
import tempfile
import unittest
from pathlib import Path

KIT = Path(__file__).resolve().parents[1]
SCRIPT = KIT / "scripts" / "install-gga.sh"
CORE_MARKER = "# GGA review rules — DevAgentKit core"


class InstallGgaTest(unittest.TestCase):
    def make_repo(self):
        root = Path(tempfile.mkdtemp())
        repo = root / "repo"
        repo.mkdir()
        return root, repo

    def make_profile(self, root, with_gga=True, with_fragment=True):
        profile = root / "profiles" / "demo"
        profile.mkdir(parents=True)
        if with_gga:
            (profile / "gga").mkdir()
            (profile / "gga" / "REVIEW-RULES.md").write_text(
                "# Profile GGA rules\n\nPROFILE-GGA-MARKER\n", encoding="utf-8"
            )
        if with_fragment:
            (profile / "AGENTS.fragment.md").write_text(
                "PROFILE-FRAGMENT-MARKER\n", encoding="utf-8"
            )
        return profile

    def run_install(self, repo, *args):
        return subprocess.run(
            ["bash", str(SCRIPT), str(repo), *args, "--provider", "none"],
            capture_output=True,
            text=True,
        )

    def test_core_and_profile_rules_are_composed(self):
        root, repo = self.make_repo()
        profile = self.make_profile(root)
        result = self.run_install(repo, "--profile", str(profile))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        rules = (repo / ".gga-rules.md").read_text(encoding="utf-8")
        self.assertIn(CORE_MARKER, rules)
        self.assertIn("PROFILE-GGA-MARKER", rules)
        self.assertNotIn("PROFILE-FRAGMENT-MARKER", rules)

    def test_core_only_without_profile(self):
        root, repo = self.make_repo()
        result = self.run_install(repo)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        rules = (repo / ".gga-rules.md").read_text(encoding="utf-8")
        self.assertIn(CORE_MARKER, rules)
        self.assertNotIn("PROFILE-GGA-MARKER", rules)

    def test_fragment_is_a_reported_fallback(self):
        root, repo = self.make_repo()
        profile = self.make_profile(root, with_gga=False)
        result = self.run_install(repo, "--profile", str(profile))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        rules = (repo / ".gga-rules.md").read_text(encoding="utf-8")
        self.assertIn("PROFILE-FRAGMENT-MARKER", rules)
        self.assertIn("using AGENTS.fragment.md", result.stderr)


if __name__ == "__main__":
    unittest.main()
