import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RENDER = ROOT / "scripts" / "render-roles.py"

CONTRACT = {
    "api": 1,
    "profile": "team",
    "handoff": "task-file-reference",
    "placeholders": ["{task_file}", "{module}", "{tree}", "{run_id}", "{score_file}"],
    "roles": [
        {
            "role": "plan",
            "stage": "specification",
            "writes": ["odd/tasks/{task_file}.md"],
            "reads": ["docs/FEATURE_MAP.md"],
            "readonly": False,
            "runs_on_copy": False,
            "owns_worktree": False,
            "entry": "dev-agent guard --staged",
            "exit": [{"command": "python3 .dev-agent/profiles/team/guard/team_lint.py --task odd/tasks/{task_file}.md", "expect": "exit 0"}],
            "forbidden": ["git push"],
        },
        {
            "role": "review",
            "stage": "review",
            "writes": [],
            "reads": ["odd/tasks/{task_file}.md"],
            "readonly": True,
            "runs_on_copy": True,
            "owns_worktree": False,
            "entry": "dev-agent review-gga {tree}",
            "exit": [{"command": "dev-agent review-gga {tree}", "expect": "STATUS: PASSED"}],
            "forbidden": ["git push"],
        },
    ],
}


def run(*args):
    return subprocess.run([sys.executable, str(RENDER), *args], capture_output=True, text=True)


def frontmatter(text):
    lines = text.splitlines()
    assert lines[0] == "---"
    end = lines.index("---", 1)
    return lines[1:end]


class RenderRolesTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.contract = self.root / "roles.json"
        self.contract.write_text(json.dumps(CONTRACT), encoding="utf-8")
        self.out = self.root / "out"

    def render(self, target, *extra):
        return run("--roles", str(self.contract), "--target", target, "--out", str(self.out), *extra)

    def test_claude_role_gets_name_and_readonly_tools(self):
        result = self.render("claude")
        self.assertEqual(result.returncode, 0, result.stderr)
        review = (self.out / "review.md").read_text(encoding="utf-8")
        head = frontmatter(review)
        self.assertIn("name: review", head)
        self.assertIn("disallowedTools: Write, Edit, NotebookEdit", head)
        self.assertIn("model: opus", head)
        self.assertIn("STATUS: PASSED", review)
        plan = (self.out / "plan.md").read_text(encoding="utf-8")
        self.assertIn("tools: Read, Grep, Glob, Edit, Write, Bash", frontmatter(plan))
        self.assertIn("model: sonnet", frontmatter(plan))

    def test_opencode_role_is_a_subagent_without_edit(self):
        result = self.render("opencode")
        self.assertEqual(result.returncode, 0, result.stderr)
        head = "\n".join(frontmatter((self.out / "review.md").read_text(encoding="utf-8")))
        self.assertIn("mode: subagent", head)
        self.assertIn("effect: deny", head)
        dev = "\n".join(frontmatter((self.out / "plan.md").read_text(encoding="utf-8")))
        self.assertNotIn("permissions:", dev)

    def test_model_map_overrides_the_default(self):
        mapping = self.root / "models.json"
        mapping.write_text(json.dumps({"plan": "haiku"}), encoding="utf-8")
        result = self.render("claude", "--model-map", str(mapping))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("model: haiku", frontmatter((self.out / "plan.md").read_text(encoding="utf-8")))
        self.assertNotIn("model:", "\n".join(frontmatter((self.out / "review.md").read_text(encoding="utf-8"))))

    def test_check_reports_stale_files_without_writing(self):
        self.assertEqual(self.render("claude").returncode, 0)
        self.assertEqual(self.render("claude", "--check").returncode, 0)
        contract = dict(CONTRACT)
        contract["roles"] = [dict(CONTRACT["roles"][1], stage="review-changed")]
        self.contract.write_text(json.dumps(contract), encoding="utf-8")
        before = (self.out / "review.md").read_text(encoding="utf-8")
        result = self.render("claude", "--check")
        self.assertEqual(result.returncode, 1)
        self.assertIn("stale", result.stderr)
        self.assertEqual(before, (self.out / "review.md").read_text(encoding="utf-8"))

    def test_contract_without_roles_is_rejected(self):
        self.contract.write_text(json.dumps({"api": 1, "roles": []}), encoding="utf-8")
        result = self.render("claude")
        self.assertEqual(result.returncode, 2)
        self.assertIn("no roles", result.stderr)


if __name__ == "__main__":
    unittest.main()
