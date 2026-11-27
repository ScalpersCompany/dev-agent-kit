import os
import subprocess
import tempfile
import unittest
from pathlib import Path

KIT = Path(__file__).resolve().parents[1]


class FlowCommandTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="dev-agent-flow-"))
        self.flow = self.tmp / "flows" / "demo"
        self.flow.mkdir(parents=True)
        (self.flow / "flow.json").write_text(
            '{"name":"demo","version":"1.0.0","api":1,"kind":"flow",'
            '"description":"demo flow","entrypoint":"bin/run.sh"}\n',
            encoding="utf-8",
        )
        (self.flow / "bin").mkdir()
        runner = self.flow / "bin" / "run.sh"
        runner.write_text('#!/usr/bin/env bash\nprintf "%s\\n" "$@"\n', encoding="utf-8")
        runner.chmod(0o755)
        self.env = {**os.environ, "DEV_AGENT_PROFILES": str(self.tmp)}
        subprocess.run(["git", "-C", str(self.tmp), "init", "-q"], check=True)

    def tearDown(self):
        import shutil

        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_list_reads_flow_json(self):
        result = subprocess.run(
            ["bash", str(KIT / "bin" / "dev-agent"), "flow", "list"],
            capture_output=True,
            text=True,
            env=self.env,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("demo", result.stdout)
        self.assertIn("demo flow", result.stdout)

    def test_run_prepends_the_current_repository(self):
        result = subprocess.run(
            ["bash", str(KIT / "bin" / "dev-agent"), "flow", "run", "demo", "--dry-run"],
            capture_output=True,
            text=True,
            env=self.env,
            cwd=str(self.tmp),
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines()[0], str(self.tmp))
        self.assertEqual(result.stdout.splitlines()[1], "--dry-run")

    def test_unknown_flow_fails_closed(self):
        result = subprocess.run(
            ["bash", str(KIT / "bin" / "dev-agent"), "flow", "run", "missing"],
            capture_output=True,
            text=True,
            env=self.env,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("flujo no encontrado", result.stderr)


if __name__ == "__main__":
    unittest.main()
