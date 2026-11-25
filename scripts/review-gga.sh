#!/usr/bin/env bash
set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="$(cd "${1:-$(pwd)}" && pwd)" || exit 2
shift || true

MODE="blocking"
if [ "${GGA_ADVISORY:-0}" = "1" ]; then
  MODE="advisory"
fi

ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --advisory) MODE="advisory"; shift ;;
    --blocking) MODE="blocking"; shift ;;
    --help|-h)
      cat >&2 <<'EOF'
usage: review-gga.sh [repo] [--blocking|--advisory] [gga run options]

Default is blocking: the review must return STATUS: PASSED and exit 0.
GGA_ADVISORY=1 or --advisory keeps the report but exits 0.
Pass-through options: --no-cache, --ci, --pr-mode, --diff-only.
EOF
      exit 2
      ;;
    --) shift; while [ $# -gt 0 ]; do ARGS+=("$1"); shift; done ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

cd "$REPO" || exit 2

if ! command -v gga >/dev/null 2>&1; then
  if [ "$MODE" = "blocking" ]; then
    echo "gga: not installed; blocking review cannot run (not a pass)" >&2
    exit 2
  fi
  echo "gga: not installed; advisory review skipped (not a pass)" >&2
  exit 0
fi

if [ ! -f .gga ]; then
  if [ "$MODE" = "blocking" ]; then
    echo "gga: no .gga in $REPO; run $KIT/scripts/install-gga.sh $REPO" >&2
    exit 2
  fi
  echo "gga: no .gga in $REPO; advisory review skipped" >&2
  exit 0
fi

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

gga run "${ARGS[@]}" 2>&1 | tee "$TMP"
CODE=${PIPESTATUS[0]}
STATUS="$(tr -d '\r' <"$TMP" | grep -m1 -E '^STATUS: (PASSED|FAILED)[[:space:]]*$' | sed 's/^STATUS:[[:space:]]*//')"

if [ "$MODE" = "advisory" ]; then
  echo "gga: advisory review finished; the deterministic gate is still guard/verify" >&2
  exit 0
fi

if [ "$CODE" -ne 0 ] || [ "$STATUS" != "PASSED" ]; then
  echo "gga: blocking review failed (status=${STATUS:-missing}, exit=$CODE)" >&2
  exit 1
fi

echo "gga: blocking review passed"
exit 0
