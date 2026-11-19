# Dev agent kit

A repo-local kit to make OpenCode trustworthy on the development codebase. It implements the method from Lauren Tan's talks: executable verification, skills built from observed failures, agent evals, and deterministic guardrails before prose.

Start here: `docs/INSTALACION-Y-FUNCIONAMIENTO.md` (Spanish) — installation, daily flow, guard, verify, evals, GGA, profiles, security and the current-versus-planned status.

Copy the folders into the repository root of a development repo, or run the bootstrap installer (`scripts/bootstrap.sh`) to copy them and install the hooks. Nothing here depends on a personal machine, a home NAS, or a personal model subscription.

## Install (automated, current)

From this kit:

```bash
bash scripts/bootstrap.sh /path/to/development-repo
bash scripts/bootstrap.sh /path/to/development-repo --with-verify
bash scripts/bootstrap.sh /path/to/development-repo --with-gga
```

The bootstrap copies `AGENTS.md`, `.opencode/`, `verify/`, `guard/`, `evals/`, `scripts/` and `docs/`; backs up anything it replaces as `.bak-<timestamp>`; creates `verify/config.env` from the example; and installs the pre-commit hook. `--with-verify` adds the pre-push gate and `.dev-agent/verify.env`; `--with-gga` adds the optional GGA files. It does not touch production, git history or the profile registry.

The full profile installer (`dev-agent init --profile ... --all`) is designed but not wired yet; `scripts/bootstrap.sh` is the current automated path.

## Profiles

All profiles can live in **one private repository**, `dev-agent-profiles`, with one
directory per profile (`profiles/odoo11`, `profiles/php`). The core keeps the contract, the
registry and the installer; the profile keeps its `profile.json`, `profile.env`, `guard/`,
`verify/`, `skills/`, `evals/` and `AGENTS.fragment.md`.

The git hooks are **not** different per profile: the same core `pre-commit` and `pre-push`
read the active profile and run its checks. What differs is the content the hook executes:
guard checks, verify config, skills, eval cases and the AGENTS fragment. Today Odoo still
lives at the core root and `profiles/php` is a skeleton; the migration is in
`docs/PERFILES-EN-REPOS.md`.

## Status

| Area | State |
|---|---|
| `guard`, `verify`, evals, pre-commit/pre-push | implemented and covered by tests |
| GGA advisory review | added; installation tested; no real review run |
| one profile repository and `dev-agent init` | designed; not implemented; Odoo still at the core root |
| PHP profile | skeleton; PHPStan/PHPCS/PHPUnit not wired |
| `comment_lint` for PHP | pending; the generic checker does not scan `.php` yet |
| `gentle-ai`, `rsc-harness`, `rsc-brain`, `engram` | documented boundaries; not wired into the daily flow |
| Scalpers CI | not touched; local gates are the current hard check |

## Agents and shared rules

The gates are plain bash/Python 3.8+ and git hooks, so Hermes, OpenCode, Claude Code, Codex
and pi run the same commands. Skills are `SKILL.md` files installed under each agent's
skills directory; the shared rule is `~/.agents/AGENTS.md`, linked from `SOUL.md`,
OpenCode's `AGENTS.md` and Claude's `CLAUDE.md`. `gentle-ai sync` distributes skills and MCP;
it does not replace `guard` or `verify`.

## GGA (optional)

`scripts/install-gga.sh <repo>` copies `.gga` and `.gga-rules.md` with backups;
`scripts/review-gga.sh <repo>` runs `gga` on staged files, `--ci` on the last commit, and
`GGA_ADVISORY=1` reports without blocking. Do not run `gga install`: it would replace the
kit's pre-commit. GGA is advice; `guard` and `verify` remain the hard gate.

## Manual install (fallback)

1. Copy `AGENTS.md` (merge it with the existing one, do not overwrite).
2. Copy `.opencode/`, `verify/`, `guard/`, `evals/`, `scripts/`, `docs/`.
3. Run `bash scripts/scan_env.sh` and complete `docs/agent-quality/ENVIRONMENT.md` with the real commands.
4. Fill `verify/config.env` with the boot, health and test commands.
5. Run `bash guard/guard.sh`. Fix or disable each check explicitly, never by deleting it silently.
6. Run `bash verify/run.sh` on a clean checkout. It must pass before you trust any agent.
7. Install the hooks: `bash scripts/install-hooks.sh .` for the pre-commit guard; add `--with-verify` for the pre-push runtime gate and edit `.dev-agent/verify.env`.
8. Copy one eval case, run `python3 evals/harness.py --case-dir evals/cases/dev-verify/01-fix-failing-test --rubric evals/rubric.dev-verify.json --dry-run`, then a real run with the approved model.

## Scope

This kit is for the development base, not production. Production receives only changes that pass `verify/run.sh`, `guard/guard.sh`, the eval where it applies, and the evidence gate. The kit is the filter; it is not deployed to production.

## First real eval

`evals/cases/odoo-11-code-review/01-seeded` is a seeded Odoo 11 module with real defects: no ACL, ungrouped credential fields, `cr.commit()`, a raw SQL `DELETE`, an `@api.one` compute, a non-stored field used in `order` and a filter, a v12 `invisible=` expression, a `missing_field` in `attrs`, a `workflow` button, a core `position="replace"`, `assets` in the manifest, data without `noupdate`, and a commented test import. The case copies the skill into `.opencode/skills/` and `context.json` gives the judge the module and the skill, so it can check both the findings and the skill's report contract.

```bash
python3 evals/harness.py \
  --case-dir evals/cases/odoo-11-code-review/01-seeded \
  --rubric evals/rubric.odoo-11-code-review.json \
  --agent build --model <approved> --judge-model <approved-different> --k 3
```

The rubric ships with `REPLACE_WITH_APPROVED_MODEL` placeholders; set them in a copy or pass both flags. The judge must be a different model from the one under test.

Baseline: `docs/EVAL-BASELINE.md` (Odoo 11 code review 9.81/10, FactorLibre preflight 9.52/10, dev-verify 10.0/10, repro-first 10.0/10, review-diff 9.64/10; K=3, threshold 8.5).

## What is inside

```
AGENTS.md                     repo rules the agent reads first
.opencode/skills/             seven skills (dev-verify, odoo-safe-change, repro-first, review-diff, correct, query-readonly, factorlibre-mr-preflight)
.opencode/commands/           /verify /guard /repro /correct /eval
.opencode/agent/judge.md      read-only eval judge, strict JSON contract
verify/run.sh                 boot, smoke, tests, evidence/
guard/guard.sh                ruff, black, mypy, eslint, tsc, gitleaks, Odoo AST checks
guard/odoo_lint.py            deterministic Odoo checks (sudo, cr.commit, raw SQL, print)
guard/comment_lint.py        blocks new comments in staged code (Python, XML, JS/TS, shell, SQL, YAML)
evals/harness.py              k runs per case in a disposable worktree or copy, artifacts, judge of another model, score.json
evals/rubric.example.json     rubric shape
evals/rubric.odoo-11-code-review.json  weighted rubric for the first real eval
evals/rubric.factorlibre-mr-preflight.json  weighted rubric for the MR preflight eval
evals/rubric.dev-verify.json  weighted rubric for the verification eval
evals/rubric.repro-first.json  weighted rubric for the reproduction eval
evals/rubric.review-diff.json  weighted rubric for the diff review eval
evals/cases/odoo-11-code-review/01-seeded/  seeded Odoo 11 module and its context.json
evals/cases/factorlibre-mr-preflight/01-seeded/  seeded MR fixture, repo.diff and skill copy
evals/cases/dev-verify/01-fix-failing-test/  failing-test fixture for dev-verify
evals/cases/repro-first/01-discount-bug/  failing-test fixture for repro-first
evals/cases/review-diff/01-unsafe-handler/  unsafe diff fixture for review-diff
evals/loop.sh                 hill climb until the score passes
profiles/                     core template and the PHP skeleton; real profiles move to dev-agent-profiles
gga/                          optional AI review: .gga example and review rules
scripts/install-gga.sh        installs .gga and .gga-rules.md with backups
scripts/review-gga.sh         runs gga on staged files, optional or blocking
hooks/pre-commit              local pre-commit: guard --staged
hooks/pre-push                local pre-push: verify/run.sh
scripts/install-hooks.sh      installs the hooks and backs up the existing ones
scripts/bootstrap.sh          copies the kit into a repo, creates verify config and installs hooks
tests/test_odoo_lint.py       unit tests for the staged/full linter modes
.github/workflows/quality.yml unit tests, syntax and eval dry-run in CI
scripts/scan_env.sh           discovery: stack, tests, CI, DB env var names
docs/FEATURE_MAP.template.md  map of the app from the user's point of view
docs/AGENT-QUALITY.md         the method in one page
docs/DEV-BASE.md              what the kit covers in the development base
docs/ARQUITECTURA-ENTORNOS.md core plus profiles, and how rsc-harness, rsc-brain, engram and gentle-ai fit
docs/PERFILES-EN-REPOS.md how profiles live in private repos, the registry and the install/use flow
docs/EVAL-BASELINE.md         first eval score and what it observed
docs/SKILL-EVAL-COVERAGE.md   all global skills, priority and eval status
docs/OPERATIONS.md            how a change moves through the kit
docs/use-cases/               how to replicate it in a company repo
CHANGELOG.md                  what changed in each version
```

## Post-install checklist

1. Run `bash scripts/bootstrap.sh <repo>` (add `--with-verify` and `--with-gga` as needed).
2. Complete `docs/agent-quality/ENVIRONMENT.md` with the real commands.
3. Fill `verify/config.env` with the boot, health and test commands.
4. Run `bash guard/guard.sh`. Fix or disable each check explicitly, never by deleting it silently.
5. Run `bash verify/run.sh` on a clean checkout. It must pass before you trust any agent.
6. The hooks are installed by the bootstrap; check with `git config --get core.hooksPath` and `.git/hooks/pre-commit`.
7. Copy one eval case, run `python3 evals/harness.py --case-dir evals/cases/dev-verify/01-fix-failing-test --rubric evals/rubric.dev-verify.json --dry-run`, then a real run with the approved model.

## What it does not do

- It does not touch production, migrations, secrets, or customer data. Those are one-way doors and keep a human signature.
- It does not install third-party skill catalogs. Seven skills, each with a job.
- It does not call a personal model endpoint. Set the model in your copy of `evals/rubric.example.json` or pass `--model` with the company-approved provider.
- It does not run the agent in your working tree. Each eval runs in a disposable worktree or copy, and the judge receives the artifacts that run produced plus, when the case declares it in `context.json`, the source under review.
- It does not auto-merge. Autonomy is earned per repo after 30 green changes and zero reverts.

## First week

- Day 1: environment scan and `verify/run.sh` green on a clean checkout.
- Day 2: feature map for the area you own.
- Day 3: reproduce one real ticket with `repro-first`.
- Day 4: run `/correct` on a week of review comments and implement the top two as lint rules.
- Day 5: first eval of `dev-verify` with three cases.
- Day 6-7: guard green in pre-commit and CI, and a sample review of what the agent produced.
