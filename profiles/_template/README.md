# Profile template

Copy this directory to `profiles/<name>`, fill `profile.env` and replace the
placeholders in `AGENTS.fragment.md` and `verify/config.env.example`.

The core reads only `profile.env`; it does not know the language. Put the
language-specific guard checks in `guard/`, the runtime commands in
`verify/config.env.example`, the skills in `skills/` and the eval cases in
`evals/cases/`.

Do not add a second copy of the generic skills. The core already ships
`dev-verify`, `repro-first`, `review-diff`, `correct` and `query-readonly`.
