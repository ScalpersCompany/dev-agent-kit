# Agents

Neutral source for the eval judge prompt and the agent adapters. One file, installed per agent
by `scripts/install-agent-adapters.sh`.

## Judge

`judge.md` is the strict JSON judge used by the eval harness. The harness reads the file and
passes it to the chosen executor as text, so the prompt body is what matters there; the
frontmatter matters when a person runs the judge as an agent inside an editor.

The frontmatter carries both shapes on purpose, because the kit supports OpenCode 1 and 2:

- `permissions` is the OpenCode v2 shape. `edit` and `shell` are denied there; v2 ignores the
  legacy `tools` map.
- `tools` is the OpenCode v1 shape. v1 ignores `permissions`.

A judge installed with only `tools` loads in v2 with the default `* allow` permissions, which is
the opposite of a read-only judge. That is why both blocks are here, and why
`tests/test_agent_adapters.py` fails when the v2 block disappears.

The eval runner is no longer OpenCode-only: `evals/agent_runner.py` normalizes OpenCode,
Claude Code, Codex, pi and Hermes, and the judge receives the same rubric and artifacts
whatever the executor is.

## Installed paths

| Agent | Agent files | Skills | Commands |
|---|---|---|---|
| OpenCode v2 | `.opencode/agents/<name>.md` | `.opencode/skills/` | `.opencode/commands/` |
| Claude Code | `.claude/agents/<name>.md` | `.claude/skills/` | `.claude/commands/` |
| pi | `~/.pi/agent/agents/<name>.md` (its own frontmatter, `tools` as a list) | `~/.pi/agent/skills/` | none |
| Codex | none: it has no agent-file format | `~/.codex/skills/` (kit convention; Codex reads `AGENTS.md` and its own prompts) | none |
| Hermes | none: a role is a profile, not a file | `~/.hermes/skills/` | none |

OpenCode v2 still discovers the legacy `.opencode/agent/` directory for compatibility. The kit
does not write it: the canonical path is `agents/`, and depending on a compatibility alias is
not a contract. When the installer finds `agent/judge.md`, it renames it to
`judge.md.bak-<stamp>` so a stale copy cannot shadow the installed one.

Skills and commands are agent-neutral; `.opencode/` and `.claude/` are generated adapters, not
source. `scripts/render-roles.py` writes one agent per role for Claude Code and OpenCode v2 from
the team profile's `roles.json`; this script installs the judge and the neutral skills and
commands, and neither replaces the other.
