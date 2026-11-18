A bug: `apply_discount(100, 10)` returns 95 instead of 90.

The case's `docs/agent-quality/ENVIRONMENT.md` and `verify/config.env` are fixtures; any
other modified support file is pre-existing, not yours.

Use the `repro-first` skill:

1. Write the smallest failing test in `test_shop.py`; run it and capture the failure.
2. Fix the root cause in `shop.py`; do not change the test to make it pass.
3. Run the test again; it must pass.
4. Report `BUG / REPRO / BEFORE / AFTER / ROOT CAUSE`, with the commands and exit codes.

Do not fix before the failing test exists. Do not edit unrelated files.
