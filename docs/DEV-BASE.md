# The development base

The core `dev-agent-kit` covers any development repository. The Odoo 11 specifics live in
the separate profiles repository, at `dev-agent-profiles/profiles/odoo11`; the PHP
skeleton is `dev-agent-profiles/profiles/php`. The core does not import Odoo, PHP or Node.

## What it covers

- `guard/guard.sh`: generic checks and the active profile checks.
- `verify/run.sh`: boot, health, smoke, tests and evidence.
- `evals/harness.py`: K runs, artifacts, judge and score.
- `hooks/`: pre-commit and pre-push with backups.
- `.opencode/skills/`: five generic skills.
- `profiles/_template/`: the contract for a new environment.

## The gate

A change is done only after `guard` and `verify` have run on it and left evidence. The
profile's `guard/` and `verify/config.env` supply the language commands; the core supplies
the mechanism.

## Isolation

Evals run in a disposable worktree or copy; Odoo verify uses a disposable database. The
shared `scalpers` database is never a test target.

## The order

1. Spec or reproduction.
2. Guard.
3. Verify.
4. Eval when a skill, prompt, rule or rubric changes.
5. Human review and repository policy.
