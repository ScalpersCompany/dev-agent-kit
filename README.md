# Dev agent kit

A repo-local kit to make OpenCode trustworthy on the development codebase. It implements the method from Lauren Tan's talks: executable verification, skills built from observed failures, agent evals, and deterministic guardrails before prose.

Copy the folders into the repository root of a development repo. Nothing here depends on a personal machine, a home NAS, or a personal model subscription.

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
.opencode/skills/             six skills (dev-verify, odoo-safe-change, repro-first, review-diff, correct, query-readonly)
.opencode/commands/           /verify /guard /repro /correct /eval
.opencode/agent/judge.md      read-only eval judge, strict JSON contract
verify/run.sh                 boot, smoke, tests, evidence/
guard/guard.sh                ruff, black, mypy, eslint, tsc, gitleaks, Odoo AST checks
guard/odoo_lint.py            deterministic Odoo checks (sudo, cr.commit, raw SQL, print)
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
scripts/scan_env.sh           discovery: stack, tests, CI, DB env var names
docs/FEATURE_MAP.template.md  map of the app from the user's point of view
docs/AGENT-QUALITY.md         the method in one page
docs/DEV-BASE.md              what the kit covers in the development base
docs/EVAL-BASELINE.md         first eval score and what it observed
docs/SKILL-EVAL-COVERAGE.md   all global skills, priority and eval status
docs/OPERATIONS.md            how a change moves through the kit
docs/use-cases/               how to replicate it in a company repo
CHANGELOG.md                  what changed in each version
```

## Install in a development repo

1. Copy `AGENTS.md` (merge it with the existing one, do not overwrite).
2. Copy `.opencode/`, `verify/`, `guard/`, `evals/`, `scripts/`, `docs/`.
3. Run `bash scripts/scan_env.sh` and complete `docs/agent-quality/ENVIRONMENT.md` with the real commands.
4. Fill `verify/config.env` with the boot, health and test commands.
5. Run `bash guard/guard.sh`. Fix or disable each check explicitly, never by deleting it silently.
6. Run `bash verify/run.sh` on a clean checkout. It must pass before you trust any agent.
7. Copy one eval case, run `python3 evals/harness.py --case-dir evals/cases/dev-verify/01-clean --rubric evals/rubric.example.json --dry-run`, then a real run with the approved model.

## What it does not do

- It does not touch production, migrations, secrets, or customer data. Those are one-way doors and keep a human signature.
- It does not install third-party skill catalogs. Six skills, each with a job.
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
