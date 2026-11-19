# Agent rules for this repository

These rules apply to every agent and every session in this repo. The repo is the source of truth; a rule that only lives in a chat does not exist.

## The seven non-negotiables

1. **Evidence before done.** A change is done only after `bash verify/run.sh` has run on the change and left artifacts in `evidence/<run-id>/`. "It compiles" and "it should work" are not evidence.
2. **No production, ever.** No production URLs, no production credentials, no migration against a shared database, no `push` to a release branch. Those are one-way doors.
3. **No secrets in code.** Keys, tokens, passwords and customer data come from the environment or a vault. If you see one committed, stop and report it.
4. **No comments in code.** No explanatory comments in new or modified code in any language. Tool directives only (`# noqa`, `# type: ignore`, `# pylint: disable`, `# shellcheck`, `// eslint-disable`, `@ts-ignore`) plus legal copyright/license/SPDX headers. Docstrings and field help are documentation, not comments. `guard/comment_lint.py` blocks new comments in `guard/guard.sh --staged`.
5. **One feature, one directory.** Do not create a second place for an existing concept. When two places already exist, do not add a third.
6. **Two corrections of the same kind become a mechanism.** The third time you fix the same mistake, it becomes a lint rule, a test, or a CI check, not another paragraph in this file.
7. **Report the real state.** End every task with: what changed, what ran, what failed, what is pending. Never claim a check you did not run.

## Read this before searching

- `docs/FEATURE_MAP.md` tells you where each feature lives and how to reach it in the UI.
- `docs/agent-quality/ENVIRONMENT.md` tells you how to boot, test and lint.
- The active profile's `AGENTS.fragment.md` carries the language rules. The core does not know Odoo, PHP or Node.

## Commands

```sh
bash verify/run.sh          # boot, smoke, tests, evidence
bash guard/guard.sh         # generic checks plus the active profile checks
bash guard/guard.sh --staged  # only staged files, for pre-commit
```

## Delivery format

```
CHANGED: <files, one line>
RAN: <commands and exit codes>
EVIDENCE: <path under evidence/>
PENDING: <what is not done, or "none">
```

## Language

Code, identifiers, comments, commit messages, PR descriptions and documentation in English. Conversation with the user in Spanish.

## Commits

Conventional commits, one work unit per commit. No `Co-Authored-By`, no AI attribution, no emoji.
