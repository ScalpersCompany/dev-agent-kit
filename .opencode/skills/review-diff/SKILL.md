---
name: review-diff
description: "Read-only diff review with a machine-readable verdict."
version: 1.0.0
author: Nicolas Ramos
---

# Review a diff

Read-only. Never edit, write or run commands that change state.

## Output contract

The first line is exactly `STATUS: PASSED` or `STATUS: FAILED`.

Then one finding per line:

```
- <BLOCKER|CRITICAL|WARNING|SUGGESTION>: <file>:<line> <what is wrong and what to do>
```

End with `SUMMARY: <n> files reviewed`.

## Rules

- Judge only the change in front of you.
- A defect that already exists on the base branch is `pre-existing: <file>:<line>` and does not block.
- No style nits the formatter owns.
- No speculation without a file and a line.
- If the diff is too large to review, say so and ask for it split.
