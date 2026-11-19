# Agents

Neutral source for the eval judge prompt and the agent adapters.

- `judge.md` is the strict JSON judge used by the eval harness. Its frontmatter is an
  OpenCode agent definition because the harness still runs through OpenCode; the prompt
  body is portable.
- The harness is the only remaining OpenCode-specific piece. A project-level adapter is
  generated with `scripts/install-agent-adapters.sh <repo> --agents opencode`.
- Skills and commands are agent-neutral; `.opencode/` and `.claude/` are generated
  adapters, not source.

The OpenCode coupling of the eval runner is a known gap. The gates (`guard`, `verify`) and
the skills are agent-neutral; the eval tool is not yet.
