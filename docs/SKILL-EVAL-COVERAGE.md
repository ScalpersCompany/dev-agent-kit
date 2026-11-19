# Skill evaluation coverage

The core ships five skills. The Odoo-specific skills are in the profile and are listed in
`dev-agent-profiles/profiles/odoo11/docs/SKILL-EVAL-COVERAGE.md`.

| Priority | Skill | Installed | Eval case | State |
|---|---|---|---|---|
| P0 | `dev-verify` | yes | yes | real K=3 (10.0) |
| P0 | `repro-first` | yes | yes | real K=3 (10.0) |
| P0 | `review-diff` | yes | yes | real K=3 (9.64) |
| P1 | `correct` | yes | no | installed; no real run |
| P1 | `query-readonly` | yes | no | installed; no real run |

The profile skills (`odoo-safe-change`, `odoo-11-code-review`,
`factorlibre-mr-preflight`) are evaluated with the profile cases and rubrics. The
rsc-harness skills are repo-local and are not core skills.

The rule is simple: a skill is not trusted because it exists; it is trusted when a case,
a judge and a recorded score show it working, or when the user explicitly accepts the gap.
