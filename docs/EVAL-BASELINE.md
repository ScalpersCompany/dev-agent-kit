# First eval baseline

Internal baseline. It records the score and what the run observed; it does not name the
executor or the judge. Both are approved internal models, different from each other.

- Case: `evals/cases/odoo-11-code-review/01-seeded`
- Skill: `odoo-11-code-review` 1.2.1
- Runs: 3
- Isolation: `copy`
- Scores: 9.44, 10.0, 10.0
- Mean: 9.81; min 9.44; max 10.0; standard deviation 0.26
- Threshold: 8.5; result: pass
- Cost: 0.698729 USD; tokens: 11,489,208 (executor plus judge, summed across steps)

## What the runs observed

Run 1 missed two of the six `help=` fields (`api_key` and `bpost_passphrase_encoded`)
and made two questionable extra claims: that the computed `total` was editable, and a
duplicate asset warning. It still passed at 9.44.

Runs 2 and 3 found every seeded defect, enumerated every field without `help=`, and
returned 10.0. The remaining variance is model adherence to the skill's report
contract, not a missing rule: the contract in 1.2.1 already requires one line per
field without `help=` and v11-only fixes.

## Command

```bash
python3 evals/harness.py \
  --case-dir evals/cases/odoo-11-code-review/01-seeded \
  --rubric evals/rubric.odoo-11-code-review.json \
  --agent build \
  --model <approved> \
  --judge-model <approved-different> \
  --k 3
```

The shipped rubric uses `REPLACE_WITH_APPROVED_MODEL` placeholders. Do not put the
model names in this document, in a ticket, or in a commit message.
