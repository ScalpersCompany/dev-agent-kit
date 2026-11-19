# Profile template

This is the starting point for a new environment. Copy it with
`scripts/new-profile.sh <name> --repo <profiles-repo>`; do not edit the template in
place for a real profile.

## What a profile owns

- `profile.json`: the machine-readable contract.
- `profile.env`: the values the core reads.
- `AGENTS.fragment.md`: language rules appended to the repo `AGENTS.md`.
- `guard/`: executable checks, one `.sh` per check.
- `verify/config.env.example`: boot, health, smoke, test and timeout.
- `skills/`: domain skills only; the core skills are not copied here.
- `evals/cases/`: a case per skill or review rule that changes.
- `tests/`: tests for the profile's own scripts.
- `docs/`: profile-specific documentation.
- `CHANGELOG.md`: what changed in the profile.

## What the core owns

The core owns `guard/guard.sh`, `verify/run.sh`, `evals/harness.py`, the git hooks and
the five generic skills (`dev-verify`, `repro-first`, `review-diff`, `correct`,
`query-readonly`) under `skills/`. The hooks are shared: a profile changes what the hook
executes, not the hook itself.

SDD is the `spec-driven-development` skill. ODD is always-on `AGENTS.md`/`SOUL.md` text; it
is not a skill. RDD is the `gentle-ai review` binary; it is not a skill. rsc-harness skills
are repo-local in `.rsc/skills`; do not copy them here. `gentle-ai` installs and synchronises
agents, skills and MCP; it does not replace rsc-harness.

## Steps

1. Generate the directory:
   `bash scripts/new-profile.sh php --language php --repo /path/to/dev-agent-profiles`.
2. Fill `profile.json`: name, version, language, description.
3. Fill `profile.env`: name, language, guard, verify, skills, evals and agents paths.
4. Write `AGENTS.fragment.md`: version, build, tests, lint and domain rules.
5. Add at least one executable `guard/*.sh`; see `guard/README.md`.
6. Fill `verify/config.env.example`; never use a shared or production database.
7. Add domain skills to `skills/`; add an eval case and rubric if the skill or rule changes.
8. Add tests for the guard and any script; run `python3 scripts/validate-profile.py <profile>`.
9. Commit the profile with its `CHANGELOG.md` entry; the core validator is the source of truth.
10. Install it in a target repo by copying it to `.dev-agent/profiles/<name>` and writing
    `.dev-agent/config` with `DEV_AGENT_PROFILE=<name>`; the core `guard.sh` then runs it.

The full `dev-agent init` installer is still pending; until then this copy-and-config path
is the supported install.

## Guard contract

- One executable `.sh` per check under `guard/`.
- Accept `--staged`; use `GUARD_ROOT` for the target repository.
- Exit non-zero when the check finds a defect; print a short finding.
- Do not write secrets, do not call the network, do not mutate the repo.
- No prose comments in the script; a legal header and tool directives are allowed.

## Verify contract

`verify/config.env.example` must define `BOOT_CMD`, `HEALTH_URL`, `SMOKE_CMD`, `TEST_CMD`
and `HEALTH_TIMEOUT`. `TEST_CMD` must exercise the change, not a smoke unrelated to it. A
missing config is exit 2, not green.

## Evaluation

The core harness is shared, but the runner is still OpenCode-only; the neutral runner is a
pending change. Run K=3 with a judge different from the executor and threshold 8.5. A case
without a rubric or without `context.json` is not a real eval. Record the result in
`docs/EVAL-BASELINE.md`.
