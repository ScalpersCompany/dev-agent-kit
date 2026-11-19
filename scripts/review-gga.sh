#!/usr/bin/env bash
set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="$(cd "${1:-$(pwd)}" && pwd)"
shift || true

cd "$REPO" || exit 2
if ! command -v gga >/dev/null 2>&1; then
  echo "gga: not installed; skipped (not a pass)"
  exit 0
fi
if [ ! -f .gga ]; then
  echo "gga: no .gga in $REPO; run $KIT/scripts/install-gga.sh $REPO"
  exit 2
fi

if [ "${GGA_ADVISORY:-0}" = "1" ]; then
  gga run "$@" || true
  echo "gga: advisory review finished; the deterministic gate is still guard/verify"
  exit 0
fi

exec gga run "$@"
