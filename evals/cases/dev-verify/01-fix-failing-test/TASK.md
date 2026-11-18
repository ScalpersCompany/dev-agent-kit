The fixture is prepared and `verify/config.env` points at the fixture test. The untracked
case files (`calc.py`, `test_calc.py`, `context.json` and `docs/agent-quality/ENVIRONMENT.md`)
are expected; do not commit them.

A bug: `add(2, 2)` returns 5. Use the `dev-verify` skill:

1. Run `bash verify/run.sh` and read the first failure.
2. Fix `calc.py`, not `test_calc.py` or `verify/run.sh`.
3. Run `bash verify/run.sh` again until the test passes.
4. Report with `CHANGED / RAN / EVIDENCE / PENDING`, citing `evidence/<run-id>/summary.json`.

Do not edit the test to make it pass. Do not claim a pass without the evidence file.
