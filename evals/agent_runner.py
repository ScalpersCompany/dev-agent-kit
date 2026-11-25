#!/usr/bin/env python3
"""Agent-neutral runner used by the eval harness and the hill-climb loop."""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any

AGENTS = ("opencode", "claude", "codex", "pi", "hermes")
ALIASES = {"build": "opencode", "plan": "opencode", "judge": "opencode"}
DEFAULT_MAX_TURNS = 30


@dataclass
class AgentResult:
    events: list[dict[str, Any]]
    text: str
    meta: dict[str, Any]


def resolve_agent(name: str | None) -> tuple[str, str | None]:
    if not name:
        return "opencode", None
    if name in AGENTS:
        return name, None
    if name in {"build", "plan"}:
        return "opencode", name
    if name == "judge":
        return "opencode", None
    raise ValueError(f"unknown agent: {name}; expected one of {', '.join(AGENTS)}")


def agent_command(agent: str, prompt: str, model: str | None, profile: str | None, timeout: int) -> list[str]:
    if agent == "opencode":
        cmd = ["opencode", "run", "--standalone", "--format", "json"]
        if profile:
            cmd += ["--agent", profile]
        if model:
            cmd += ["--model", model]
        cmd.append(prompt)
        return cmd
    if agent == "claude":
        cmd = [
            "claude",
            "-p",
            prompt,
            "--output-format",
            "json",
            "--no-session-persistence",
            "--max-turns",
            str(DEFAULT_MAX_TURNS),
            "--permission-mode",
            "acceptEdits",
            "--allowedTools",
            "Read,Write,Edit,Bash",
        ]
        if model:
            cmd += ["--model", model]
        return cmd
    if agent == "codex":
        cmd = [
            "codex",
            "exec",
            "--json",
            "--sandbox",
            "workspace-write",
            "--ephemeral",
            "--skip-git-repo-check",
        ]
        if model:
            cmd += ["--model", model]
        cmd.append(prompt)
        return cmd
    if agent == "pi":
        cmd = ["pi", "-p", "--no-session", "--mode", "json"]
        if model:
            cmd += ["--model", model]
        cmd.append(prompt)
        return cmd
    if agent == "hermes":
        cmd = ["hermes", "-z", prompt, "--usage-file", "__USAGE_FILE__"]
        if model:
            cmd += ["-m", model]
        return cmd
    raise ValueError(f"unknown agent: {agent}")


def _strings(value: Any) -> list[str]:
    if isinstance(value, str):
        return [value]
    if isinstance(value, list):
        result: list[str] = []
        for item in value:
            result.extend(_strings(item))
        return result
    if isinstance(value, dict):
        preferred = (
            "result",
            "text",
            "message",
            "content",
            "output",
            "last_message",
            "response",
            "aggregated_output",
        )
        result: list[str] = []
        for key in preferred:
            if key in value:
                result.extend(_strings(value[key]))
        if result:
            return result
        for key, item in value.items():
            if key in {"type", "event", "id", "status", "role", "model", "usage", "tokens", "cost", "timestamp", "session_id", "kind"}:
                continue
            result.extend(_strings(item))
        return result
    return []


def _extract_text(payload: Any) -> str:
    values = _strings(payload)
    return values[-1].strip() if values else ""


def _sum_tokens(value: Any) -> int:
    total = 0
    if isinstance(value, dict):
        for key, item in value.items():
            if key in {"total", "total_tokens", "input_tokens", "output_tokens", "reasoning_tokens", "input", "output", "reasoning"}:
                if isinstance(item, (int, float)):
                    total += int(item)
            elif isinstance(item, (dict, list)):
                total += _sum_tokens(item)
    elif isinstance(value, list):
        for item in value:
            total += _sum_tokens(item)
    return total


def _sum_cost(value: Any) -> float:
    total = 0.0
    if isinstance(value, dict):
        for key, item in value.items():
            if key in {"cost", "total_cost_usd", "total_cost", "cost_usd"} and isinstance(item, (int, float)):
                total += float(item)
            elif isinstance(item, (dict, list)):
                total += _sum_cost(item)
    elif isinstance(value, list):
        for item in value:
            total += _sum_cost(item)
    return total


def parse_output(agent: str, stdout: str, stderr: str, exit_code: int, elapsed: float, timed_out: bool, usage_file: Path | None = None) -> AgentResult:
    meta: dict[str, Any] = {
        "agent": agent,
        "exit": exit_code,
        "elapsed_s": round(elapsed, 2),
        "tokens": 0,
        "cost": 0.0,
        "timed_out": timed_out,
        "stderr_tail": stderr[-800:],
    }
    text = ""
    events: list[dict[str, Any]] = []

    if usage_file and usage_file.exists():
        try:
            usage = json.loads(usage_file.read_text(encoding="utf-8"))
            meta["tokens"] += _sum_tokens(usage)
            meta["cost"] += _sum_cost(usage)
        except (OSError, json.JSONDecodeError):
            pass

    if agent == "claude":
        try:
            payload = json.loads(stdout)
        except json.JSONDecodeError:
            payload = None
        if isinstance(payload, dict):
            text = str(payload.get("result") or "").strip()
            meta["tokens"] += _sum_tokens(payload.get("usage"))
            meta["cost"] += _sum_cost(payload)
            events = [{"type": "result", "result": payload}]
        else:
            text = stdout.strip()
    elif agent in {"opencode", "codex", "pi"}:
        for line in stdout.splitlines():
            line = line.strip()
            if not line.startswith("{"):
                continue
            try:
                events.append(json.loads(line))
            except json.JSONDecodeError:
                continue
        if events:
            texts = []
            for event in events:
                part = event.get("part") if isinstance(event, dict) else None
                if isinstance(part, dict) and event.get("type") == "text" and part.get("text"):
                    texts.append(str(part["text"]))
                elif agent in {"codex", "pi"}:
                    value = _extract_text(event)
                    if value:
                        texts.append(value)
            text = texts[-1].strip() if texts else ""
            meta["tokens"] += _sum_tokens(events)
            meta["cost"] += _sum_cost(events)
        else:
            text = stdout.strip()
    else:
        text = stdout.strip()

    if not text and stderr.strip():
        text = stderr.strip()
    meta["chars"] = len(text)
    return AgentResult(events=events, text=text, meta=meta)


def run_agent(
    agent: str,
    prompt: str,
    cwd: Path,
    model: str | None,
    profile: str | None = None,
    timeout: int = 900,
) -> AgentResult:
    agent, inferred_profile = resolve_agent(agent)
    profile = profile or inferred_profile
    binary = agent
    if not shutil.which(binary):
        return AgentResult(
            events=[],
            text="",
            meta={
                "agent": agent,
                "exit": 127,
                "elapsed_s": 0.0,
                "tokens": 0,
                "cost": 0.0,
                "timed_out": False,
                "stderr_tail": f"{binary}: command not found",
                "error": "agent_not_installed",
            },
        )

    usage_file: Path | None = None
    if agent == "hermes":
        handle = tempfile.NamedTemporaryFile(prefix="hermes-usage-", suffix=".json", delete=False)
        handle.close()
        usage_file = Path(handle.name)

    cmd = agent_command(agent, prompt, model, profile, timeout)
    if usage_file:
        cmd = [str(usage_file) if item == "__USAGE_FILE__" else item for item in cmd]

    started = time.time()
    try:
        proc = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
            cwd=str(cwd),
        )
    except subprocess.TimeoutExpired as exc:
        if usage_file:
            usage_file.unlink(missing_ok=True)
        return AgentResult(
            events=[],
            text="",
            meta={
                "agent": agent,
                "exit": 124,
                "elapsed_s": round(time.time() - started, 2),
                "tokens": 0,
                "cost": 0.0,
                "timed_out": True,
                "stderr_tail": str(exc)[-800:],
            },
        )
    except OSError as exc:
        if usage_file:
            usage_file.unlink(missing_ok=True)
        return AgentResult(
            events=[],
            text="",
            meta={
                "agent": agent,
                "exit": 127,
                "elapsed_s": round(time.time() - started, 2),
                "tokens": 0,
                "cost": 0.0,
                "timed_out": False,
                "stderr_tail": str(exc)[-800:],
                "error": "agent_start_failed",
            },
        )

    result = parse_output(
        agent,
        proc.stdout,
        proc.stderr,
        proc.returncode,
        time.time() - started,
        False,
        usage_file,
    )
    if usage_file:
        usage_file.unlink(missing_ok=True)
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--agent", default="opencode")
    parser.add_argument("--profile", default=None)
    parser.add_argument("--model", default=None)
    parser.add_argument("--prompt", default=None)
    parser.add_argument("--prompt-file", default=None)
    parser.add_argument("--cwd", default=None)
    parser.add_argument("--timeout", type=int, default=900)
    args = parser.parse_args()

    prompt = args.prompt
    if args.prompt_file:
        prompt = Path(args.prompt_file).read_text(encoding="utf-8")
    if not prompt:
        print("missing --prompt or --prompt-file", file=sys.stderr)
        return 2

    result = run_agent(
        args.agent,
        prompt,
        Path(args.cwd).resolve() if args.cwd else Path.cwd(),
        args.model,
        args.profile,
        args.timeout,
    )
    if result.text:
        print(result.text)
    else:
        print(json.dumps(result.meta, ensure_ascii=False), file=sys.stderr)
    return 0 if result.text and result.meta.get("exit") == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
