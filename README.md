# Dev agent kit

Repository: https://github.com/ScalpersCompany/dev-agent-kit

A repo-local kit to make agents trustworthy on a development codebase. It implements executable verification, skills built from observed failures, agent evals and deterministic guardrails before prose. The core is language-agnostic; Odoo, PHP and other environments live in profiles.

Start here: `docs/INSTALACION-Y-FUNCIONAMIENTO.md` (Spanish) — install, daily flow, guard, verify, evals, GGA, profiles, security and the implemented-versus-pending status.

For a new colleague, start with `docs/INSTALADOR.md` (one line), then
`docs/FORMACION-DEV-AGENT-KIT.md` and `docs/formacion/dev-agent-kit-formacion.html`.
The complete functional reference is `docs/SISTEMA-FUNCIONALIDADES.html`; the short
peer presentation is `docs/formacion/dev-agent-kit-para-companeros.html`.
Daily commands: `docs/USO-RAPIDO.md`. Improving a skill: `docs/MEJORAR-SKILLS.md`.

## Repositories that work together

| Repository | Role | Relation |
|---|---|---|
| `ScalpersCompany/dev-agent-kit` | Deterministic gate, hooks, skills and evals | This repository; public |
| `ScalpersCompany/dev-agent-profiles` | Odoo 11 and PHP profiles | Separate public repository; installed by the active profile |
| `ScalpersCompany/scalpers-tech-doc` | Company norm and documentation | Separate company repository; its `AGENTS.md` is canonical and is linked at `~/.agents/AGENTS.md`; verified by `scripts/check-techdoc.sh` |
| Your development repository | The repository where the work happens (Odoo, PHP, any stack) | Install the kit and the active profile at its root; there is no fixed product repository |

They are separate repositories, not submodules. `scalpers-tech-doc` is the canonical source
of the company norm; the kit, the profiles and the product code consume it without copying
it. The integration contract is `docs/INTEGRACION-TECHDOC.md`.

## Company norm

The company norm lives in the separate repository `ScalpersCompany/scalpers-tech-doc`; its
`AGENTS.md` is linked at `~/.agents/AGENTS.md`. The kit does not copy it: `AGENTS.md` here
is the local contract, and the Odoo profile's `AGENTS.fragment.md` only adds Odoo rules.
`scripts/check-techdoc.sh` verifies the remote, the branch/commit, a clean tree and the
link. The full integration is in `docs/INTEGRACION-TECHDOC.md`; the local clone is
currently on a dirty feature branch, so the check fails closed until that company change is
closed. This is deliberate: the company repo is the source of the norm, not a copy inside
the kit.

## Scope

This kit is for the development base, not production. Production receives only changes that pass `guard/guard.sh`, `verify/run.sh`, the applicable eval and the evidence gate. The kit is the filter; it is not deployed to production.

## Core

```text
install.sh                    one-line installer: profile menu, agents, CodeGraph, Engram, tech-doc and doctor
bin/dev-agent                 usage wrapper: doctor, guard, verify, review, eval, profile, codegraph, memory
AGENTS.md                     generic rules the agent reads first
skills/                       five core skills: dev-verify, repro-first, review-diff, correct, query-readonly
commands/                     neutral prompt templates; adapters install them per agent
agents/                       eval judge prompt; adapters install it for OpenCode
scripts/install-agent-adapters.sh  generates .opencode/.claude adapters from the neutral source; --profile also merges the profile skills
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
scripts/check-techdoc.sh      verifies the company norm clone, remote, branch/commit and link
gga/                          optional AI review: .gga example and rules
scripts/install-gga.sh        installs .gga and .gga-rules.md with backups
scripts/review-gga.sh         runs gga on staged files, optional or blocking
scripts/bootstrap.sh          copies the core into a repo, installs a profile, hooks and optional tech-doc reference
scripts/install-techdoc.sh    clones or links tech-doc, links AGENTS.md and writes docs/TECHDOC.md
scripts/new-profile.sh        creates a profile from profiles/_template with a backup
scripts/validate-profile.py   validates the profile contract and paths
scripts/install-hooks.sh      installs the hooks and backs up the existing ones
scripts/doctor.sh             reports installed, optional and missing pieces without false green
hooks/pre-commit              local pre-commit: guard --staged
hooks/pre-push                local pre-push: verify/run.sh
tests/test_comment_lint.py    unit tests for the comment gate
.github/workflows/quality.yml unit tests, syntax and eval dry-run in CI
docs/                         install, operations, architecture, profiles, coverage
docs/INSTALADOR.md            one-line install, menu and recovery
docs/USO-RAPIDO.md            daily commands
docs/MEJORAR-SKILLS.md        skill improvement loop
docs/FORMACION-DEV-AGENT-KIT.md  three-session training guide
docs/formacion/dev-agent-kit-formacion.html  37-slide training deck with simulations
docs/SISTEMA-FUNCIONALIDADES.html  complete functional reference: components, installer, gates, memory, status
docs/formacion/dev-agent-kit-para-companeros.html  16-slide peer presentation, informative, no trainer cues
docs/CREAR-PERFIL.md          how to build a new profile
docs/INTEGRACION-TECHDOC.md   how the company norm repository connects to the kit
docs/DIAGRAMA-SISTEMA.md      Mermaid map of the whole system
docs/diagrams/sistema.html    visual overview of the flow and the layers
docs/diagrams/flujo-detallado.html  detailed flow with decisions, loops and artifacts
CHANGELOG.md
```

The core has no `odoo_lint`, Odoo allowlist, Odoo skills, Odoo eval cases or Odoo docs. Those are in the Odoo profile. The core has no PHP either.

## Install (automated, current)

From this kit:

```bash
git clone https://github.com/ScalpersCompany/dev-agent-kit.git "$HOME/.dev-agent-kit" \
  && "$HOME/.dev-agent-kit/install.sh"
```

The installer asks for the target repository, profile or profiles, active profile, agents
and optional CodeGraph, Engram and tech-doc. It installs the kit, all skills, the hooks,
guard/verify, the selected profiles and the local references; see `docs/INSTALADOR.md`.

Non-interactive:

```bash
./install.sh --target /path/to/development-repo \
  --profiles all --active odoo11 --agents all \
  --with-codegraph --with-engram --with-techdoc --yes
```

The bootstrap remains the lower-level path:

```bash
bash scripts/bootstrap.sh /path/to/development-repo --profile odoo11 --with-verify
bash scripts/bootstrap.sh /path/to/development-repo --with-gga
```

## Profiles

All profiles can live in one company repository, `dev-agent-profiles`, with one directory per profile (`profiles/odoo11`, `profiles/php`). The core keeps the contract, the registry and the installer; the profile keeps its `profile.json`, `profile.env`, `guard/`, `verify/`, `skills/`, `evals/` and `AGENTS.fragment.md`.

The git hooks are **not** different per profile: the same core `pre-commit` and `pre-push` read the active profile and run its checks. What differs is the content the hook executes: guard checks, verify config, skills, eval cases and the AGENTS fragment.

SDD is the `spec-driven-development` skill. ODD is always-on text in `AGENTS.md`/`SOUL.md`, not a skill. RDD is the `gentle-ai review` binary, not a skill. The rsc-harness skills (`asdd`, `sdd-init`, `harness`, `verify`...) are repo-local in `.rsc/skills/`; gentle-ai installs and synchronises agents and does not replace rsc-harness.

## Create a profile

The base template is `profiles/_template`; the guide is `docs/CREAR-PERFIL.md`.

```bash
bash scripts/new-profile.sh php-nuevo \
  --language php \
  --repo /path/to/dev-agent-profiles \
  --description "PHP 8 with PHPStan, PHPCS and PHPUnit"
python3 scripts/validate-profile.py /path/to/dev-agent-profiles/profiles/php-nuevo
```

The generator copies the template, backs up an existing profile as `.bak-<timestamp>` and fills the name and language. The validator checks the contract, `profile.env` and every path. A profile that does not validate is not installable.

The visual map of the system is in `docs/diagrams/sistema.html`; the detailed flow with decisions, loops and artifacts is in `docs/diagrams/flujo-detallado.html`. The Mermaid version and the status table are in `docs/DIAGRAMA-SISTEMA.md`.

## Status

| Area | State |
|---|---|
| core `guard`, `verify`, evals, pre-commit/pre-push | implemented and covered by tests |
| Odoo 11 profile | extracted to `ScalpersCompany/dev-agent-profiles/profiles/odoo11`; public |
| PHP profile | skeleton moved to the profiles repository; PHPStan/PHPCS/PHPUnit not wired |
| `install.sh` one-line installer | implemented; menu of profiles, agents, CodeGraph, Engram, tech-doc and doctor |
| `bootstrap --profile` | implemented; lower-level path that copies the active profile and writes `.dev-agent/config` |
| `dev-agent` wrapper | implemented; doctor, guard, verify, review, eval, profile, codegraph, memory |
| `dev-agent init` and the profile lock | pending; `install.sh` is the complete path today |
| profile template, `new-profile.sh` and `validate-profile.py` | implemented and tested |
| visual system map | `docs/diagrams/sistema.html` and `docs/DIAGRAMA-SISTEMA.md` |
| detailed flow | `docs/diagrams/flujo-detallado.html` and the Mermaid section in `docs/DIAGRAMA-SISTEMA.md` |
| eval runner agent-neutral | pending: `evals/harness.py` and `evals/loop.sh` still use OpenCode |
| GGA advisory review | added; installation tested; no real review run |
| `comment_lint` for PHP | pending; the generic checker does not scan `.php` yet |
| `gentle-ai`, `rsc-harness`, `engram` | documented boundaries; `engram` stays local until the AWS infrastructure exists |
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
7. Install the hooks: `bash scripts/install-hooks.sh .` for the pre-commit guard; add `--with-verify` for the pre-push runtime gate and edit `.dev-agent/verify.env`. For OpenCode or Claude, run `bash scripts/install-agent-adapters.sh . --agents opencode,claude --profile /path/to/dev-agent-profiles/profiles/odoo11`; the kit's own `.gitignore` ignores the generated directories, but the target repo does not get a `.gitignore` from that script: add them to `.git/info/exclude` or commit them intentionally.
8. Copy one eval case, run `python3 evals/harness.py --case-dir evals/cases/dev-verify/01-fix-failing-test --rubric evals/rubric.dev-verify.json --dry-run`, then a real run with the approved model.

## What it does not do

- It does not touch production, migrations, secrets or customer data. Those are one-way doors and keep a human signature.
- It does not install third-party skill catalogs. Five core skills, each with a job.
- It does not call a personal model endpoint. Set the model in your copy of the rubric or pass `--model` with the company-approved provider.
- It does not run the agent in your working tree. Each eval runs in a disposable worktree or copy, and the judge receives the artifacts that run produced plus, when the case declares it in `context.json`, the source under review.
- It does not auto-merge. Autonomy is earned per repo after 30 green changes and zero reverts.
