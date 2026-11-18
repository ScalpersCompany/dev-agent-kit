#!/usr/bin/env bash
# Boot the app, exercise it, run tests and leave evidence.
# Exit 0 = all configured checks passed. Exit 2 = nothing configured.
set -uo pipefail

ROOT="${VERIFY_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ROOT="$(cd "$ROOT" && pwd)" || exit 2
cd "$ROOT" || exit 2

CONFIG="${VERIFY_CONFIG:-$ROOT/verify/config.env}"
if [ -f "$CONFIG" ]; then
  # shellcheck disable=SC1090
  . "$CONFIG"
fi

BOOT_CMD="${BOOT_CMD:-}"
HEALTH_URL="${HEALTH_URL:-}"
SMOKE_CMD="${SMOKE_CMD:-}"
TEST_CMD="${TEST_CMD:-}"
HEALTH_TIMEOUT="${HEALTH_TIMEOUT:-60}"

if [ -z "$SMOKE_CMD" ] && [ -z "$TEST_CMD" ]; then
  echo "verify: no SMOKE_CMD or TEST_CMD configured in verify/config.env" >&2
  exit 2
fi

RUN_ID="$(date +%Y%m%dT%H%M%S)"
if git rev-parse --short HEAD >/dev/null 2>&1; then
  RUN_ID="${RUN_ID}-$(git rev-parse --short HEAD)"
fi
EVIDENCE="${VERIFY_EVIDENCE:-$ROOT/evidence}/$RUN_ID"
mkdir -p "$EVIDENCE"

STATUS=0
BOOT_STATUS="skipped"
HEALTH_STATUS="skipped"
SMOKE_STATUS="skipped"
TEST_STATUS="skipped"
BOOT_PID=""

cleanup() {
  if [ -n "$BOOT_PID" ] && kill -0 "$BOOT_PID" 2>/dev/null; then
    if command -v pkill >/dev/null 2>&1; then
      pkill -P "$BOOT_PID" 2>/dev/null || true
    fi
    kill "$BOOT_PID" 2>/dev/null || true
    wait "$BOOT_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

if [ -n "$BOOT_CMD" ]; then
  echo "verify: booting"
  bash -lc "$BOOT_CMD" >"$EVIDENCE/boot.log" 2>&1 &
  BOOT_PID=$!
  echo "$BOOT_PID" >"$EVIDENCE/boot.pid"
  BOOT_STATUS="started"
fi

if [ -n "$HEALTH_URL" ]; then
  echo "verify: waiting for $HEALTH_URL"
  DEADLINE=$((SECONDS + HEALTH_TIMEOUT))
  HEALTH_STATUS="fail"
  while [ $SECONDS -lt $DEADLINE ]; do
    CODE="$(curl -sS -o /dev/null -w '%{http_code}' -m 3 "$HEALTH_URL" 2>/dev/null || true)"
    echo "$(date -u +%FT%TZ) $CODE" >>"$EVIDENCE/health.log"
    if [ "$CODE" = "200" ] || [ "$CODE" = "204" ]; then
      HEALTH_STATUS="pass"
      break
    fi
    sleep 2
  done
  if [ "$HEALTH_STATUS" != "pass" ]; then STATUS=1; fi
fi

run_check() {
  local name="$1" cmd="$2" out="$3" status_var="$4"
  if [ -z "$cmd" ]; then return; fi
  echo "verify: $name"
  bash -lc "$cmd" >"$EVIDENCE/$out.log" 2>&1
  local code=$?
  echo "$code" >"$EVIDENCE/$out.exit"
  if [ $code -ne 0 ]; then
    eval "$status_var=fail"
    STATUS=1
  else
    eval "$status_var=pass"
  fi
}

run_check "smoke" "$SMOKE_CMD" "smoke" "SMOKE_STATUS"
run_check "tests" "$TEST_CMD" "tests" "TEST_STATUS"

cat >"$EVIDENCE/summary.json" <<JSON
{
  "run_id": "$RUN_ID",
  "sha": "$(git rev-parse --verify HEAD 2>/dev/null || echo "")",
  "boot": "$BOOT_STATUS",
  "health": "$HEALTH_STATUS",
  "smoke": "$SMOKE_STATUS",
  "tests": "$TEST_STATUS",
  "status": $( [ $STATUS -eq 0 ] && echo '"pass"' || echo '"fail"' )
}
JSON

echo "verify: evidence in $EVIDENCE"
cat "$EVIDENCE/summary.json"
exit $STATUS
