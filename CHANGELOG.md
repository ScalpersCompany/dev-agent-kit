# Changelog

## [3.7.0] - 2026-11-26

### Added

- `scripts/render-roles.py`: renders one agent per role from the team profile's `roles.json` for `claude` (`.claude/agents/`) and `opencode` v2 (`.opencode/agents/`), with the write surface, the reads, the exit commands and the forbidden list taken from the contract; `--check` fails when a rendered file is behind the contract and `--model-map` overrides the models.
- `dev-agent roles <claude|opencode>`: wrapper for the renderer.
- `docs/EQUIPO-MULTI-AGENTE.md`: one agent per role, generated from the neutral contract, with the read-only tools per agent and the commands that verify the result.
- `tests/test_render_roles.py`: five tests for both frontmatter shapes, the model map, `--check` and a contract without roles.

### Changed

- `bin/dev-agent` usage lists `roles`.
- README describes the renderer and points at the new document.

## [3.6.0] - 2026-11-25

### Added

- `e2e/`: Playwright baseline with `playwright.config.ts`, `package.json`, a real health spec and flow-spec guidance.
- `scripts/install-e2e.sh`: copies the harness with a backup; `--install` installs npm dependencies and never runs implicitly.
- `verify/run.sh`: `E2E_CMD` runs after smoke and tests, sets `E2E_BASE_URL`, `PLAYWRIGHT_OUTPUT_DIR` and `PLAYWRIGHT_REPORT_DIR`, and records `e2e` in `summary.json`.
- `tests/test_verify_e2e.py` and `tests/test_install_e2e.py`.

### Changed

- `verify/config.env.example` and the profile examples include `E2E_CMD`, `E2E_BASE_URL` and `E2E_HEALTH_PATH`; the evidence keeps the HTML report, JUnit/JSON, traces and screenshots.
- `scripts/bootstrap.sh` copies `e2e/`; README, operations, install, use and training docs describe the E2E lane.
- GGA core and the Odoo, PHP and hexagonal rules require complete E2E evidence for UI and user flows, not a smoke probe.

## [3.5.0] - 2026-11-25

### Changed

- `gga/REVIEW-RULES.md` is now language-agnostic: output contract, evidence, secrets, data, tests, security and hygiene. Odoo 11 specifics moved to the active profile.
- `scripts/install-gga.sh` appends `<profile>/gga/REVIEW-RULES.md`; a profile with only `AGENTS.fragment.md` remains a reported compatibility fallback. Without `--profile`, only the core rules are installed.
- `scripts/bootstrap.sh --with-gga` passes the selected profile to `install-gga.sh`; `profiles/_template` and `new-profile.sh` include `gga/REVIEW-RULES.md`.

### Added

- `tests/test_install_gga.py`: core + profile composition, core-only mode and fragment fallback.

## [3.4.0] - 2026-11-25

### Added

- `evals/agent_runner.py`: agent-neutral executor and judge normalization for OpenCode, Claude Code, Codex, pi and Hermes. Claude print mode is verified locally; Codex remains supported but needs its own login.
- `gga/REVIEW-RULES.md`: canonical blocking and advisory rules derived from the FactorLibre MR preflight, plus company and profile precedence. It now covers manifest/version/changelog evidence, flake8, mandatory pylint, check-xml, pre-commit, pipeline evidence, OCA/ORM N+1 patterns, route/token allowlists and real MR failure patterns.
- `scripts/review-gga.sh`: blocking by default, requires `STATUS: PASSED`; `--advisory` and `GGA_ADVISORY=1` keep the report without blocking.
- `scripts/install-gga.sh --profile` and `--with-pre-push`: append profile rules and optionally enable GGA after verify in the composite pre-push hook.
- `dev-agent init` as an alias of `install.sh`; `install.sh` writes `.dev-agent/profiles.lock` with the profile source and commit, and `profile use` updates the active entry.
- `dev-agent review-gga`; PHP support in `guard/comment_lint.py`, including `//`, `#` and docblocks.

### Changed

- `evals/harness.py` and `evals/loop.sh` use the neutral runner; `--agent build` remains an OpenCode alias.
- README, operations, architecture, diagrams, install and training docs reflect the implemented runner, GGA gate and PHP lint.

## [3.3.0] - 2026-11-25

### Added

- `docs/SISTEMA-FUNCIONALIDADES.html`: complete functional reference for the system: four repos, auto-installation, inventory, gate, profiles, skills, CodeGraph, Engram, tech-doc, change flow, CLI, evals, limits and current state.
- `docs/formacion/dev-agent-kit-para-companeros.html`: 16-slide informative presentation for the team, without trainer cues, simulations or exercises; it explains what the system is, how it installs, how it works and what changes for the team.

## [3.2.0] - 2026-11-25

### Added

- `install.sh`: interactive one-line installer with dynamic profile discovery, one or several profiles, active profile, agents, CodeGraph, Engram, tech-doc and optional single HTML; idempotent and non-interactive through flags.
- `bin/dev-agent`: usage wrapper for `doctor`, `guard`, `verify`, `review`, `eval`, `profile`, `codegraph` and `memory`.
- `scripts/doctor.sh`: reads the repo and reports installed, optional and missing pieces without turning a warning into green.
- `docs/INSTALADOR.md`, `docs/USO-RAPIDO.md` and `docs/MEJORAR-SKILLS.md`.
- The installer patches the kit path into the installed hooks, symlinks `dev-agent` under `~/.local/bin`, excludes local artifacts and saves the installation in Engram when available.

### Changed

- README, install guide and training guide make `install.sh` the primary path; `bootstrap.sh` remains the lower-level path.
- Training deck grows to 37 slides: purpose, strengths, the full front-to-back flow, CodeGraph/Engram/doctor, a reverse evidence walkthrough and three clickable live simulations.

## [3.1.0] - 2026-11-19

### Added

- `scripts/install-techdoc.sh`: clones or links `ScalpersCompany/scalpers-tech-doc`, links `~/.agents/AGENTS.md`, writes `docs/TECHDOC.md`, and links the generated single HTML locally when it exists; private HTML is never copied into the kit.
- `bootstrap.sh --profile <name>`: copies the active profile to `.dev-agent/profiles/<name>`, writes `.dev-agent/config`, and excludes `.dev-agent/` locally.
- `bootstrap.sh --with-techdoc`, `--techdoc-path` and `--build-techdoc-html`: automatic tech-doc clone/link and optional single-HTML build.
- `tests/test_install_techdoc.py`.

### Changed

- Automatic install no longer requires manual profile copying; `dev-agent init` and the full lock remain pending.
- Training guide, deck, install, profiles and integration docs describe the automatic flow and the private-HTML boundary.

## [3.0.0] - 2026-11-19

### Added

- `docs/FORMACION-DEV-AGENT-KIT.md`: three-session onboarding guide for a colleague starting from zero, covering download, install, profiles, verify, skills, models, labs, assessment, troubleshooting and known gaps.
- `docs/formacion/dev-agent-kit-formacion.html`: self-contained, keyboard-navigable 27-slide deck for the same material.

## [2.9.0] - 2026-11-19

### Changed

- Removed the fixed `scalpers-v11` product row from README, architecture, install, operations, profiles, integration and diagrams. The target is the repository where development happens (Odoo, PHP or any stack), with the kit and the active profile installed at its root; there is no fixed product repository.

## [2.8.0] - 2026-11-19

### Added

- `scalpers-tech-doc` is now a first-class repository in the README, architecture, install, operations and profiles docs, the Mermaid map and both HTML diagrams: four separate repos (kit, profiles, techdoc, product), the canonical `AGENTS.md` link and the `check-techdoc.sh` gate.
- The detailed flow starts with the four repositories and stops when techdoc is not clean.

## [2.7.0] - 2026-11-19

### Changed

- Removed `rsc-brain` from this project; the curated-knowledge/wiki layer is deferred until the AWS infrastructure exists.
- `engram` stays local as MCP until that infrastructure exists; docs, diagrams and status now say so.
- The Odoo profile no longer references the knowledge layer or evaluates its installer skill.

## [2.6.0] - 2026-11-19

### Changed

- Published as `ScalpersCompany/dev-agent-kit` (public); clone commands and status docs now use the company URLs.
- The Odoo 11 profile points to `ScalpersCompany/dev-agent-profiles` (public); no private remote remains in the docs.

## [2.5.0] - 2026-11-19

### Added

- `scripts/check-techdoc.sh`: verifies the company `scalpers-tech-doc` clone, remote, `AGENTS.md`, branch/commit, clean tree and `~/.agents/AGENTS.md` link; no network and no writes.
- `tests/test_check_techdoc.py`: clean, dirty, allow-dirty and wrong-remote cases.
- `docs/INTEGRACION-TECHDOC.md`: separate-repo integration, canonical norm, workspace layout, no submodule, local-only CI and current dirty-clone status.
- The core `AGENTS.md`, README and Odoo profile state that the company norm wins and the profile only adds Odoo rules; `PROFILE_NORM_REPO`/`PROFILE_NORM_PATH` are declared.

## [2.4.0] - 2026-11-19

### Added

- `install-agent-adapters.sh --profile <profile>` merges the profile domain skills into the generated OpenCode and Claude adapters.
- Adapter tests for profile-skill merging and unknown agents.
- The eval harness isolates the judge in a temporary directory, copies `agents/judge.md` there, marks timed-out executors and judge failures invalid, and supports `.claude`/`.codex` as support paths.

### Changed

- The template, README and profile design use one relative profile path, the correct `python3` validator command and a portable profiles path.

## [2.3.0] - 2026-11-19

### Changed

- `scripts/install-agent-adapters.sh --profile <profile>` merges the profile's domain skills into the OpenCode and Claude adapters.
- The eval harness copies `.claude/` and `.codex/` support paths and no longer reports them as agent changes.
- The judge runs in a fresh temporary directory with only `agents/judge.md`; it no longer has the executor's sandbox. A timed-out executor and a judge that returns no JSON are marked invalid instead of being scored as zero.
- The profile template and README remove the duplicated validator step and the hard-coded home path.
- The adapter tests cover profile-skill merging and unknown agents.

## [2.2.0] - 2026-11-19

### Added

- `scripts/install-agent-adapters.sh`: generates `.opencode/` and `.claude/` adapters from the neutral `skills/`, `commands/` and `agents/` source; the generated directories are gitignored.
- `tests/test_agent_adapters.py`: checks the generated OpenCode and Claude adapters and rejects unknown agents.
- `docs/diagrams/flujo-detallado.html` and the detailed Mermaid flow in `docs/DIAGRAMA-SISTEMA.md`: decisions, loops, artifacts and the OpenCode eval gap.

### Changed

- The core skills and commands moved out of `.opencode/` into neutral `skills/` and `commands/`; the eval judge moved to `agents/judge.md`. `.opencode/` is no longer a tracked source directory.
- The eval harness support paths now cover `skills/`, `commands/` and `agents/`; the loop points at `skills/`.
- README, install guide, operations, profile template and architecture state the neutral source, the generated adapters and the remaining OpenCode-only eval runner.
- The generated `.claude/` and `.codex/` adapter paths are gitignored.

## [2.1.0] - 2026-11-19

### Added

- Complete profile template: `profile.json`, `profile.env`, `profile.schema.json`, `AGENTS.fragment.md`, guard, verify, skills, evals, tests, docs and `CHANGELOG`.
- `scripts/new-profile.sh`: generates a profile from the template with a backup and fills name and language.
- `scripts/validate-profile.py`: validates the profile contract, `profile.env` and every path; tested in CI.
- `docs/CREAR-PERFIL.md`: step-by-step guide, guard/verify/skills/evals contracts, checklist and anti-patterns.
- `docs/DIAGRAMA-SISTEMA.md` and `docs/diagrams/sistema.html`: Mermaid and visual map of the flow and the layers.
- README, operations and install guide point to the template, generator, validator and map.

## [2.0.0] - 2026-11-19

### Changed

- The Odoo 11 profile is extracted to the separate local repository `dev-agent-profiles/profiles/odoo11`: linter, allowlist, verify example, Odoo skills, eval cases, rubrics, tests and Odoo docs.
- The core no longer contains Odoo: `guard/guard.sh` loads the active profile from `.dev-agent/profiles/<name>` or `profiles/<name>` and runs its `guard/*.sh`.
- The core keeps five generic skills; the Odoo skills live in the profile.
- Core docs, install guide, operations, baseline and coverage are language-agnostic; Odoo details live in the profile docs.
- The PHP skeleton is moved to the profiles repository.

### Removed

- `guard/odoo_lint.py`, `guard/odoo_allowlist.txt`, `tests/test_odoo_lint.py`, the Odoo and FactorLibre eval cases and rubrics, and the Odoo skills from the core.

## [1.10.0] - 2026-11-19

### Added

- The profile design documents which names are real skills: SDD is `spec-driven-development`; ODD is always-on AGENTS/SOUL text; RDD is the `gentle-ai review` binary; rsc-harness skills are repo-local under `.rsc/skills/`.
- The Odoo profile skill sources are listed: profile skills, the global SDD skill, repo-local rsc-harness skills and the AGENTS fragment; ODD and RDD are not declared as skills.

## [1.9.0] - 2026-11-19

### Added

- `scripts/bootstrap.sh`: automated current install into a git repo, with backups, verify config from the example, pre-commit and optional `--with-verify` and `--with-gga`.
- The README now covers automated install, profiles, status, agents and GGA; the install guide uses the bootstrap and keeps the manual path as a fallback.
- The profile design now recommends one private `dev-agent-profiles` repository with one directory per profile, and states that the git hooks are shared while guard, verify, skills, evals and the AGENTS fragment are per profile.

### Changed

- The README status table separates what is implemented from what is designed or pending.

## [1.8.0] - 2026-11-18

### Added

- `docs/INSTALACION-Y-FUNCIONAMIENTO.md`: the install and operation guide, in Spanish, with the current manual install, hooks, verify, guard, evals, GGA, agent skills, security, troubleshooting and the implemented-versus-planned status.
- The README starts with a link to that guide.

## [1.7.0] - 2026-11-18

### Added

- `docs/PERFILES-EN-REPOS.md`: profiles in separate private repositories, a registry plus clone (no submodules), a lock by commit, and `dev-agent init/use/profiles/doctor` with `--profile`, `--all`, `--select` and `--source`.
- The README and operations guide point to the profile-repository design.

### Changed

- Profiles are no longer described as directories inside the core; the core keeps the contract, registry and installer, and each language keeps its own repository.

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
