import os
import unittest
from pathlib import Path
from unittest.mock import patch

from evals.agent_runner import agent_command, parse_output, resolve_agent, run_agent


class AgentRunnerTest(unittest.TestCase):
    def test_aliases_are_backwards_compatible(self):
        self.assertEqual(resolve_agent("build"), ("opencode", "build"))
        self.assertEqual(resolve_agent("plan"), ("opencode", "plan"))
        self.assertEqual(resolve_agent("judge"), ("opencode", None))

    def test_unknown_agent_is_rejected(self):
        with self.assertRaises(ValueError):
            resolve_agent("unknown-agent")

    def test_claude_command_is_print_mode_and_bounded(self):
        cmd = agent_command("claude", "prompt", "model", None, 60)
        self.assertEqual(cmd[0], "claude")
        self.assertIn("-p", cmd)
        self.assertIn("--output-format", cmd)
        self.assertIn("--max-turns", cmd)
        self.assertIn("model", cmd)
        self.assertNotIn("--dangerously-skip-permissions", cmd)

    def test_codex_command_is_non_interactive_and_sandboxed(self):
        cmd = agent_command("codex", "prompt", "model", None, 60)
        self.assertEqual(cmd[:2], ["codex", "exec"])
        self.assertIn("--sandbox", cmd)
        self.assertIn("workspace-write", cmd)
        self.assertIn("--skip-git-repo-check", cmd)

    def test_pi_and_hermes_commands_are_one_shot(self):
        pi = agent_command("pi", "prompt", "model", None, 60)
        self.assertIn("-p", pi)
        self.assertIn("--no-session", pi)
        self.assertIn("--mode", pi)
        hermes = agent_command("hermes", "prompt", "model", None, 60)
        self.assertEqual(hermes[0], "hermes")
        self.assertIn("-z", hermes)
        self.assertIn("--usage-file", hermes)

    def test_claude_json_is_normalized(self):
        result = parse_output(
            "claude",
            '{"result":"OK","usage":{"input_tokens":2,"output_tokens":3},"total_cost_usd":0.1}',
            "",
            0,
            1.2,
            False,
        )
        self.assertEqual(result.text, "OK")
        self.assertEqual(result.meta["tokens"], 5)
        self.assertAlmostEqual(result.meta["cost"], 0.1)

    def test_opencode_jsonl_is_normalized(self):
        stdout = (
            '{"type":"text","part":{"text":"OK"}}\n'
            '{"type":"step_finish","part":{"tokens":{"input":2,"output":3},"cost":0.2}}\n'
        )
        result = parse_output("opencode", stdout, "", 0, 1.2, False)
        self.assertEqual(result.text, "OK")
        self.assertEqual(result.meta["tokens"], 5)
        self.assertAlmostEqual(result.meta["cost"], 0.2)

    def test_missing_agent_is_not_a_pass(self):
        with patch.dict(os.environ, {"PATH": ""}):
            result = run_agent("claude", "prompt", Path.cwd(), None)
        self.assertEqual(result.meta["exit"], 127)
        self.assertEqual(result.meta["error"], "agent_not_installed")
        self.assertFalse(result.text)


if __name__ == "__main__":
    unittest.main()
