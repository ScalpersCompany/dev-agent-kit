# Dev agent kit

A repo-local kit to make agents trustworthy on a development codebase. It implements executable verification, skills built from observed failures, agent evals and deterministic guardrails before prose. The core is language-agnostic; Odoo, PHP and other environments live in profiles.

Start here: `docs/INSTALACION-Y-FUNCIONAMIENTO.md` (Spanish) — install, daily flow, guard, verify, evals, GGA, profiles, security and the implemented-versus-pending status.

The Odoo 11 profile now lives in the separate profiles repository, at
`/home/scalpers/dev-agent-profiles/profiles/odoo11` locally. Its remote is pending.

## Scope

This kit is for the development base, not production. Production receives only changes that pass `guard/guard.sh`, `verify/run.sh`, the applicable eval and the evidence gate. The kit is the filter; it is not deployed to production.

## Core

```text
AGENTS.md                     generic rules the agent reads first
skills/                       five core skills: dev-verify, repro-first, review-diff, correct, query-readonly
commands/                     neutral prompt templates; adapters install them per agent
agents/                       eval judge prompt; adapters install it for OpenCode
scripts/install-agent-adapters.sh  generates .opencode/.claude adapters from the neutral source
verify/run.sh                 boot, smoke, tests, evidence/
guard/guard.sh                generic checks plus the active profile checks
guard/comment_lint.py         blocks new comments in staged code
evals/harness.py              k runs per case in a disposable worktree or copy, artifacts, judge, score.json
evals/cases/                  dev-verify, repro-first, review-diff
evals/rubric.*.json           rubrics for those cases
evals/loop.sh                 hill climb until the score passes
profiles/_template/           contract, env, guard, verify, skills, evals and docs for a new profile
scripts/new-profile.sh        creates a profile from the template with a backup
scripts/validate-profile.py  validates profile.json, profile.env and the profile paths
gga/                          optional AI review: .gga example and rules
scripts/install-gga.sh        installs .gga and .gga-rules.md with backups
scripts/review-gga.sh         runs gga on staged files, optional or blocking
scripts/bootstrap.sh          copies the core into a repo, creates verify config and installs hooks
scripts/new-profile.sh        creates a profile from profiles/_template with a backup
scripts/validate-profile.py   validates the profile contract and paths
scripts/install-hooks.sh      installs the hooks and backs up the existing ones
hooks/pre-commit              local pre-commit: guard --staged
hooks/pre-push                local pre-push: verify/run.sh
tests/test_comment_lint.py    unit tests for the comment gate
.github/workflows/quality.yml unit tests, syntax and eval dry-run in CI
docs/                         install, operations, architecture, profiles, coverage
docs/CREAR-PERFIL.md          how to build a new profile
docs/DIAGRAMA-SISTEMA.md      Mermaid map of the whole system
docs/diagrams/sistema.html    visual overview of the flow and the layers
docs/diagrams/flujo-detallado.html  detailed flow with decisions, loops and artifacts
CHANGELOG.md
```

The core has no `odoo_lint`, Odoo allowlist, Odoo skills, Odoo eval cases or Odoo docs. Those are in the Odoo profile. The core has no PHP either.

## Install (automated, current)

From this kit:

```bash
bash scripts/bootstrap.sh /path/to/development-repo
bash scripts/bootstrap.sh /path/to/development-repo --with-verify
bash scripts/bootstrap.sh /path/to/development-repo --with-gga
```

The bootstrap copies `AGENTS.md`, `skills/`, `commands/`, `agents/`, `verify/`, `guard/`, `evals/`, `scripts/`, `docs/` and `profiles/_template/`; backs up anything it replaces as `.bak-<timestamp>`; creates `verify/config.env` from the example; and installs the pre-commit hook. `--with-verify` adds the pre-push gate and `.dev-agent/verify.env`; `--with-gga` adds the optional GGA files. It does not touch production, git history or a profile registry.

The full profile installer (`dev-agent init --profile ... --all`) is designed but not wired yet; `scripts/bootstrap.sh` is the current automated core path.

## Profiles

All profiles can live in one private repository, `dev-agent-profiles`, with one directory per profile (`profiles/odoo11`, `profiles/php`). The core keeps the contract, the registry and the installer; the profile keeps its `profile.json`, `profile.env`, `guard/`, `verify/`, `skills/`, `evals/` and `AGENTS.fragment.md`.

The git hooks are **not** different per profile: the same core `pre-commit` and `pre-push` read the active profile and run its checks. What differs is the content the hook executes: guard checks, verify config, skills, eval cases and the AGENTS fragment.

SDD is the `spec-driven-development` skill. ODD is always-on text in `AGENTS.md`/`SOUL.md`, not a skill. RDD is the `gentle-ai review` binary, not a skill. The rsc-harness skills (`asdd`, `sdd-init`, `harness`, `verify`...) are repo-local in `.rsc/skills/`; gentle-ai installs and synchronises agents and does not replace rsc-harness.

## Create a profile

The base template is `profiles/_template`; the guide is `docs/CREAR-PERFIL.md`.

```bash
bash scripts/new-profile.sh php-nuevo \
  --language php \
  --repo /home/scalpers/dev-agent-profiles \
  --description "PHP 8 with PHPStan, PHPCS and PHPUnit"
python3 scripts/validate-profile.py /home/scalpers/dev-agent-profiles/profiles/php-nuevo
```

The generator copies the template, backs up an existing profile as `.bak-<timestamp>` and fills the name and language. The validator checks the contract, `profile.env` and every path. A profile that does not validate is not installable.

The visual map of the system is in `docs/diagrams/sistema.html`; the detailed flow with decisions, loops and artifacts is in `docs/diagrams/flujo-detallado.html`. The Mermaid version and the status table are in `docs/DIAGRAMA-SISTEMA.md`.

## Status

| Area | State |
|---|---|
| core `guard`, `verify`, evals, pre-commit/pre-push | implemented and covered by tests |
| Odoo 11 profile | extracted to `dev-agent-profiles/profiles/odoo11`; local; remote pending |
| PHP profile | skeleton moved to the profiles repository; PHPStan/PHPCS/PHPUnit not wired |
| `dev-agent init` and the profile lock | designed; not implemented |
| profile template, `new-profile.sh` and `validate-profile.py` | implemented and tested |
| visual system map | `docs/diagrams/sistema.html` and `docs/DIAGRAMA-SISTEMA.md` |
| detailed flow | `docs/diagrams/flujo-detallado.html` and the Mermaid section in `docs/DIAGRAMA-SISTEMA.md` |
| eval runner agent-neutral | pending: `evals/harness.py` and `evals/loop.sh` still use OpenCode |
| GGA advisory review | added; installation tested; no real review run |
| `comment_lint` for PHP | pending; the generic checker does not scan `.php` yet |
| `gentle-ai`, `rsc-harness`, `rsc-brain`, `engram` | documented boundaries; rsc-harness is not replaced by gentle-ai |
| Scalpers CI | not touched; local gates are the current hard check |

## Agents and shared rules

The gates are plain bash/Python 3.8+ and git hooks, so Hermes, OpenCode, Claude Code, Codex and pi run the same commands. Skills are `SKILL.md` files under `skills/`; `scripts/install-agent-adapters.sh <repo> --agents opencode,claude` generates the project-level copies, and `gentle-ai sync` handles the global ones. The eval harness is the exception: it still runs through OpenCode, and that is a known gap. The shared rule is `~/.agents/AGENTS.md`, linked from `SOUL.md`, OpenCode's `AGENTS.md` and Claude's `CLAUDE.md`.

## GGA (optional)

`scripts/install-gga.sh <repo>` copies `.gga` and `.gga-rules.md` with backups; `scripts/review-gga.sh <repo>` runs `gga` on staged files, `--ci` on the last commit, and `GGA_ADVISORY=1` reports without blocking. Do not run `gga install`: it would replace the kit's pre-commit. GGA is advice; `guard` and `verify` remain the hard gate.

## Manual install (fallback)

1. Copy `AGENTS.md` (merge it with the existing one, do not overwrite).
2. Copy `skills/`, `commands/`, `agents/`, `verify/`, `guard/`, `evals/`, `scripts/`, `docs/`.
3. Run `bash scripts/scan_env.sh` and complete `docs/agent-quality/ENVIRONMENT.md` with the real commands.
4. Fill `verify/config.env` with the boot, health and test commands.
5. Run `bash guard/guard.sh`. Fix or disable each check explicitly, never by deleting it silently.
6. Run `bash verify/run.sh` on a clean checkout. It must pass before you trust any agent.
7. Install the hooks: `bash scripts/install-hooks.sh .` for the pre-commit guard; add `--with-verify` for the pre-push runtime gate and edit `.dev-agent/verify.env`. For OpenCode or Claude, run `bash scripts/install-agent-adapters.sh . --agents opencode,claude`; the generated directories are gitignored.
8. Copy one eval case, run `python3 evals/harness.py --case-dir evals/cases/dev-verify/01-fix-failing-test --rubric evals/rubric.dev-verify.json --dry-run`, then a real run with the approved model.

## What it does not do

- It does not touch production, migrations, secrets or customer data. Those are one-way doors and keep a human signature.
- It does not install third-party skill catalogs. Five core skills, each with a job.
- It does not call a personal model endpoint. Set the model in your copy of the rubric or pass `--model` with the company-approved provider.
- It does not run the agent in your working tree. Each eval runs in a disposable worktree or copy, and the judge receives the artifacts that run produced plus, when the case declares it in `context.json`, the source under review.
- It does not auto-merge. Autonomy is earned per repo after 30 green changes and zero reverts.
