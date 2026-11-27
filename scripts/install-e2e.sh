#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: install-e2e.sh <repo> [--install] [--force]

Copies the Playwright harness to <repo>/e2e with a backup of an existing e2e/.
--install runs npm install inside e2e; it needs network and is never implicit.
When e2e/ already exists (for example after install.sh), --install keeps it and only
installs its dependencies; --force is required to replace the harness.
The harness is a baseline, not the complete flow suite: add one spec per user flow.
EOF
  exit 2
}

[ $# -ge 1 ] || usage
TARGET="$1"
shift
INSTALL=0
FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --install) INSTALL=1; shift ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage ;;
    *) usage ;;
  esac
done

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="$(cd "$TARGET" && pwd)" || exit 2
STAMP="$(date +%Y%m%d-%H%M%S)"

if [ -e "$TARGET/e2e" ]; then
  if [ "$FORCE" != "1" ]; then
    if [ "$INSTALL" = "1" ]; then
      echo "e2e/ already exists in $TARGET; keeping it and installing dependencies"
      (cd "$TARGET/e2e" && npm install)
      echo "installed npm dependencies in $TARGET/e2e"
      echo "next: set E2E_BASE_URL and E2E_CMD in verify/config.env"
      exit 0
    fi
    echo "e2e/ already exists in $TARGET; use --force to replace it (a backup is kept)" >&2
    exit 2
  fi
  mv "$TARGET/e2e" "$TARGET/e2e.bak-$STAMP"
  echo "backup: $TARGET/e2e.bak-$STAMP"
fi

mkdir -p "$TARGET/e2e"
rsync -a "$KIT/e2e/" "$TARGET/e2e/"
echo "installed: $TARGET/e2e"
echo "next: add specs in e2e/tests/ and set E2E_BASE_URL and E2E_CMD in verify/config.env"
echo "example: E2E_CMD=\"npm --prefix e2e test\""

if [ "$INSTALL" = "1" ]; then
  (cd "$TARGET/e2e" && npm install)
  echo "installed npm dependencies in $TARGET/e2e"
fi
