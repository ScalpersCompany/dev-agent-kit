---
description: Run or design the eval for a skill
agent: build
---

Use the eval harness in `evals/`.

1. If there is no case yet, create one under `evals/cases/<skill>/<case>/` with `TASK.md` and the files the agent needs.
2. Run `python3 evals/harness.py --case-dir <case> --rubric evals/rubric.example.json --dry-run` first.
3. Then run it for real with the approved model.
4. Report the score, the reasons and the token cost.

Context: $ARGUMENTS
