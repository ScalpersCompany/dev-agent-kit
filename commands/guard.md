---
description: Run the deterministic guardrails
agent: build
---

Run `bash guard/guard.sh`.

For every failure:
- read the message,
- fix the root cause,
- run the guard again.

Do not disable a check to make it pass. If a check is wrong, say why and propose the change to the rule.

Context: $ARGUMENTS
