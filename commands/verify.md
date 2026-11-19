---
description: Verify the current change and capture evidence
agent: build
---

Run the `dev-verify` skill for the current change.

1. Run `bash verify/run.sh`.
2. Read the evidence summary.
3. If it fails, fix the first failure and run again.
4. Answer with the delivery format from `AGENTS.md` and the evidence path.

Context: $ARGUMENTS
