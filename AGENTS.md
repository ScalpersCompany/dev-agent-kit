# Agent rules for this repository

These rules apply to every agent and every session in this repo. The repo is the source of truth; a rule that only lives in a chat does not exist.

## The ten non-negotiables

1. **Evidence before done.** A change is done only after `bash verify/run.sh` has run on the change and left artifacts in `evidence/<run-id>/`. "It compiles" and "it should work" are not evidence.
2. **No production, ever.** No production URLs, no production credentials, no migration against a shared database, no `push` to a release branch. Those are one-way doors.
3. **No `sudo()` without a reason.** In Odoo code, `sudo()` is allowed only in the paths listed in `guard/odoo_allowlist.txt` and must have a test that proves the access rule.
4. **No `cr.commit()`.** The framework owns the transaction. A commit inside business code is a defect.
5. **No raw SQL without a written reason.** Prefer the ORM. If SQL is unavoidable, parameterize it and add a test for the edge case.
6. **No secrets in code.** Keys, tokens, passwords and customer data come from the environment or a vault. If you see one committed, stop and report it.
7. **Comments explain why, never history.** Do not narrate what changed, who said what, or what the previous agent did. If the code needs a comment to be understood, fix the code first.
8. **One feature, one directory.** Do not create a second place for an existing concept. When two places already exist, do not add a third.
9. **Two corrections of the same kind become a mechanism.** The third time you fix the same mistake, it becomes a lint rule, a test, or a CI check, not another paragraph in this file.
10. **Report the real state.** End every task with: what changed, what ran, what failed, what is pending. Never claim a check you did not run.

## Read this before searching

- `docs/FEATURE_MAP.md` tells you where each feature lives and how to reach it in the UI.
- `docs/agent-quality/ENVIRONMENT.md` tells you how to boot, test and lint.
- `guard/odoo_allowlist.txt` lists the only files where `sudo()` is accepted.

## Commands

```sh
bash verify/run.sh          # boot, smoke, tests, evidence
bash guard/guard.sh         # lint, types, secrets, Odoo checks
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
