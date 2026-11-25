#!/usr/bin/env python3
"""Eval harness for OpenCode skills.

Each run happens in a disposable sandbox (a git worktree when possible, a copy
otherwise) so the agent cannot touch the real working tree. The judge receives
the final answer plus the artifacts the run produced, and returns one score per
rubric criterion. The harness computes the weighted average itself.

Usage:
  python3 evals/harness.py --case-dir evals/cases/<skill>/<case> --rubric evals/rubric.json
  python3 evals/harness.py ... --dry-run
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import statistics
import subprocess
import sys
import tempfile
import time
from collections.abc import Callable
from datetime import datetime, timezone
from pathlib import Path

try:
    from evals.agent_runner import AGENTS, resolve_agent, run_agent
except ImportError:
    from agent_runner import AGENTS, resolve_agent, run_agent

HEAVY = {
    ".git",
    "node_modules",
    ".venv",
    "venv",
    "__pycache__",
    "dist",
    "build",
    "evidence",
    ".mypy_cache",
    ".pytest_cache",
}
SUPPORT_PREFIXES = ("skills/", "commands/", "agents/", ".opencode/", ".claude/", ".codex/", "AGENTS.md", "verify/", "guard/", "scripts/", "docs/")
ARTIFACT_SUFFIXES = {".json", ".md", ".txt", ".log", ".xml", ".csv", ".yaml", ".yml", ".html", ".py", ".rst", ".po", ".js", ".diff", ".patch"}
MAX_ARTIFACT_FILES = 20
MAX_ARTIFACT_FILE_CHARS = 20000
MAX_ARTIFACT_CHARS = 45000
MAX_DIFF_CHARS = 6000


def neutral_name(index: int) -> str:
    # Directory names must not reveal that this is an evaluation.
    return chr(ord("a") + index)


def repo_root() -> Path:
    # The harness is run from the repository root. Never climb to a parent
    # repository: a home directory that happens to be a git repo would make the
    # sandbox copy the whole home.
    return Path.cwd().resolve()


def has_head(repo: Path) -> bool:
    if not (repo / ".git").exists():
        return False
    result = subprocess.run(
        ["git", "-C", str(repo), "rev-parse", "--verify", "HEAD"],
        capture_output=True,
        text=True,
    )
    return result.returncode == 0


def copy_support(repo: Path, sandbox: Path) -> None:
    """Copy the kit's working-tree support files into the sandbox.

    The skills under test are often uncommitted, so the working-tree version
    wins over the committed one. These paths are filtered out of the artifact
    report later, so they do not look like agent changes.
    """
    for rel in ("skills", "commands", "agents", ".opencode", ".claude", ".codex", "AGENTS.md", "verify", "guard", "scripts", "docs"):
        source = repo / rel
        if not source.exists():
            continue
        target = sandbox / rel
        if source.is_dir():
            shutil.copytree(
                source,
                target,
                dirs_exist_ok=True,
                ignore=shutil.ignore_patterns("runs", "evidence", "__pycache__"),
            )
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)


def make_sandbox(repo: Path, case_dir: Path, index: int, keep: bool) -> tuple[Path, Callable[[], None], str]:
    parent = Path(tempfile.mkdtemp(prefix="eval-"))
    sandbox = parent / neutral_name(index)
    mode = "copy"

    if has_head(repo):
        result = subprocess.run(
            ["git", "-C", str(repo), "worktree", "add", "--detach", str(sandbox), "HEAD"],
            capture_output=True,
            text=True,
        )
        if result.returncode == 0:
            mode = "worktree"
        else:
            shutil.rmtree(sandbox, ignore_errors=True)

    if not sandbox.exists():
        sandbox.mkdir(parents=True)
        shutil.copytree(
            repo,
            sandbox,
            dirs_exist_ok=True,
            ignore=shutil.ignore_patterns(*HEAVY, "runs"),
        )

    copy_support(repo, sandbox)

    for item in case_dir.iterdir():
        if item.name == "TASK.md":
            continue
        target = sandbox / item.name
        if item.is_dir():
            shutil.copytree(item, target, dirs_exist_ok=True)
        else:
            shutil.copy2(item, target)

    def cleanup() -> None:
        if mode == "worktree":
            subprocess.run(
                ["git", "-C", str(repo), "worktree", "remove", "--force", str(sandbox)],
                capture_output=True,
                text=True,
            )
        shutil.rmtree(parent, ignore_errors=True)

    if keep:
        print(f"sandbox kept: {sandbox}")

    return sandbox, cleanup, mode


def collect_text(events: list[dict]) -> str:
    texts = []
    for event in events:
        part = event.get("part") or {}
        if event.get("type") == "text" and part.get("text"):
            texts.append(part["text"])
    return texts[-1].strip() if texts else ""


def run_opencode(
    prompt: str,
    cwd: Path,
    agent: str | None,
    model: str,
    timeout: int,
) -> tuple[list[dict], str, dict]:
    result = run_agent("opencode", prompt, cwd, model, agent, timeout)
    return result.events, result.text, result.meta


def collect_artifacts(sandbox: Path, baseline: set[str]) -> dict:
    changed: list[str] = []
    if (sandbox / ".git").exists():
        result = subprocess.run(
            ["git", "-C", str(sandbox), "status", "--porcelain"],
            capture_output=True,
            text=True,
        )
        for line in result.stdout.splitlines():
            status = line[:2]
            path = line[3:].strip()
            if " -> " in path:
                path = path.split(" -> ", 1)[1]
            path = path.strip('"')
            if not path or path.startswith(SUPPORT_PREFIXES):
                continue
            if status == "??" and path in baseline:
                continue
            changed.append(path)

    candidates: list[Path] = []
    evidence = sandbox / "evidence"
    if evidence.exists():
        candidates.extend(path for path in evidence.rglob("*") if path.is_file())
    for rel in changed:
        path = sandbox / rel
        if path.is_file():
            candidates.append(path)

    # A case can declare the source tree the judge needs to read, even when the
    # agent does not modify it (a review task reviews existing files).
    context_file = sandbox / "context.json"
    if context_file.exists():
        try:
            spec = json.loads(context_file.read_text(encoding="utf-8"))
            for rel in spec.get("paths", []):
                path = sandbox / rel
                if path.is_file():
                    candidates.append(path)
                elif path.is_dir():
                    candidates.extend(p for p in path.rglob("*") if p.is_file())
        except (OSError, json.JSONDecodeError):
            pass

    seen: set[str] = set()
    files = []
    for path in candidates:
        try:
            rel = str(path.relative_to(sandbox))
        except ValueError:
            continue
        if rel in seen:
            continue
        seen.add(rel)
        if path.suffix.lower() not in ARTIFACT_SUFFIXES:
            continue
        files.append((rel, path))
    files = files[:MAX_ARTIFACT_FILES]

    entries = []
    total = 0
    for rel, path in files:
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError as exc:
            text = f"<unreadable: {exc}>"
        text = text[:MAX_ARTIFACT_FILE_CHARS]
        if total + len(text) > MAX_ARTIFACT_CHARS:
            break
        total += len(text)
        entries.append({"path": rel, "chars": len(text), "content": text})

    diff = ""
    if (sandbox / ".git").exists():
        result = subprocess.run(
            [
                "git",
                "-C",
                str(sandbox),
                "diff",
                "--unified=3",
                "--",
                ".",
                ":(exclude)skills",
                ":(exclude)commands",
                ":(exclude)agents",
                ":(exclude).opencode",
                ":(exclude).claude",
                ":(exclude).codex",
                ":(exclude)AGENTS.md",
                ":(exclude)verify",
                ":(exclude)guard",
                ":(exclude)scripts",
                ":(exclude)docs",
            ],
            capture_output=True,
            text=True,
        )
        diff = result.stdout[:MAX_DIFF_CHARS]

    return {"changed": changed[:50], "files": entries, "diff": diff}


def artifacts_prompt(artifacts: dict) -> str:
    parts = []
    if artifacts["changed"]:
        parts.append("Changed or untracked paths:\n" + "\n".join(f"- {path}" for path in artifacts["changed"]))
    if artifacts["diff"]:
        parts.append("Diff (truncated):\n```\n" + artifacts["diff"] + "\n```")
    for entry in artifacts["files"]:
        parts.append(f"Artifact {entry['path']}:\n```\n{entry['content']}\n```")
    return "\n\n".join(parts) if parts else "(no artifacts produced)"


def extract_json(text: str) -> dict | None:
    match = re.search(r"\{.*\}", text, re.DOTALL)
    if not match:
        return None
    try:
        return json.loads(match.group(0))
    except json.JSONDecodeError:
        return None


def judge(
    prompt: str,
    output: str,
    artifacts: dict,
    rubric: dict,
    cwd: Path,
    judge_agent: str,
    judge_model: str,
    judge_profile: str | None,
    timeout: int,
) -> dict:
    criteria = json.dumps(rubric["criteria"], ensure_ascii=False)
    judge_source = Path(__file__).resolve().parents[1] / "agents" / "judge.md"
    judge_instructions = judge_source.read_text(encoding="utf-8")
    judge_prompt = (
        judge_instructions
        + "\n\n---\n\nRubric criteria (id, text, weight):\n"
        + criteria
        + "\n\nTask given to the agent:\n"
        + prompt
        + "\n\nAgent output:\n"
        + output
        + "\n\nArtifacts produced or modified:\n"
        + artifacts_prompt(artifacts)
        + "\n\nScore every criterion from 0 to 10, only on visible evidence. "
        + "Return only the JSON object described in your instructions. "
        + "Do not compute the weighted average; the harness does it."
    )
    with tempfile.TemporaryDirectory(prefix="eval-judge-") as tmp:
        judge_root = Path(tmp)
        result = run_agent(
            judge_agent,
            judge_prompt,
            judge_root,
            judge_model,
            judge_profile,
            timeout,
        )
    text = result.text
    data = extract_json(text)
    if not data:
        return {
            "scores": {},
            "pass": False,
            "invalid": True,
            "reasons": ["judge did not return JSON"],
            "missing": [],
            "judge_text": text[:500],
            "judge_meta": result.meta,
        }
    data["judge_meta"] = result.meta
    return data


def score_run(data: dict, rubric: dict) -> float:
    weights = {criterion["id"]: float(criterion.get("weight", 1)) for criterion in rubric["criteria"]}
    scores = data.get("scores")
    if isinstance(scores, dict) and scores:
        total = 0.0
        weight_sum = 0.0
        for key, weight in weights.items():
            total += float(scores.get(key, 0)) * weight
            weight_sum += weight
        if weight_sum:
            return round(total / weight_sum, 2)
    if isinstance(data.get("score"), (int, float)):
        return float(data["score"])
    return 0.0


def aggregate(scores: list[float]) -> dict:
    if not scores:
        return {"mean": 0.0, "min": 0.0, "max": 0.0, "stdev": 0.0}
    return {
        "mean": round(statistics.mean(scores), 2),
        "min": round(min(scores), 2),
        "max": round(max(scores), 2),
        "stdev": round(statistics.pstdev(scores), 2) if len(scores) > 1 else 0.0,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--case-dir", required=True)
    parser.add_argument("--rubric", default="evals/rubric.example.json")
    parser.add_argument("--agent", default="opencode")
    parser.add_argument("--agent-profile", default=None)
    parser.add_argument("--model", default=None)
    parser.add_argument("--judge-agent", default=None)
    parser.add_argument("--judge-agent-profile", default=None)
    parser.add_argument("--judge-model", default=None)
    parser.add_argument("--k", type=int, default=None)
    parser.add_argument("--out", default=None)
    parser.add_argument("--timeout", type=int, default=900)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--keep-sandbox", action="store_true")
    args = parser.parse_args()

    case_dir = Path(args.case_dir).resolve()
    task_file = case_dir / "TASK.md"
    if not task_file.exists():
        print(f"missing {task_file}", file=sys.stderr)
        return 2

    rubric = json.loads(Path(args.rubric).read_text(encoding="utf-8"))
    k = args.k or int(rubric.get("k", 1))
    model = args.model or rubric.get("model")
    judge_model = args.judge_model or rubric.get("judge_model") or model

    try:
        agent_name, inferred_profile = resolve_agent(args.agent)
        judge_name, inferred_judge_profile = resolve_agent(args.judge_agent or agent_name)
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 2
    agent_profile = args.agent_profile or inferred_profile
    judge_profile = args.judge_agent_profile or inferred_judge_profile

    if not args.dry_run and (not model or "REPLACE_WITH" in model):
        print("set --model or rubric.model to the company-approved provider/model", file=sys.stderr)
        return 2
    if not args.dry_run and (not judge_model or "REPLACE_WITH" in judge_model):
        print("set --judge-model or rubric.judge_model to a different approved model", file=sys.stderr)
        return 2

    repo = repo_root()
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    if args.out:
        out_dir = Path(args.out).resolve()
    else:
        out_dir = repo / "evals" / "runs" / f"{case_dir.name}-{stamp}"
    out_dir.mkdir(parents=True, exist_ok=True)

    baseline = {
        str(path.relative_to(case_dir))
        for path in case_dir.rglob("*")
        if path.is_file() and path.name != "TASK.md"
    }

    prompt = task_file.read_text(encoding="utf-8").strip()
    scores: list[float] = []
    total_tokens = 0
    total_cost = 0.0
    isolation_modes: list[str] = []

    for index in range(k):
        run_dir = out_dir / f"run-{index + 1}"
        run_dir.mkdir(parents=True, exist_ok=True)
        sandbox, cleanup, mode = make_sandbox(repo, case_dir, index, args.keep_sandbox)
        isolation_modes.append(mode)
        try:
            if args.dry_run:
                output = (
                    "CHANGED: none\n"
                    "RAN: bash verify/run.sh (exit 0)\n"
                    "EVIDENCE: evidence/20260101T000000Z-abc123\n"
                    "PENDING: none"
                )
                meta = {
                    "exit": 0,
                    "elapsed_s": 0.0,
                    "tokens": 0,
                    "cost": 0.0,
                    "timed_out": False,
                    "stderr_tail": "",
                }
                events = [{"type": "text", "part": {"text": output}}]
                artifacts = collect_artifacts(sandbox, baseline)
                judged = {
                    "scores": {criterion["id"]: 9.0 for criterion in rubric["criteria"]},
                    "reasons": ["dry run"],
                    "missing": [],
                }
            else:
                result = run_agent(
                    agent_name,
                    prompt,
                    sandbox,
                    model,
                    agent_profile,
                    args.timeout,
                )
                events, output, meta = result.events, result.text, result.meta
                artifacts = collect_artifacts(sandbox, baseline)
                if meta.get("timed_out") or meta.get("error"):
                    judged = {
                        "scores": {},
                        "pass": False,
                        "invalid": True,
                        "reasons": [meta.get("error") or "executor timed out"],
                        "missing": [],
                    }
                else:
                    judged = judge(
                        prompt,
                        output,
                        artifacts,
                        rubric,
                        sandbox,
                        judge_name,
                        judge_model,
                        judge_profile,
                        args.timeout,
                    )

            (run_dir / "events.jsonl").write_text(
                "\n".join(json.dumps(event, ensure_ascii=False) for event in events),
                encoding="utf-8",
            )
            (run_dir / "output.md").write_text(output, encoding="utf-8")
            (run_dir / "meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
            (run_dir / "artifacts.json").write_text(json.dumps(artifacts, indent=2), encoding="utf-8")
            if (sandbox / "evidence").exists():
                shutil.copytree(sandbox / "evidence", run_dir / "artifacts" / "evidence", dirs_exist_ok=True)

            value = score_run(judged, rubric)
            scores.append(value)
            total_tokens += int(meta.get("tokens") or 0)
            total_cost += float(meta.get("cost") or 0)
            judge_meta = judged.get("judge_meta") if isinstance(judged, dict) else None
            if isinstance(judge_meta, dict):
                total_tokens += int(judge_meta.get("tokens") or 0)
                total_cost += float(judge_meta.get("cost") or 0)
            (run_dir / "score.json").write_text(json.dumps(judged, indent=2), encoding="utf-8")
            print(f"{run_dir.name}: score {value}")
        finally:
            if not args.keep_sandbox:
                cleanup()

    summary = aggregate(scores)
    threshold = float(rubric.get("threshold", 8.5))
    result = {
        "case": case_dir.name,
        "skill": rubric.get("skill"),
        "agent": agent_name,
        "agent_profile": agent_profile,
        "judge_agent": judge_name,
        "model": model,
        "judge_model": judge_model,
        "k": k,
        "scores": scores,
        "aggregate": summary,
        "threshold": threshold,
        "passed": summary["mean"] >= threshold,
        "tokens": total_tokens,
        "cost": round(total_cost, 6),
        "isolation": sorted(set(isolation_modes)),
        "run_dir": str(out_dir),
    }
    (out_dir / "score.json").write_text(json.dumps(result, indent=2), encoding="utf-8")

    print(json.dumps(result, indent=2))
    return 0 if (result["passed"] or args.dry_run) else 1


if __name__ == "__main__":
    sys.exit(main())
