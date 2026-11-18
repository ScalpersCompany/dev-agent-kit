Review the patch in `repo.diff` with the `review-diff` skill.

Read-only: do not edit, write, run commands that change state, or apply the patch.

Output the skill's contract exactly:

- first line `STATUS: PASSED` or `STATUS: FAILED`;
- one finding per line, `<BLOCKER|CRITICAL|WARNING|SUGGESTION>: <file>:<line> <what is wrong and what to do>`;
- end with `SUMMARY: <n> files reviewed`.

Judge only the change in front of you. Do not invent findings and do not report style nits
the formatter owns.
