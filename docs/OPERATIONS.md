# Operations

## What moves a change

1. **Spec or reproduction.** For a bug, a failing test first. For a feature, a written
   spec with acceptance criteria.
2. **Guard.** `bash guard/guard.sh --staged` in the pre-commit hook. It runs the generic
   checks and, if a profile is active, the profile's `guard/*.sh`.
3. **Verify.** `bash verify/run.sh` boots, checks health, runs smoke and tests, and writes
   `evidence/<run-id>/summary.json`.
4. **Eval.** Only when a skill, prompt, rule or rubric changes. K=3, a judge different from
   the executor, threshold 8.5.
5. **Review and delivery.** A human reads the diff. The repository decides push, PR and CI.

## The gate

`guard` and `verify` are mandatory; the eval is not a per-commit ceremony. The pre-commit
hook catches staged defects; the pre-push hook runs verify and fails closed when
`.dev-agent/verify.env` has no `TEST_CMD`. Both can be bypassed with `--no-verify`; the CI
is the hard gate and can only be bypassed with a human decision recorded in the repo.

## Profiles

The core is language-agnostic. A profile supplies `profile.json`, `profile.env`, `guard/`,
`verify/`, `skills/`, `evals/` and `AGENTS.fragment.md`. The core `guard.sh` reads
`.dev-agent/config` (`DEV_AGENT_PROFILE=<name>`) and runs the profile's guard scripts.

- Odoo 11: `dev-agent-profiles/profiles/odoo11`, local repo; remote pending.
- PHP: `dev-agent-profiles/profiles/php`, skeleton.
- Template: `profiles/_template`.
- Design: `docs/PERFILES-EN-REPOS.md`.

The git hooks are shared. The profile changes what the hook executes, not the hook itself.

## Skills

Core skills are `dev-verify`, `repro-first`, `review-diff`, `correct` and `query-readonly`.
They are installed in the agents' skills directories and copied from `.opencode/skills/`.
The Odoo domain skills are in the profile. SDD is `spec-driven-development`; ODD is
always-on `AGENTS.md`/`SOUL.md` text; RDD is the `gentle-ai review` binary. None of ODD or
RDD is a skill.

## GGA

GGA is an optional AI reviewer, not a gate. Install it with `scripts/install-gga.sh <repo>`
and run it with `scripts/review-gga.sh <repo>`; `GGA_ADVISORY=1` reports without blocking.
Do not run `gga install`: it would replace the kit's pre-commit hook. If there is no
provider or no `.gga`, the script says so; it is not green.

## Layers

- `rsc-harness`: process, spec and ASDD; skills are repo-local in `.rsc/skills`.
- `dev-agent-kit`: the deterministic gate and the hooks.
- `gentle-ai`: installs and synchronises agents, skills and MCP; it does not replace
  rsc-harness.
- `rsc-brain`: curated knowledge.
- `engram`: project memory.

The agent is interchangeable; the gate is a command.

## Status

| Area | State |
|---|---|
| core guard, verify, evals, hooks | implemented and tested |
| Odoo 11 profile | extracted locally; remote pending |
| PHP profile | skeleton; no runtime yet |
| `dev-agent init` and the lock | designed; not implemented |
| GGA | optional; installation tested; no real review run |
| `comment_lint` for PHP | pending |
| Scalpers CI | not touched |
