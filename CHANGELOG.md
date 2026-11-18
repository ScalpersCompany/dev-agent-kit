# Changelog

## [1.1.0] - 2026-11-18

### Added

- First real eval case: `odoo-11-code-review` over a seeded Odoo 11 module, with a weighted rubric and a `context.json` that gives the judge the source tree under review.
- FactorLibre MR preflight eval case: a git fixture with `master`/`feature`, a static `repo.diff`, the skill copy and a weighted rubric. The preflight returns 6 ERROR, 15 WARN and 4 INFO; the credential scan finds two readable fields.
- The five path-aware skills are now 1.1.0: when the repo has no `verify/`, `guard/`,
  `docs/` or `evidence/`, they use `DEV_AGENT_KIT` or `~/dev-agent-kit` by absolute path.
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
