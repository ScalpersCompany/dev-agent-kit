# GGA review rules

First line exactly `STATUS: PASSED` or `STATUS: FAILED`. On failure, list one
finding per line as `file:line - rule - issue`.

Reject:

- Explanatory comments in new or modified code. Tool directives, legal
  copyright/license/SPDX headers, docstrings, `help` and README are not
  comments.
- Tests that only mock or assert an internal method such as `run()`; tests
  must prove observable behaviour.
- `RetryableJobError` for a terminal state; an all-cancelled product must not
  retry forever.
- `product_uom_qty` summed or rounded with the product UoM rounding; use
  `product_qty` or convert explicitly.
- `or {}` or `or []` that hides a `None` from a contract.
- `depends` that repeats the transitive closure of the parent module.
- Secrets, tokens, credentials, personal data, `eval`, `exec`, `pdb`, or a
  debugger in production code.
- Raw SQL writes without parameters and a test; `cr.commit()` in business code;
  `sudo()` outside the allowlist in Odoo.
- A diff that mixes unrelated refactors, formatting, translations or another
  ticket.
- A test disabled, commented, not imported, or removed only to make the
  pipeline green.

Prefer:

- A file:line finding with a concrete fix, not a general opinion.
- The profile rules in `AGENTS.md` over generic style preferences.
- Deterministic checks over AI judgement when both can decide.
