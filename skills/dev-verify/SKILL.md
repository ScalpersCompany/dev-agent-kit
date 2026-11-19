---
name: dev-verify
description: "Prove a change by running the app and capturing evidence."
version: 1.1.0
author: Nicolas Ramos
---

# Prove a change

Use after any code change, before reporting done.

Kit root: `KIT="${DEV_AGENT_KIT:-$HOME/dev-agent-kit}"`. If the current repo has no
`verify/` or `docs/agent-quality/`, use the same paths under `$KIT`.

1. Read `docs/agent-quality/ENVIRONMENT.md` and `docs/FEATURE_MAP.md`; if the repo has
   no kit, read the same files under `$KIT`.
2. Run `bash verify/run.sh` if it exists; otherwise `bash "$KIT/verify/run.sh"`.
3. If it fails, read `evidence/<run-id>/summary.json` from the repo or from the kit root
   used in step 2, fix the first failure, run again. Do not fix a second failure before
   the first is green.
4. If the change has UI, use the feature map to navigate and capture a screenshot or a
   short video into `evidence/<run-id>/` (repo or kit).
5. If the change has data, run the read-only query and save the result next to the
   evidence.
6. Report with the delivery format in `AGENTS.md`; if the repo has none, use
   `$KIT/AGENTS.md`.

Exit code 0 is the minimum, not the proof. A check that did not run is not a check that passed.

## Failure protocol

- Wrong environment: check the health probe before blaming the code.
- Flaky test: run it three times, save the three outputs, and report it as flaky instead of green.
- Missing test data: create it with a fixture, never by editing a shared database by hand.
