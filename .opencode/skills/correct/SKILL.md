---
name: correct
description: "Turn repeated corrections into lints, tests or CI checks."
version: 1.1.0
author: Nicolas Ramos
---

# Correct at the highest level

Use when the same correction appears twice in transcripts, review comments or tickets.

Kit root: `KIT="${DEV_AGENT_KIT:-$HOME/dev-agent-kit}"`. If the current repo has no
`guard/` or `verify/`, use the same paths under `$KIT`.

1. Collect the corrections. Sources: session transcripts, PR comments, review notes, ticket replies.
2. Classify them into mistake classes: naming, layering, error handling, Odoo access, tests, copy, commits.
3. For each class, choose the highest level that works:
   - architecture or API design that makes the mistake impossible,
   - types,
   - lint rule,
   - CI check,
   - test,
   - documentation last.
4. Implement the top two mechanisms now. Do not write another paragraph of prose for the rest.
5. Output a table:

```
| rule | mechanism | where | test that proves the mechanism exists |
```

6. Run `bash guard/guard.sh` and `bash verify/run.sh` if the repo has them; otherwise
   `bash "$KIT/guard/guard.sh"` and `bash "$KIT/verify/run.sh"`.

A rule with no mechanism is a wish. The output of this skill is code, not advice.
