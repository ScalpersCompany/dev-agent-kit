# Operations

## What moves a change

1. **Spec or reproduction.** For a bug, a failing test first. For a feature, a written
   spec with acceptance criteria.
2. **Guard.** `bash guard/guard.sh --staged` in the pre-commit hook. It runs the generic
   checks and, if a profile is active, the profile's `guard/*.sh`.
3. **Verify.** `bash verify/run.sh` boots, checks health, runs smoke, tests and the complete
   E2E suite, and writes `evidence/<run-id>/summary.json` plus `evidence/<run-id>/e2e/`
   with the Playwright HTML report, JUnit/JSON, traces and screenshots.
4. **Eval.** Only when a skill, prompt, rule or rubric changes. K=3, a judge different from
   the executor, threshold 8.5. `evals/agent_runner.py` runs OpenCode, Claude, Codex, pi or
   Hermes; the judge receives the same rubric and artifacts.
5. **Review and delivery.** A human reads the diff. The repository decides push, PR and CI.

## The gate

`guard` and `verify` are mandatory; the eval is not a per-commit ceremony. The pre-commit
hook catches staged defects; the pre-push hook runs verify and fails closed when
`.dev-agent/verify.env` has no `TEST_CMD` or `E2E_CMD`. Both can be bypassed with
`--no-verify`; the CI is the hard gate and can only be bypassed with a human decision
recorded in the repo.

## Profiles

The core is language-agnostic. A profile supplies `profile.json`, `profile.env`, `guard/`,
`verify/`, `skills/`, `evals/` and `AGENTS.fragment.md`. The core `guard.sh` reads
`.dev-agent/config` (`DEV_AGENT_PROFILE=<name>`) and runs the profile's guard scripts.

- Odoo 11: `ScalpersCompany/dev-agent-profiles/profiles/odoo11`, public repo.
- PHP: `ScalpersCompany/dev-agent-profiles/profiles/php`.
- Hexagonal microservices: `ScalpersCompany/dev-agent-profiles/profiles/hexagonal`.
- Template: `profiles/_template`.
- Design: `docs/PERFILES-EN-REPOS.md`.
- New profile: `docs/CREAR-PERFIL.md`; generate with `scripts/new-profile.sh` and validate with `scripts/validate-profile.py`.

The git hooks are shared. The profile changes what the hook executes, not the hook itself.

## Skills

Core skills are `dev-verify`, `repro-first`, `review-diff`, `correct` and `query-readonly`.
They are installed in the agents' skills directories from `skills/` through the adapter script or `gentle-ai sync`.
The Odoo domain skills are in the profile. SDD is `spec-driven-development`; ODD is
always-on `AGENTS.md`/`SOUL.md` text; RDD is the `gentle-ai review` binary. None of ODD or
RDD is a skill.

## GGA

GGA is the second reviewer, not the deterministic gate. The main installer asks whether to
install the active profile's rules; the lower-level command is
`scripts/install-gga.sh <repo> --profile <profile-dir>`. The core rules are language-agnostic
and the active profile appends its `gga/REVIEW-RULES.md` (Odoo 11, PHP 8, or the new profile's
own). The company norm still wins. `scripts/review-gga.sh <repo>` is blocking by default and
requires `STATUS: PASSED`; `--advisory` or `GGA_ADVISORY=1` reports without blocking.
`install-gga.sh --with-pre-push` enables the GGA gate after verify in `.dev-agent/gga.env`.
Do not run `gga install`: it would replace the kit's pre-commit hook. If there is no provider
or no `.gga`, the blocking review says so; it is not green.

## Layers

### Repositories

| Repository | Role |
|---|---|
| `ScalpersCompany/dev-agent-kit` | deterministic gate and hooks |
| `ScalpersCompany/dev-agent-profiles` | Odoo 11 and PHP profiles |
| `ScalpersCompany/scalpers-tech-doc` | company norm and documentation; canonical `AGENTS.md`, linked at `~/.agents/AGENTS.md`; checked by `scripts/check-techdoc.sh` |
| The repository where development happens | product code (Odoo, PHP, any stack); install the kit and the active profile at its root |

They are separate repositories, not submodules. The company norm wins; the kit and the
profile only reference it.

- `rsc-harness`: process, spec and ASDD; skills are repo-local in `.rsc/skills`.
- `dev-agent-kit`: the deterministic gate and the hooks.
- `gentle-ai`: installs and synchronises agents, skills and MCP; it does not replace
  rsc-harness.
- Knowledge/wiki layer: deferred until there is AWS infrastructure.
- `engram`: project memory; local until the AWS infrastructure exists.

The agent is interchangeable; the gate is a command.

## Status

| Area | State |
|---|---|
| core guard, verify, evals, hooks | implemented and tested |
| Odoo 11 profile | extracted to `ScalpersCompany/dev-agent-profiles`; public |
| PHP profile | skeleton; no runtime yet |
| `install.sh` | implemented; one-line installer with menu; `dev-agent` is the wrapper |
| `bootstrap --profile` | implemented; lower-level path that copies the active profile and writes `.dev-agent/config` |
| `dev-agent init` and the lock | implemented: alias of `install.sh`; lock written to `.dev-agent/profiles.lock` |
| eval runner | implemented for OpenCode, Claude, Codex, pi and Hermes; Codex needs its own login |
| GGA | rules, blocking review and optional pre-push gate |
| `comment_lint` for PHP | implemented |
| Scalpers CI | not touched |
