# Agent quality: the method in one page

## The problem

An agent writes code fast and verifies it badly. If the only verifier is a human reading diffs, the human is the bottleneck and the codebase degrades in silence.

## The four layers, strongest first

| Layer | What it is | Can the agent skip it |
|---|---|---|
| 1. Code and architecture | API design, structure, one feature per directory | No, the structure prevents it |
| 2. Static analysis | Types, lint, compiler, dependency boundaries, tests | No, CI goes red |
| 3. Verification | Run the app, exercise it, capture evidence; formal checks where needed | No, the gate is real |
| 4. Prose | AGENTS.md, skills, rules, style guides | Yes, always |

Invest top down. A new rule in prose is the last resort, not the first.

## The three loops

1. **Inner loop (verification).** The agent runs `verify/run.sh`, reads the evidence, fixes the first failure, repeats. It does not report done without an artifact.
2. **Training loop (evals).** A rubric, K runs in neutral, isolated directories, a judge from a different model that sees the output and the artifacts, and a weighted score computed by the harness. If the score is low, the skill changes and the eval runs again. This is the only way a skill earns trust.
3. **Outer loop (signals).** Tickets, failed CI, logs and reports enter one queue. A coordinator groups them and delegates with a WIP cap. Nothing spawns one agent per signal.

## The correction rule

Every time you correct the agent, ask: how do I make this impossible or automatic?

Order: architecture, types, lint, CI, test, documentation. If the same correction appears twice, it becomes a mechanism the third time.

## Autonomy levels

| Level | Meaning | Promotion |
|---|---|---|
| L0 | Human does, agent watches | - |
| L1 | Agent proposes, human verifies each step | - |
| L2 | Agent verifies with `verify/run.sh`, human samples | 10 green changes |
| L3 | Agent merges reversible changes when the gate is green | 30 green changes, 0 reverts, 2 weeks |

One revert drops the repo one level. Production, migrations, secrets and customer data stay at L0 forever.

## Metrics

- Revert rate: reverts / merged changes. Target under 1%.
- Escaped defects: bugs in production per release.
- Time to merge.
- Share of tokens spent on verification. It should be the largest line.
- Rules in prose with no mechanism. Target zero.
