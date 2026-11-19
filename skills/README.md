# Core skills

These are the five generic skills. They are the source of truth; an agent that needs a
project-level copy gets it through `scripts/install-agent-adapters.sh` or the global
installation, not by keeping a second tracked version here.

- `dev-verify`: prove a change with the real commands and evidence.
- `repro-first`: reproduce a bug with a failing test before fixing it.
- `review-diff`: read a diff with a machine-readable verdict.
- `correct`: turn repeated corrections into lint, tests or CI.
- `query-readonly`: answer data questions with read-only SQL and saved evidence.

The profile's `skills/` directory carries only the domain skills. The core does not copy
those either; the profile is the owner.
