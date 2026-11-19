# How the kit runs in the development base

The kit is a gate, not a deploy tool. It makes an agent's change observable before a
human sends it to the company repository.

## Repository map

| Path | Job |
|---|---|
| `AGENTS.md` | Rules the agent reads before touching code. |
| `.opencode/skills/` | Seven skills: `dev-verify`, `odoo-safe-change`, `repro-first`, `review-diff`, `correct`, `query-readonly`, `factorlibre-mr-preflight`. |
| `.opencode/commands/` | `/verify`, `/guard`, `/repro`, `/correct`, `/eval`. |
| `verify/run.sh` | Boots the app, checks health, runs smoke and tests, writes `evidence/<run-id>/`. |
| `guard/guard.sh` | Deterministic checks; writes `guard-report.json` (one JSON object per line). |
| `guard/odoo_lint.py` | Odoo 11 AST checks: `sudo()`, `cr.commit()`, raw SQL writes, `print()`. |
| `guard/comment_lint.py` | Blocks new explanatory comments in staged code; tool directives are allowed. |
| `hooks/pre-commit` | Local hook: `guard --staged` on the commit's files only. |
| `hooks/pre-push` | Local hook: `verify/run.sh`, fail-closed without `.dev-agent/verify.env`. |
| `scripts/install-hooks.sh` | Installs either hook, backs up an existing one, excludes `.dev-agent/` locally. |
| `tests/test_odoo_lint.py` | Unit tests for full and staged linter modes. |
| `.github/workflows/quality.yml` | CI: unit tests, shell/Python syntax, eval dry-run. |
| `evals/harness.py` | Runs a case K times in a disposable copy or worktree, gives the judge the artifacts, writes `score.json`. |
| `evals/cases/` | Task, source tree and `context.json` for each case. |
| `evals/rubric*.json` | Weighted criteria and threshold. |
| `scripts/scan_env.sh` | Discovers the stack, test commands and database variable names. |
| `docs/` | Method, scope, baseline and use cases. |

## One change, end to end

1. **Branch.** Work on `feat/...`, `fix/...` or `hotfix/...` in the development repo. Never on the default branch.
2. **Reproduce.** For a bug, use `/repro` and keep the failing command and its output. A fix without a reproduction is a guess.
3. **Implement.** Follow `AGENTS.md` and the relevant skill. One change, one commit; tests and docs in the same commit.
4. **Verify.** Fill `verify/config.env` from `verify/config.env.example`, then run `bash verify/run.sh`. It must exit 0 and leave `evidence/<run-id>/summary.json` with `"status": "pass"`. If it exits 2, the configuration is incomplete, not green.
5. **Guard.** Run `bash guard/guard.sh`. A check that cannot run is `skipped` with a reason; a failing check is red. Do not delete a check to make the gate green.
6. **Evaluate.** If the change touches a skill, a prompt, an agent workflow or a review rule, run the eval with K=3 (see below). A code change that no skill touches does not need an eval.
7. **Review.** A human reads the diff against the ticket. The agent's report is not the review.
8. **Deliver.** The company repository receives the change only when verify, guard and the applicable eval are green and the evidence is attached. Production keeps its own pipeline and a human signature.

## Install in a development repo

1. Clone this private repository next to the working repos, for example `~/dev-agent-kit`.
2. Copy `AGENTS.md` into the repo root, merging it with the existing rules instead of overwriting them.
3. Copy `.opencode/`, `verify/`, `guard/`, `evals/`, `scripts/` and `docs/` into the repo root.
4. Run `bash scripts/scan_env.sh` and complete `docs/agent-quality/ENVIRONMENT.md` with the real commands and paths.
5. Copy `verify/config.env.example` to `verify/config.env` and fill `BOOT_CMD`, `HEALTH_URL`, `SMOKE_CMD` and `TEST_CMD`.
6. Run `bash verify/run.sh` on a clean checkout. It must pass before the agent is allowed to change anything.
7. Run `bash guard/guard.sh`. Fix or explicitly skip each missing tool.
8. Install the local hooks with `bash scripts/install-hooks.sh .`; add `--with-verify` for the pre-push runtime gate and edit `.dev-agent/verify.env`. Existing hooks are backed up, never deleted.
9. Create the first eval case with a real defect and run it in dry-run, then with the approved models.

`verify/config.env`, `evidence/`, `evals/runs/`, `guard-report.json`, `__pycache__/` and
tool caches are git-ignored. Never commit a real test database, a token or a customer
file.

## Environment profiles

The kit is being split into a language-agnostic core and thin profiles. `profiles/php`
is the first non-Odoo adapter; `profiles/_template` is the starting point for another
language. The full design, the layer boundaries for rsc-harness, rsc-brain, engram and
gentle-ai, and the migration phases are in `docs/ARQUITECTURA-ENTORNOS.md`.

The current Odoo files remain at the root until phase 1 moves them to `profiles/odoo11`;
the PHP directory is the target shape, not a second runtime.

## GGA optional review

`gga` is an AI reviewer, not a gate. It needs a provider and a rules file; it is slower
and non-deterministic than `guard`.

- `bash scripts/install-gga.sh <repo>` copies `.gga` and `.gga-rules.md`, with backups.
- `bash scripts/review-gga.sh <repo>` reviews staged files; `GGA_ADVISORY=1` reports
  without blocking; `--ci` reviews the last commit.
- Do not run `gga install`: it would replace the kit's pre-commit hook.
- `PROVIDER` can be `claude`, `opencode`, `codex`, `ollama:<model>` or another approved
  CLI; Hermes invokes the script as a command.
- If there is no provider or no `.gga`, the script reports it; it is not green.
- The GGA rules mirror the review checklist; `guard` and `verify` remain the hard gate.

## Global skills in dev-nicolas

The kit's seven skills are installed globally in both agents on this host:

- `~/.config/opencode/skills/software-development/{dev-verify,odoo-safe-change,repro-first,review-diff,correct,query-readonly,factorlibre-mr-preflight}`
- `~/.hermes/skills/software-development/{dev-verify,odoo-safe-change,repro-first,review-diff,correct,query-readonly,factorlibre-mr-preflight}`

Both agents also have `odoo-11-code-review`, `odoo-11-standards`,
`odoo-11-orm-performance`, `odoo-11-credential-security`, `odoo-development` and
`gentle-ai-toolchain`. OpenCode additionally has `rsc-harness-brain`, `gitlab`, `jira-cloud`,
`sga-e2e-testing` and `odoo-11-reservas-marketplace` in its global skills directory.

Hermes, OpenCode and Claude Code load the same `SKILL.md` from their own skills
directory; `preflight_mr.py` and `comment_lint.py` are plain Python 3.8+ and the
comment gate is a git hook, so none of the three depends on an agent-specific API.
The shared norm lives in `~/.agents/AGENTS.md`, which all three configurations point to.

The skills are procedures; they do not make the gates mandatory. `verify/`, `guard/` and
`evals/` stay repo-local because their commands and database are repo-specific. When a
skill runs from a repo without the kit, it falls back to `DEV_AGENT_KIT` or
`~/dev-agent-kit`; set `DEV_AGENT_KIT` if the clone lives elsewhere. The shared
`~/.agents/AGENTS.md` does not mention the kit yet; add the gate rule there when the team
wants every agent to run it without being asked.

## Invocation model

The skills are **model-selected**, not hooks. Hermes and OpenCode list them and the agent
loads one when the task matches its description; no skill runs on every edit by itself.
`dev-verify`, `repro-first`, `review-diff`, `correct`, `odoo-safe-change` and
`query-readonly` are procedures the agent follows after it loads them.

The gates are commands:

- `verify/run.sh` runs when a person or the agent calls it; it is too slow for every edit.
  Put it in CI or a pre-push hook when it must block a delivery.
- `guard/guard.sh` is fast enough for a pre-commit hook. That hook is the deterministic
  guarantee; an `AGENTS.md` sentence is only an instruction the model may follow.
- `evals/harness.py` runs when a skill, prompt or review rule changes, K=3, not on every
  code change.

`AGENTS.md` can require the commands before a report, but only the hook or the CI job makes
the requirement impossible to skip. The kit is a toolbox plus a documented flow; it is not
a background service.

## Recommendation

- **Guard: mandatory in pre-commit.** It is fast, deterministic and local; a red check
  blocks the commit without spending a model call.
- **Verify: mandatory in CI or pre-push, not on every edit.** It boots the app and tests a
  disposable database; it is the delivery gate, not an editor loop.
- **Eval: mandatory only when a skill, prompt or review rule changes.** K=3 with a
  different judge; it is too expensive and too slow to run on every code change.
- **Do not make every skill a hard trigger.** The model selects skills by description; the
  hard guarantees belong in the hook and the pipeline. The skill tells the agent how to do
  the work; the hook decides whether the work may leave the machine.

## Make it mandatory

The recommendation is mechanical, not prose:

1. **Pre-commit (guard).** `bash scripts/install-hooks.sh <repo>` copies the local
   `pre-commit` hook. It runs `guard/guard.sh --staged`, so it checks only the files in the
   commit and does not fail on pre-existing findings. The report lives in
   `.git/guard-report.json`, outside the worktree. Existing hooks are backed up as
   `<name>.bak-<timestamp>`.
2. **Pre-push or CI (verify).** `bash scripts/install-hooks.sh <repo> --with-verify` adds
   the `pre-push` hook. It runs `verify/run.sh` against the repository and fails closed
   until `.dev-agent/verify.env` has a real `TEST_CMD`; evidence goes to
   `.git/dev-agent-evidence`. A missing config is not green.
3. **Kit CI.** `.github/workflows/quality.yml` runs the unit tests for the linter, shell and
   Python syntax checks, and an eval dry-run on every push and pull request. The real K=3
   eval stays manual because it spends model budget; it is required only when a skill,
   rubric, prompt or review rule changes.
4. **Limits.** A local hook is not a sandbox: `git commit --no-verify` and
   `git push --no-verify` bypass it. The CI job is the hard gate. A hook installed in one
   repository does not cover its subrepositories; install it in each repository that takes
   commits.
5. **Where it is installed.** On this host the pre-commit hook is installed in
   `odoo/custom/src/private/scalpers-v11`; the pre-push hook uses the disposable Odoo test
   in `.dev-agent/verify.env`. The kit itself keeps its own CI and does not run the Odoo
   pre-push hook.

## Odoo 11 specifics

- Test on a **disposable database**, never on the live `scalpers` database:
  `docker compose -f devel.yaml run --rm odoo odoo -d test_<ticket> -u <module> --test-enable --stop-after-init`.
- After adding a model or a field to an installed module, update it with `-u`; copying files alone does not create columns.
- Read the whole log: in v11 a view error can leave the view half-loaded without killing the process.
- `odoo_lint` runs on the repo root and skips `evals/`, so the seeded fixtures do not fail the guard. Run it directly with `--root` on a case when you want to lint that case.
- `sudo()` needs a justification and an allowlist entry; `cr.commit()` in business code is a blocker; raw SQL writes go through the ORM or a parameterized query with a test.

## Evals

The harness copies the case into a disposable directory, copies the support files
(`.opencode/`, `AGENTS.md`, `verify/`, `guard/`, `scripts/`, `docs/`), and runs
`opencode` with a private server. The case's `context.json` lists the source tree the
judge must read, so a review eval can be judged against the code and the skill.

```bash
python3 evals/harness.py \
  --case-dir evals/cases/odoo-11-code-review/01-seeded \
  --rubric evals/rubric.odoo-11-code-review.json \
  --agent build \
  --model <approved> \
  --judge-model <approved-different> \
  --k 3
```

- The executor and the judge are different approved models. Never put their names in a
  report, a ticket or a commit message; `docs/EVAL-BASELINE.md` records the result without
  naming them.
- The judge scores each criterion 0-10 from the output and the artifacts; the harness
  computes the weighted mean. The threshold is 8.5.
- A dry run (`--dry-run`) proves the plumbing, not the skill. The real score is the one
  with a model and a judge.
- The first baseline is in `docs/EVAL-BASELINE.md`: 9.81/10 over K=3, with one run at
  9.44 and two at 10.0.

## Cadence

- **Every change:** verify and guard.
- **Every skill, prompt or review-rule change:** the eval with K=3, and update the
  baseline only after the run.
- **Weekly:** review the skipped guard checks and the eval scores; a skip that repeats
  is a missing tool or a missing rule.
- **Monthly:** remove a rule that no longer catches anything; keep the seven skills small.

## When something fails

- Two identical failures mean stop and change the approach, not a third retry.
- A red verify or guard is not delivered. An amber result is prepared but unverified;
  say so.
- If the tool or the database is unavailable, record the blocker and the exact command
  that failed. Do not invent a pass.
- Production is never touched from this host. The kit produces evidence; the company
  pipeline and a human make the delivery.
