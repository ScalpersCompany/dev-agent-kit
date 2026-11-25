# GGA review rules — DevAgentKit

You are the second reviewer for a development change. `guard` and `verify` are the
deterministic gate; this review catches semantic defects they cannot prove. Review only
the staged diff and the files it touches. Do not ask for a full-repository audit.

## Output contract

Return exactly one of these two forms:

```text
STATUS: PASSED
```

```text
STATUS: FAILED
path/to/file:line - RULE - concrete issue and required fix
path/to/file:line - RULE - concrete issue and required fix
```

- `STATUS` must be the first line.
- One finding per line, with a real `file:line` in the change. Do not report a general
  opinion without a location.
- A finding in **BLOCKING** means `STATUS: FAILED`. An `ADVISORY` finding alone does not
  fail the review.
- If the diff does not contain enough evidence, say what is missing; do not invent code
  or a pass. A review without a status is not a pass.
- The company rule in `scalpers-tech-doc/AGENTS.md` wins over this file. The active
  profile's `AGENTS.fragment.md` adds the language rules; it never weakens the company
  rule.

## BLOCKING — reject the change

### Secrets and dangerous primitives

- A secret, token, password, private key, webhook secret, customer personal data or
  production credential in code, tests, fixtures, logs, comments or documentation.
- `eval`, `exec`, `pdb`, `breakpoint`, a debugger left enabled or a backdoor in code that
  can run in production.
- A production URL, production database or shared database used as a test/development
  target.
- A dependency, script or download from an unapproved source that executes at install or
  runtime without review.

### Tests and evidence

- A test disabled, commented out, deleted, not imported or marked skip only to make the
  pipeline green.
- A test that only asserts an internal call (`run()`, `assert_called`, a private helper)
  and would still pass if the behaviour were wrong; tests must prove observable
  behaviour.
- A behaviour change with no test that fails without it and passes with it, when a
  deterministic test is possible.
- A success claim without the command output or evidence artifact that proves it.
- A test or verify command that was not actually executed, or a green claim based only on
  a code read.

### Odoo 11 correctness

- A v12+ API, OWL, `@api.one`, f-string syntax, `type="json"` route, or any feature not
  available in Odoo 11 / the supported Python runtime.
- `ensure_one()` missing on a method that assumes one record; missing `for record in
  self` in a multi-record constrain; `super()` with the old two-argument form in Python 3.
- `float` money/quantity compared without `float_compare`; `datetime.now()` where
  `fields.Datetime.now()` is required.
- `product_uom_qty` summed or rounded with the product UoM rounding; use `product_qty` or
  convert explicitly.
- `search` inside a loop; `search([])` without a domain where the record set must be
  bounded; `browse()` missing where an id is known; `read_group` reimplemented by hand.
- A defensive `or {}` / `or []` that hides a contract returning `None`; `getattr(obj,
  "field", default)` that hides a wrong field name.
- Reimplementing a core calculation such as `compute_all`, `_amount_all` or a rounding
  rule instead of using the native option or method.
- A new or modified field without `help` (meaning, unit/format and effect) and its
  documentation in the same change.

### Security and data access

- Missing `ir.model.access.csv` for a new model, including a `TransientModel`; missing
  `ir.rule` for a record rule the domain does not protect.
- `sudo()` outside the profile allowlist, especially in a controller; an admin token or
  elevated permission used to work around access rules.
- A credential, token, password, hash or derived credential field readable by a
  non-administrator group; the connector filter is not enough. Cite the ACL row that
  grants the read.
- Raw SQL without parameters, a written justification and a test for the edge case;
  `cr.commit()` in business code; an unparameterised write that can corrupt data.
- A controller, RPC or public route that bypasses the normal access rules.

### Migrations, XML and data

- Renaming or deleting a persisted field/model without a migration; a migration that
  would not run on a new install (`post_init_hook` where needed).
- A destructive `UPDATE`/`DELETE` without a bounded `WHERE`, a backup, a dry run or a
  log; an `UPDATE` without `WHERE` is always blocking.
- A migration folder whose version is not the new manifest version; a version not bumped
  when the module or data changes.
- An incomplete or redundant `depends`: every model, view and xmlid used directly must be
  declared; do not copy the parent's transitive closure.
- A view, XML id, security CSV, data file or asset that does not load in a clean database;
  a core view edited directly; a duplicated XML id; a missing `noupdate="1"` on
  customer-editable data.
- A manifest change that is not reflected in `CHANGELOG.md` when behaviour changes.

### Queue, jobs and terminal states

- `RetryableJobError` used for a terminal state; an all-cancelled product or a permanent
  business condition that will retry forever.
- A job that retries a condition that cannot change, or swallows an exception and leaves
  the record in a half-finished state.

### Scope and code hygiene

- Explanatory comments in new or modified code in any language. Legal headers and tool
  directives are allowed; docstrings, `help`, `_description` and README are documentation,
  not comments.
- Dead or commented-out code, a debug print, a temporary script, a `.bak`, a capture or a
  work file that reaches the diff.
- An unrelated refactor, a whole-file reformat, a translation of another environment, a
  dependency bump or another ticket mixed into this change.
- A change that touches production, a release branch, a shared database or a migration
  with destructive effects without explicit human authorization.
- A code path that changes security, permissions, concurrency, payment, stock, fiscal or
  data-deletion behaviour without a test that proves the new rule.

## ADVISORY — report, do not fail

- Naming, readability, duplication or a simpler structure.
- Missing docstring, README section or changelog entry that is not required for safety.
- Test coverage that could be broader, a slow query that is not on a hot path, or a
  performance improvement with no correctness risk.
- A style preference that is not in the company norm or the active profile.
- A missing convenience command, log line or diagnostic that would help operators.

## Method

1. Read the staged diff and the files it touches; use the profile and `AGENTS.md` as
   context, not as a reason to invent rules.
2. Check blocking rules first. For every finding, cite `file:line`, the rule and the
   concrete fix.
3. Check that `guard` and `verify` evidence is present and honest. A claim is not
   evidence.
4. Only then produce advisory findings.
5. If no blocking finding exists, return `STATUS: PASSED` even if there are advisory
   findings; leave the advisories out of a PASSED response unless they change the
   verdict.
