#!/usr/bin/env bash
# Discovery: what the repo is, how it is tested, and what the agent must not touch.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2
OUT="$ROOT/docs/agent-quality/ENVIRONMENT.md"
mkdir -p "$(dirname "$OUT")"

echo "== repo =="
echo "root: $ROOT"
git rev-parse --short HEAD 2>/dev/null || true
echo

echo "== manifests =="
for f in pyproject.toml setup.py requirements.txt package.json pnpm-lock.yaml go.mod __manifest__.py docker-compose.yml compose.yml Makefile; do
  [ -e "$f" ] && echo "found: $f"
done
echo

echo "== tests and quality =="
for f in pytest.ini tox.ini .pre-commit-config.yaml ruff.toml .eslintrc .eslintrc.json eslint.config.js tsconfig.json; do
  [ -e "$f" ] && echo "found: $f"
done
echo

echo "== CI =="
for d in .github/workflows .gitlab-ci.yml .circleci; do
  [ -e "$d" ] && echo "found: $d"
done
echo

echo "== odoo modules =="
find . -name __manifest__.py -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | head -20
echo

echo "== env var names (no values) =="
if [ -f .env.example ]; then
  grep -E "^[A-Za-z_][A-Za-z0-9_]*=" .env.example | cut -d= -f1 | sort -u
fi
echo

if [ ! -f "$OUT" ]; then
  cat >"$OUT" <<'MD'
# Environment

Complete this file by running the commands on a clean checkout. The agent reads it before touching anything.

## Boot

```
TODO: command that starts the app or the disposable database
```

## Health

```
TODO: URL that answers 200 when ready
```

## Tests

```
TODO: command that runs the tests for one module
```

## Lint

```
TODO: formatter, linter, type checker
```

## Database

- Engine:
- Disposable database:
- Production: forbidden.

## One-way doors

- Production deploy:
- Migrations:
- Secrets:
- Customer data:
MD
  echo "wrote $OUT (complete it)"
else
  echo "$OUT already exists"
fi
