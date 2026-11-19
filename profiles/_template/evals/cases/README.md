# Profile eval cases

One directory per case. Each case needs:

- `TASK.md`: the request the agent receives, including the exact output contract.
- `context.json`: the paths the judge may read, relative to the case.
- the fixture files the task needs;
- a rubric in `evals/rubric.<name>.json`.

The harness is the core one (`evals/harness.py`). Run K=3 with a judge different from the
executor and threshold 8.5. A case without a rubric or without `context.json` is not a real
eval. Record the result in `docs/EVAL-BASELINE.md`.
