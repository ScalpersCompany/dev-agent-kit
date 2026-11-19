# Changelog

## [1.6.0] - 2026-11-18

### Added

- `gga/project.gga.example` and `gga/REVIEW-RULES.md`: optional GGA AI review, with the no-comments and review-checklist rules.
- `scripts/install-gga.sh`: copies `.gga` and `.gga-rules.md` with backups; it does not run `gga install`, so the kit pre-commit is preserved.
- `scripts/review-gga.sh`: runs GGA on staged files; `GGA_ADVISORY=1` reports without blocking; `--ci` reviews the last commit.
- `docs/ARQUITECTURA-ENTORNOS.md` and `docs/OPERATIONS.md` explain that GGA is advisory, provider-dependent and not a hard gate.

## [1.5.0] - 2026-11-18

### Added

- `docs/ARQUITECTURA-ENTORNOS.md`: core plus environment profiles, with the boundaries for rsc-harness, rsc-brain, engram and gentle-ai.
- `profiles/_template/` and `profiles/php/`: the profile contract and the first non-Odoo adapter, with PHPStan/PHPCS/PHPUnit and a verify example.
- The README and operations guide point to the profile design and state that the Odoo files move to `profiles/odoo11` in phase 1.

### Changed

- The kit is no longer described as Odoo-only; the core is language-agnostic and the Odoo checks become a profile.

## [1.4.1] - 2026-11-18

### Changed

- `factorlibre-mr-preflight` 1.3.1 documents that Hermes, OpenCode and Claude Code load the same `SKILL.md`; the preflight and comment checker are plain Python 3.8+ and the comment gate is a git hook.
- `docs/OPERATIONS.md` records the three-agent compatibility and the shared `~/.agents/AGENTS.md` norm.

## [1.4.0] - 2026-11-18

### Added

- `factorlibre-mr-preflight` 1.3.1 in `.opencode/skills/`: the review logic learned from the latest connector MR, with the 1.3.0 preflight checks, the 1.3.1 compatibility note and reference patterns.
- The skill is also installed globally in Hermes, OpenCode, Claude, Codex, pi and `~/.agents`.

### Changed

- The kit now ships seven skills, not six.

## [1.3.0] - 2026-11-18

### Added

- `guard/comment_lint.py`: blocks new explanatory comments in staged Python, XML, JavaScript/TypeScript, shell, SQL and YAML; tool directives remain allowed.
- `tests/test_comment_lint.py`: five unit tests for Python comments, directives, docstrings, XML and JavaScript.
- `guard/guard.sh --staged` runs the comment check in pre-commit; full runs skip it with a reason so legacy files do not block unrelated work.
- Global norm 4.1 in the shared `AGENTS.md`: no explanatory comments in new or modified code; docstrings and Odoo `help` remain documentation.

## [1.2.0] - 2026-11-18

### Added

- Local pre-commit hook that runs `guard/guard.sh --staged` on the files in the commit, with the report in `.git/guard-report.json`.
- Local pre-push hook that runs `verify/run.sh` and fails closed until `.dev-agent/verify.env` has a real `TEST_CMD`.
- `scripts/install-hooks.sh`: installs either hook, backs up an existing one as `.bak-<timestamp>`, and adds `.dev-agent/` to the local exclude.
- `tests/test_odoo_lint.py`: full scan, staged-file mode and interpolation checks; three unit tests.
- `.github/workflows/quality.yml`: unit tests, shell and Python syntax checks and an eval dry-run on push and pull request.

### Changed

- `guard/guard.sh` now accepts `GUARD_ROOT` and `GUARD_REPORT` and, with `--staged`, scans only staged Python/JS files; ruff, black, mypy, eslint and tsc receive that file list.
- `guard/odoo_lint.py` accepts `--files` and `--allowlist`, so a target repository can use the kit's allowlist without copying it.
- `verify/run.sh` accepts `VERIFY_ROOT`, `VERIFY_CONFIG` and `VERIFY_EVIDENCE`, so a pre-push hook can run the kit's runner against another repository.

### Fixed

- A pre-commit guard no longer scans the whole repository and fails on pre-existing findings; the commit sees only what it changes.
- `docs/OPERATIONS.md` no longer tells the reader to hand-wire `guard/guard.sh`; it points at the installer and states the `--no-verify` and CI limits.

## [1.1.0] - 2026-11-18

### Added

- First real eval case: `odoo-11-code-review` over a seeded Odoo 11 module, with a weighted rubric and a `context.json` that gives the judge the source tree under review.
- FactorLibre MR preflight eval case: a git fixture with `master`/`feature`, a static `repo.diff`, the skill copy and a weighted rubric. The preflight returns 6 ERROR, 15 WARN and 4 INFO; the credential scan finds two readable fields.
- The five path-aware skills are now 1.1.0: when the repo has no `verify/`, `guard/`,
  `docs/` or `evidence/`, they use `DEV_AGENT_KIT` or `~/dev-agent-kit` by absolute path.
- The eval diff excludes the kit support paths (`.opencode`, `AGENTS.md`, `verify/`,
  `guard/`, `scripts/`, `docs/`), so a pre-existing support file is not reported as an
  agent change; the case files remain in the artifacts/context.
- `review-diff` real eval: 9.64/10 over K=3 (threshold 8.5), case
  `evals/cases/review-diff/01-unsafe-handler`; run 3 lost format/line-number points, so the
  skill is 1.1.0 with the new-file line and prefix clarification.
- `repro-first` real eval: 10.0/10 over K=3 (threshold 8.5), case
  `evals/cases/repro-first/01-discount-bug`; the support-path diff fix is above.
- `dev-verify` real eval: 10.0/10 over K=3 (threshold 8.5), case
  `evals/cases/dev-verify/01-fix-failing-test`.
- Global skills on dev-nicolas: the six kit skills are installed in both OpenCode and
  Hermes; `rsc-harness-brain`, `gitlab`, `jira-cloud`, `sga-e2e-testing` and
  `odoo-11-reservas-marketplace` were added to OpenCode. The eval coverage table in
  `docs/EVAL-BASELINE.md` says which ones have a real run and which are only installed.
- `docs/agent-quality/ENVIRONMENT.md` now has the real disposable-database test for `scalpers_partner_vat_unique` (four post-install tests, verified) and the `--entrypoint odoo` workaround for the doodba addons link.
- FactorLibre eval baseline: 9.52/10 over K=3 (threshold 8.5), after fixing the scanner
  and preflight script defects it exposed.
- `docs/DEV-BASE.md`: what the kit covers in the development base and where the production gate sits.
- `docs/EVAL-BASELINE.md`: first real eval baseline, 9.81/10 over K=3 (threshold 8.5).

### Changed

- Renamed the kit to `dev-agent-kit` and the verify skill to `dev-verify`.
- The Scalpers plan is now a use case under `docs/use-cases/`, not the main target.
- The eval harness runs `opencode` with the sandbox as its working directory instead of `--dir`, so it works with CLI versions that do not expose that flag.
- The eval harness uses a private OpenCode server (`--standalone`) per run, so the background service cannot reuse another project.
- Token totals are read from `input`/`output`/`reasoning`/`cache` when the event has no `total`, and the judge's tokens and cost are included in the run total.
- The eval harness gives the judge the full source under review: `context.json` can list files or directories, and the per-file and total artifact caps were raised for a whole skill plus a module.
- `odoo_lint` skips `evals/` so the seeded eval fixtures do not fail the guard on the kit itself; run it directly with `--root` on a case to lint that case.
- `loop.sh` passes `MODEL` and `JUDGE_MODEL` to the harness, stops if the harness produced no `score.json`, and runs the skill edit with `--standalone`.
- The eval harness accepts `.diff`, `.patch` and `.js` artifacts, so a FactorLibre MR case can give the judge the patch and the POS/JS files.
- `factorlibre-mr-preflight` is now 1.1.0: `scan_secret_fields.py` no longer swallows the field after a one-line definition, and `preflight_mr.py` no longer treats `model="..."` as an xmlid.
- The `odoo-11-code-review` skill is now 1.2.1: the review report contract fixes
  absent-file citations, per-field `help=` enumeration, `models.Constraint` and
  the `@api.one` N+1 case; the reviewer CLI and model names are placeholders and
  the canonical id stays in the internal register.
- `odoo_lint` now catches raw SQL writes built with `%` or f-strings, not only literal strings.

## [1.0.1] - 2026-11-18

### Fixed

- `guard-report.json` is valid JSON when a check detail contains quotes or backslashes.
- `eslint` and `tsc` are skipped when the tool is not installed instead of attempting a download through `npx`.
- `verify/run.sh` stops the `BOOT_CMD` process and its children when the script exits, so a verification run leaves no server behind.
- `verify/run.sh` no longer records the literal string `HEAD` as the commit outside a git repository.
- The eval harness runs each case in a disposable worktree or copy, never in the working tree, and cleans it up afterwards.
- The eval judge receives the artifacts produced by the run, not only the final text.
- The harness computes the weighted score from one score per rubric criterion; the judge no longer does the arithmetic.
- `evals/loop.sh` refuses to edit a skill with the default model unless `MODEL` is set to an approved provider/model.
- The Scalpers plan no longer claims that `verify/run.sh` ran a real test; it documents the `TEST_CMD=true` smoke check.
- The Lauren Tan plan separates the 1,000 and 2,000 PR claims by source and date.

### Added

- A CHANGELOG.md in the kit.

## [1.0.0] - 2026-11-17

### Added

- Initial kit: AGENTS.md, six skills, five commands, the judge agent, verify, guard, Odoo lint, eval harness, eval loop and environment scanner.
