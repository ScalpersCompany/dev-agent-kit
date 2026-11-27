import os
import subprocess
import tempfile
import unittest
from pathlib import Path

KIT = Path(__file__).resolve().parents[1]
PROFILES = Path("/home/scalpers/dev-agent-profiles")


class InstallMainTest(unittest.TestCase):
    def test_installer_installs_gga_and_writes_both_verify_configs(self):
        if not (PROFILES / "profiles" / "odoo11" / "profile.json").is_file():
            self.skipTest("odoo11 profile checkout is not available")
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            repo = root / "repo"
            home = root / "home"
            repo.mkdir()
            home.mkdir()
            subprocess.run(["git", "-C", str(repo), "init", "-q"], check=True)
            subprocess.run(["git", "-C", str(repo), "config", "user.email", "test@example.com"], check=True)
            subprocess.run(["git", "-C", str(repo), "config", "user.name", "test"], check=True)
            env = dict(os.environ)
            env["HOME"] = str(home)
            env["DEV_AGENT_PROFILES"] = str(PROFILES)
            result = subprocess.run(
                [
                    "bash",
                    str(KIT / "install.sh"),
                    "--target",
                    str(repo),
                    "--profiles",
                    "odoo11",
                    "--active",
                    "odoo11",
                    "--agents",
                    "none",
                    "--no-codegraph",
                    "--no-engram",
                    "--no-techdoc",
                    "--yes",
                    "--no-toolchain",
                    "--no-dev-deps",
                    "--with-gga",
                    "--no-gga-pre-push",
                    "--no-e2e-deps",
                    "--with-e2e-config",
                    "--e2e-cmd",
                    "npm --prefix e2e test",
                    "--e2e-base-url",
                    "http://127.0.0.1:8000",
                    "--e2e-health-path",
                    "/",
                ],
                capture_output=True,
                text=True,
                env=env,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertTrue((repo / ".gga").is_file())
            self.assertTrue((repo / ".gga-rules.md").is_file())
            self.assertIn(".gga", (repo / ".git" / "info" / "exclude").read_text())
            self.assertRegex((repo / ".gga").read_text(), r"(?m)^PROVIDER=\s*$")
            for config in (repo / "verify" / "config.env", repo / ".dev-agent" / "verify.env"):
                text = config.read_text()
                self.assertIn('E2E_CMD="npm --prefix e2e test"', text)
                self.assertIn('E2E_BASE_URL="http://127.0.0.1:8000"', text)


if __name__ == "__main__":
    unittest.main()
