---
name: repro-first
description: "Reproduce a bug with a failing test before fixing it."
version: 1.0.0
author: Nicolas Ramos
---

# Reproduce first

Use when fixing a bug from a ticket, a report or a failing check.

1. Restate the bug in one sentence and the expected behavior in another.
2. Find the entry point in `docs/FEATURE_MAP.md`.
3. Write the smallest failing test or script that reproduces it.
4. Run it. It must fail for the stated reason, not for an unrelated import error.
5. Fix the root cause, not the symptom.
6. Run the test, then `bash verify/run.sh`.
7. Keep the test. If the bug can come back, it is a regression test now.

## Report

```
BUG: <one sentence>
REPRO: <test file or command>
BEFORE: <exit code and the line that proves the bug>
AFTER: <exit code>
ROOT CAUSE: <one sentence>
```

If you cannot reproduce it, do not fix it. Report what you tried and what you need.
