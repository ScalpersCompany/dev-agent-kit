import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

KIT = Path(__file__).resolve().parents[1]
UPDATE = KIT / "scripts" / "update.sh"


def run(cmd, cwd=None, env=None, check=True):
    result = subprocess.run(
        cmd,
        cwd=str(cwd) if cwd else None,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    if check and result.returncode != 0:
        raise AssertionError("%s\n%s" % (" ".join(cmd), result.stdout))
    return result


def git(repo, *args):
    return run(["git", "-C", str(repo), *args])


class UpdateTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="dev-agent-update-"))

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def make_remote(self, name):
        remote = self.tmp / (name + ".git")
        run(["git", "-c", "init.defaultBranch=main", "init", "--bare", "-q", str(remote)])
        source = self.tmp / (name + "-source")
        run(["git", "clone", "-q", str(remote), str(source)])
        git(source, "config", "user.name", "Test")
        git(source, "config", "user.email", "test@example.com")
        return remote, source

    def commit_and_push(self, repo, path, content, message):
        target = repo / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")
        git(repo, "add", path)
        git(repo, "commit", "-q", "-m", message)
        git(repo, "push", "-q", "-u", "origin", "main")

    def env(self):
        return {
            **os.environ,
            "DEV_AGENT_PROFILES": str(self.tmp / "profiles-source"),
        }

    def test_core_fast_forwards_and_leaves_backup_tag(self):
        remote, source = self.make_remote("core")
        self.commit_and_push(source, "VERSION", "one\n", "first")
        installed = self.tmp / "installed"
        run(["git", "clone", "-q", str(remote), str(installed)])
        self.commit_and_push(source, "VERSION", "two\n", "second")
        result = run(
            ["bash", str(UPDATE), "--core", "--yes"],
            env={**self.env(), "DEV_AGENT_KIT": str(installed)},
        )
        self.assertIn("actualizado a", result.stdout)
        self.assertEqual((installed / "VERSION").read_text(encoding="utf-8"), "two\n")
        tags = git(installed, "tag", "--list", "dev-agent-update-backup-*")
        self.assertTrue(tags.stdout.strip())

    def test_dirty_core_is_refused_without_changing_files(self):
        remote, source = self.make_remote("dirty")
        self.commit_and_push(source, "VERSION", "one\n", "first")
        installed = self.tmp / "installed"
        run(["git", "clone", "-q", str(remote), str(installed)])
        self.commit_and_push(source, "VERSION", "two\n", "second")
        (installed / "VERSION").write_text("local\n", encoding="utf-8")
        result = run(
            ["bash", str(UPDATE), "--core", "--yes"],
            env={**self.env(), "DEV_AGENT_KIT": str(installed)},
            check=False,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("cambios locales", result.stdout)
        self.assertEqual((installed / "VERSION").read_text(encoding="utf-8"), "local\n")

    def test_profiles_can_sync_one_target_with_backup(self):
        remote, source = self.make_remote("profiles")
        profile = source / "profiles" / "p1"
        profile.mkdir(parents=True)
        (profile / "profile.json").write_text('{"name":"p1"}\n', encoding="utf-8")
        (profile / "profile.env").write_text("PROFILE_NAME=p1\n", encoding="utf-8")
        git(source, "add", "profiles")
        git(source, "commit", "-q", "-m", "profile")
        git(source, "push", "-q", "-u", "origin", "main")
        target = self.tmp / "target"
        installed_profile = target / ".dev-agent" / "profiles" / "p1"
        installed_profile.mkdir(parents=True)
        (installed_profile / "profile.json").write_text('{"name":"p1","version":"old"}\n', encoding="utf-8")
        (target / ".dev-agent" / "config").write_text("DEV_AGENT_PROFILE=p1\n", encoding="utf-8")
        result = run(
            ["bash", str(UPDATE), "--profiles", "--target", str(target), "--yes"],
            env={**self.env(), "DEV_AGENT_PROFILES": str(source)},
        )
        self.assertIn("p1 actualizado", result.stdout)
        self.assertTrue((target / ".dev-agent" / "profiles" / "p1.bak-" ).exists() or any(
            p.name.startswith("p1.bak-") for p in (target / ".dev-agent" / "profiles").iterdir()
        ))
        self.assertEqual(
            (installed_profile / "profile.json").read_text(encoding="utf-8"),
            '{"name":"p1"}\n',
        )


if __name__ == "__main__":
    unittest.main()
