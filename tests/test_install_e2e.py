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

    def test_existing_harness_install_keeps_specs_and_runs_npm(self):
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "repo"
            (target / "e2e" / "tests").mkdir(parents=True)
            (target / "e2e" / "tests" / "custom.spec.ts").write_text("// custom\n", encoding="utf-8")
            (target / "e2e" / "package.json").write_text('{"name":"custom"}\n', encoding="utf-8")
            bin_dir = Path(tmp) / "bin"
            bin_dir.mkdir()
            npm = bin_dir / "npm"
            npm.write_text("#!/usr/bin/env bash\nprintf '%s\\n' \"$*\" > \"$NPM_LOG\"\n", encoding="utf-8")
            npm.chmod(0o755)
            log = Path(tmp) / "npm.log"
            result = subprocess.run(
                ["bash", str(SCRIPT), str(target), "--install"],
                capture_output=True,
                text=True,
                env={"PATH": f"{bin_dir}:/usr/bin:/bin", "NPM_LOG": str(log)},
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertTrue((target / "e2e" / "tests" / "custom.spec.ts").is_file())
            self.assertEqual(log.read_text().strip(), "install")


if __name__ == "__main__":
    unittest.main()
