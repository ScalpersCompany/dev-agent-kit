#!/usr/bin/env bash
# Deterministic guardrails. Exit 0 = all checks passed or skipped with a reason.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2

STAGED=0
if [ "${1:-}" = "--staged" ]; then STAGED=1; fi

REPORT="$ROOT/guard-report.json"
: >"$REPORT"
FAIL=0
RAN=0

record() {
  local name="$1" status="$2" detail="${3:-}"
  python3 - "$name" "$status" "$detail" >>"$REPORT" <<'PY'
import json
import sys
print(json.dumps({"check": sys.argv[1], "status": sys.argv[2], "detail": sys.argv[3]}))
PY
  if [ "$status" = "fail" ]; then FAIL=1; fi
  if [ "$status" != "skipped" ]; then RAN=$((RAN + 1)); fi
  printf '%-12s %-8s %s\n' "$name" "$status" "$detail"
}

have() { command -v "$1" >/dev/null 2>&1; }

if have ruff && { [ -f pyproject.toml ] || [ -f ruff.toml ] || [ -f .ruff.toml ]; }; then
  if ruff check . >/tmp/guard-ruff.log 2>&1; then record ruff pass; else record ruff fail "$(tail -5 /tmp/guard-ruff.log | tr '\n' ' ')"; fi
else
  record ruff skipped "not installed or not configured"
fi

if have black && { [ -f pyproject.toml ] || [ -f .black ]; }; then
  if black --check . >/tmp/guard-black.log 2>&1; then record black pass; else record black fail "$(tail -3 /tmp/guard-black.log | tr '\n' ' ')"; fi
else
  record black skipped "not installed or not configured"
fi

if have mypy && { [ -f mypy.ini ] || [ -f pyproject.toml ]; }; then
  if mypy . >/tmp/guard-mypy.log 2>&1; then record mypy pass; else record mypy fail "$(tail -3 /tmp/guard-mypy.log | tr '\n' ' ')"; fi
else
  record mypy skipped "not installed or not configured"
fi

ESLINT_BIN=""
if [ -x node_modules/.bin/eslint ]; then
  ESLINT_BIN="node_modules/.bin/eslint"
elif have eslint; then
  ESLINT_BIN="eslint"
fi

if [ -f package.json ] && [ -n "$ESLINT_BIN" ]; then
  if "$ESLINT_BIN" . >/tmp/guard-eslint.log 2>&1; then record eslint pass; else record eslint fail "$(tail -3 /tmp/guard-eslint.log | tr '\n' ' ')"; fi
elif [ -f package.json ]; then
  record eslint skipped "eslint not installed"
else
  record eslint skipped "no package.json"
fi

TSC_BIN=""
if [ -x node_modules/.bin/tsc ]; then
  TSC_BIN="node_modules/.bin/tsc"
elif have tsc; then
  TSC_BIN="tsc"
fi

if [ -f tsconfig.json ] && [ -n "$TSC_BIN" ]; then
  if "$TSC_BIN" --noEmit >/tmp/guard-tsc.log 2>&1; then record tsc pass; else record tsc fail "$(tail -3 /tmp/guard-tsc.log | tr '\n' ' ')"; fi
elif [ -f tsconfig.json ]; then
  record tsc skipped "typescript not installed"
else
  record tsc skipped "no tsconfig.json"
fi

if have gitleaks; then
  if [ "$STAGED" = "1" ]; then
    if gitleaks protect --staged --no-banner >/tmp/guard-gitleaks.log 2>&1; then record gitleaks pass; else record gitleaks fail "staged secret"; fi
  else
    if gitleaks detect --no-git --no-banner >/tmp/guard-gitleaks.log 2>&1; then record gitleaks pass; else record gitleaks fail "secret found"; fi
  fi
else
  record gitleaks skipped "not installed"
fi

if have python3 && [ -f guard/odoo_lint.py ]; then
  if python3 guard/odoo_lint.py --root . >/tmp/guard-odoo.log 2>&1; then record odoo_lint pass; else record odoo_lint fail "$(tail -5 /tmp/guard-odoo.log | tr '\n' ' ')"; fi
else
  record odoo_lint skipped "python3 or script missing"
fi

echo
echo "guard: $RAN checks ran, report in guard-report.json"
if [ $FAIL -ne 0 ]; then
  echo "guard: FAILED"
  exit 1
fi
echo "guard: passed"
exit 0
