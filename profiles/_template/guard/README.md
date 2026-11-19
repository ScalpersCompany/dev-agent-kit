# Profile guard

Each executable `.sh` in this directory is a check. The core `guard/guard.sh` runs them
after its generic checks and reports one line per check.

## Contract

- Read the target root from `GUARD_ROOT`; fall back to a path relative to the script only
  when run manually.
- Accept `--staged` and scan only the staged files when it is present.
- Exit 0 when nothing is wrong, exit 1 with a short finding when there is a defect.
- Do not mutate the repository, do not use the network, do not print secrets.
- No prose comments; a legal header and tool directives are allowed.

## Skeleton

```bash
#!/usr/bin/env bash
set -uo pipefail
ROOT="${GUARD_ROOT:-$(pwd)}"
if [ "${1:-}" = "--staged" ]; then
  mapfile -d '' FILES < <(git -C "$ROOT" diff --cached --name-only -z --diff-filter=ACMR -- '*.php')
  [ ${#FILES[@]} -eq 0 ] && exit 0
fi
# run the language tool against "$ROOT" or "${FILES[@]}"
```

Remove the `#` lines before using the skeleton. A check that always exits 0 is not a check;
do not add it.
