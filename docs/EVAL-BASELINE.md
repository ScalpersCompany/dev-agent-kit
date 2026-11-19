# Eval baselines

The core baseline uses K=3, threshold 8.5 and a judge different from the model under test.

| Core skill | Case | Result |
|---|---|---|
| `dev-verify` | `evals/cases/dev-verify/01-fix-failing-test` | 10.0/10 |
| `repro-first` | `evals/cases/repro-first/01-discount-bug` | 10.0/10 |
| `review-diff` | `evals/cases/review-diff/01-unsafe-handler` | 9.64/10 |

`correct` and `query-readonly` have no real eval yet; they are installed and covered by
the core checks, not by a model run.

The Odoo 11 and FactorLibre baselines are in
`dev-agent-profiles/profiles/odoo11/docs/EVAL-BASELINE.md`: Odoo 11 code review 9.81/10 and
FactorLibre MR preflight 9.52/10. The cases and rubrics live in the profile.

A score is a measurement, not a gate for every commit. Re-run the eval when a skill,
prompt, review rule or rubric changes.
