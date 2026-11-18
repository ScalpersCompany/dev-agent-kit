#!/usr/bin/env bash
# Deterministic guardrails. Exit 0 = all checks passed or skipped with a reason.
# In a target repository, set GUARD_ROOT to its top level and GUARD_REPORT to a path
# outside the worktree (for example .git/guard-report.json). --staged scans only the
# staged files, so a pre-commit hook does not fail on pre-existing findings.
set -uo pipefail

KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="${GUARD_ROOT:-$KIT_ROOT}"
ROOT="$(cd "$ROOT" && pwd)" || exit 2
cd "$ROOT" || exit 2

STAGED=0
if [ "${1:-}" = "--staged" ]; then STAGED=1; fi

REPORT="${GUARD_REPORT:-$ROOT/guard-report.json}"
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

PY_FILES=()
JS_FILES=()
if [ "$STAGED" = "1" ] && git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  while IFS= read -r -d '' file; do
    case "$file" in
      *.py) PY_FILES+=("$file") ;;
      *.js|*.jsx|*.ts|*.tsx) JS_FILES+=("$file") ;;
    esac
  done < <(git -C "$ROOT" diff --cached --name-only -z --diff-filter=ACMR)
fi

if [ "$STAGED" = "1" ]; then
  if [ ${#PY_FILES[@]} -eq 0 ]; then
    record ruff skipped "no staged Python files"
  elif have ruff && { [ -f pyproject.toml ] || [ -f ruff.toml ] || [ -f .ruff.toml ]; }; then
    if ruff check "${PY_FILES[@]}" >/tmp/guard-ruff.log 2>&1; then record ruff pass; else record ruff fail "$(tail -5 /tmp/guard-ruff.log | tr '\n' ' ')"; fi
  else
    record ruff skipped "not installed or not configured"
  fi
elif have ruff && { [ -f pyproject.toml ] || [ -f ruff.toml ] || [ -f .ruff.toml ]; }; then
  if ruff check . >/tmp/guard-ruff.log 2>&1; then record ruff pass; else record ruff fail "$(tail -5 /tmp/guard-ruff.log | tr '\n' ' ')"; fi
else
  record ruff skipped "not installed or not configured"
fi

if [ "$STAGED" = "1" ]; then
  if [ ${#PY_FILES[@]} -eq 0 ]; then
    record black skipped "no staged Python files"
  elif have black && { [ -f pyproject.toml ] || [ -f .black ]; }; then
    if black --check "${PY_FILES[@]}" >/tmp/guard-black.log 2>&1; then record black pass; else record black fail "$(tail -3 /tmp/guard-black.log | tr '\n' ' ')"; fi
  else
    record black skipped "not installed or not configured"
  fi
elif have black && { [ -f pyproject.toml ] || [ -f .black ]; }; then
  if black --check . >/tmp/guard-black.log 2>&1; then record black pass; else record black fail "$(tail -3 /tmp/guard-black.log | tr '\n' ' ')"; fi
else
  record black skipped "not installed or not configured"
fi

if [ "$STAGED" = "1" ]; then
  if [ ${#PY_FILES[@]} -eq 0 ]; then
    record mypy skipped "no staged Python files"
  elif have mypy && { [ -f mypy.ini ] || [ -f pyproject.toml ]; }; then
    if mypy "${PY_FILES[@]}" >/tmp/guard-mypy.log 2>&1; then record mypy pass; else record mypy fail "$(tail -3 /tmp/guard-mypy.log | tr '\n' ' ')"; fi
  else
    record mypy skipped "not installed or not configured"
  fi
elif have mypy && { [ -f mypy.ini ] || [ -f pyproject.toml ]; }; then
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
  if [ "$STAGED" = "1" ]; then
    if [ ${#JS_FILES[@]} -eq 0 ]; then
      record eslint skipped "no staged JS/TS files"
    elif "$ESLINT_BIN" "${JS_FILES[@]}" >/tmp/guard-eslint.log 2>&1; then
      record eslint pass
    else
      record eslint fail "$(tail -3 /tmp/guard-eslint.log | tr '\n' ' ')"
    fi
  elif "$ESLINT_BIN" . >/tmp/guard-eslint.log 2>&1; then
    record eslint pass
  else
    record eslint fail "$(tail -3 /tmp/guard-eslint.log | tr '\n' ' ')"
  fi
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
  if [ "$STAGED" = "1" ]; then
    if [ ${#JS_FILES[@]} -eq 0 ]; then
      record tsc skipped "no staged JS/TS files"
    elif "$TSC_BIN" --noEmit "${JS_FILES[@]}" >/tmp/guard-tsc.log 2>&1; then
      record tsc pass
    else
      record tsc fail "$(tail -3 /tmp/guard-tsc.log | tr '\n' ' ')"
    fi
  elif "$TSC_BIN" --noEmit >/tmp/guard-tsc.log 2>&1; then
    record tsc pass
  else
    record tsc fail "$(tail -3 /tmp/guard-tsc.log | tr '\n' ' ')"
  fi
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

if have python3 && [ -f "$KIT_ROOT/guard/odoo_lint.py" ]; then
  LINT_ARGS=(--root "$ROOT" --allowlist "$KIT_ROOT/guard/odoo_allowlist.txt")
  if [ "$STAGED" = "1" ]; then
    if [ ${#PY_FILES[@]} -eq 0 ]; then
      record odoo_lint skipped "no staged Python files"
    elif python3 "$KIT_ROOT/guard/odoo_lint.py" "${LINT_ARGS[@]}" --files "${PY_FILES[@]}" >/tmp/guard-odoo.log 2>&1; then
      record odoo_lint pass
    else
      record odoo_lint fail "$(tail -5 /tmp/guard-odoo.log | tr '\n' ' ')"
    fi
  elif python3 "$KIT_ROOT/guard/odoo_lint.py" "${LINT_ARGS[@]}" >/tmp/guard-odoo.log 2>&1; then
    record odoo_lint pass
  else
    record odoo_lint fail "$(tail -5 /tmp/guard-odoo.log | tr '\n' ' ')"
  fi
else
  record odoo_lint skipped "python3 or script missing"
fi

echo
echo "guard: $RAN checks ran, report in $REPORT"
if [ $FAIL -ne 0 ]; then
  echo "guard: FAILED"
  exit 1
fi
echo "guard: passed"
exit 0
