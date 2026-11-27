#!/usr/bin/env python3
"""Render one agent definition per team role from the neutral role contract.

The team flow declares its roles in `roles.json`. This script reads that file
and writes one Markdown agent per role for the requested agent, so several
people can run the same team on different agents without hand-copying the
contract. The contract stays the source of truth: every rendered file says so,
and `--check` fails when a rendered file is older than the contract.
"""

import argparse
import json
import os
import sys
import time
from pathlib import Path

TARGETS = {
    "claude": {
        "dir": ".claude/agents",
        "suffix": ".md",
    },
    "opencode": {
        "dir": ".opencode/agents",
        "suffix": ".md",
    },
}

READ_TOOLS = "Read, Grep, Glob"
WRITE_TOOLS = "Read, Grep, Glob, Edit, Write"
SHELL_TOOL = "Bash"
READONLY_BLOCKED = "Write, Edit, NotebookEdit"
DEFAULT_CLAUDE_MODELS = {
    "plan": "sonnet",
    "dev": "sonnet",
    "review": "opus",
    "verify": "sonnet",
    "judge": "opus",
}


class ContractError(Exception):
    pass


def load_contract(path):
    try:
        data = json.loads(Path(path).read_text(encoding="utf-8"))
    except FileNotFoundError:
        raise ContractError("roles contract not found: %s" % path)
    except ValueError as exc:
        raise ContractError("roles contract is not valid JSON: %s" % exc)
    roles = data.get("roles")
    if not isinstance(roles, list) or not roles:
        raise ContractError("roles contract declares no roles: %s" % path)
    placeholders = data.get("placeholders") or []
    for role in roles:
        for key in ("role", "stage", "writes", "reads", "readonly", "runs_on_copy", "exit"):
            if key not in role:
                raise ContractError("role %r is missing %r" % (role.get("role"), key))
        for step in role["exit"]:
            if not isinstance(step, dict) or "command" not in step or "expect" not in step:
                raise ContractError("role %r has an exit entry without command/expect" % role["role"])
    unknown = set()
    for role in roles:
        for text in [role["stage"]] + list(role["writes"]) + list(role["reads"]) + [s["command"] for s in role["exit"]]:
            for placeholder in placeholders:
                if placeholder in str(text):
                    unknown.add(placeholder)
    return data, roles, placeholders


def surface(role):
    writes = role.get("writes") or []
    return ", ".join(writes) if writes else "nothing"


def body(role, contract_path):
    lines = []
    lines.append("You are the `%s` role of the team declared in `%s`." % (role["role"], contract_path))
    lines.append("")
    lines.append("The contract is the source of truth: read it before acting, and when these lines")
    lines.append("disagree with it, the contract wins. The company norm is `~/.agents/AGENTS.md`.")
    lines.append("")
    lines.append("## Your stage: %s" % role["stage"])
    lines.append("")
    lines.append("- You write: %s" % surface(role))
    lines.append("- You read: %s" % (", ".join(role.get("reads") or []) or "the repository"))
    lines.append("- Read-only: %s" % ("yes, work on a copy" if role.get("readonly") else "no"))
    if role.get("runs_on_copy"):
        lines.append("- You work on a copy of the tree and prove the original unchanged with the contract's")
        lines.append("  snapshot and unchanged commands before and after your stage.")
    if role.get("owns_worktree"):
        lines.append("- You own the worktree: no second writer works in it while you do.")
    lines.append("")
    lines.append("## Exit")
    lines.append("")
    lines.append("Done means one of these commands ran and matched what it expects. Nothing else is done.")
    lines.append("")
    for step in role["exit"]:
        lines.append("```bash")
        lines.append(step["command"])
        lines.append("```")
        lines.append("")
        lines.append("Require: `%s`." % step["expect"])
        lines.append("")
    forbidden = role.get("forbidden") or []
    if forbidden:
        lines.append("Forbidden: %s." % ", ".join(forbidden))
        lines.append("")
    lines.append("## Handoff")
    lines.append("")
    lines.append("Every handoff cites `odd/tasks/<feature>.md`, the task ID and the `S#` list, plus the")
    lines.append("artifact path of the previous stage when one exists. \"It works\" is not a handoff.")
    lines.append("")
    lines.append("A gate you could not run is `ENV-FAIL`. Never report a pass on a check that did not run,")
    lines.append("and never describe a result you did not see in tool output.")
    lines.append("")
    return "\n".join(lines)


def frontmatter(role, target, model):
    name = role["role"]
    description = "%s stage: %s." % (name, role["stage"])
    if role.get("readonly"):
        description += " Read-only, works on a copy."
    fields = [("description", description)]
    if target == "claude":
        tools = READ_TOOLS + ("" if role.get("readonly") else ", Edit, Write")
        tools += ", " + SHELL_TOOL
        fields = [("name", name)] + fields
        fields.append(("tools", tools))
        if role.get("readonly"):
            fields.append(("disallowedTools", READONLY_BLOCKED))
        if model:
            fields.append(("model", model))
    else:
        fields.append(("mode", "subagent"))
        if model:
            fields.append(("model", model))
    head = ["---"]
    for key, value in fields:
        head.append("%s: %s" % (key, value))
    if target == "opencode" and role.get("readonly"):
        head.append("permissions:")
        head.append("  - action: edit")
        head.append('    resource: "*"')
        head.append("    effect: deny")
    head.append("---")
    head.append("")
    return "\n".join(head)


def render(role, target, contract_path, model):
    return frontmatter(role, target, model) + body(role, contract_path) + "\n"


def contract_reference(contract_file):
    relative = os.path.relpath(contract_file)
    return contract_file if relative.startswith("..") else relative


def render_all(contract_file, target, out_dir, models):
    data, roles, _placeholders = load_contract(contract_file)
    reference = contract_reference(contract_file)
    rendered = {}
    for role in roles:
        name = role["role"]
        text = render(role, target, reference, models.get(name))
        rendered[Path(out_dir) / (name + TARGETS[target]["suffix"])] = text
    return rendered


def main(argv=None):
    parser = argparse.ArgumentParser(
        prog="render-roles.py",
        description="Render one agent definition per team role from roles.json.",
    )
    parser.add_argument("--roles", required=True, help="path to the team roles.json")
    parser.add_argument("--target", required=True, choices=sorted(TARGETS))
    parser.add_argument("--out", help="output directory (default: the target's project directory)")
    parser.add_argument("--model-map", help="JSON file mapping role name to a model for this target")
    parser.add_argument("--check", action="store_true", help="verify the rendered files are current; write nothing")
    parser.add_argument("--force", action="store_true", help="overwrite rendered files without a backup")
    args = parser.parse_args(argv)

    models = {}
    if args.model_map:
        try:
            models = json.loads(Path(args.model_map).read_text(encoding="utf-8"))
        except (OSError, ValueError) as exc:
            print("model map unreadable: %s" % exc, file=sys.stderr)
            return 2
    elif args.target == "claude":
        models = dict(DEFAULT_CLAUDE_MODELS)

    out_dir = args.out or TARGETS[args.target]["dir"]
    try:
        rendered = render_all(args.roles, args.target, out_dir, models)
    except ContractError as exc:
        print(str(exc), file=sys.stderr)
        return 2

    stale = []
    for path, text in sorted(rendered.items()):
        current = path.read_text(encoding="utf-8") if path.exists() else None
        if current == text:
            continue
        stale.append(path)
        if args.check:
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        if current is not None and not args.force:
            stamp = time.strftime("%Y%m%d-%H%M%S")
            backup = path.with_suffix(path.suffix + ".bak-" + stamp)
            backup.write_text(current, encoding="utf-8")
        path.write_text(text, encoding="utf-8")
        print("rendered: %s" % path)

    if args.check:
        for path in stale:
            print("stale: %s" % path, file=sys.stderr)
        if stale:
            return 1
        print("roles: up to date for %s" % args.target)
        return 0

    if not stale:
        print("roles: already up to date for %s" % args.target)
    return 0


if __name__ == "__main__":
    sys.exit(main())
