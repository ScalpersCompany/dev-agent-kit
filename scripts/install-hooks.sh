#!/usr/bin/env bash
# Install the local dev-agent-kit hooks into a repository.
# Usage: scripts/install-hooks.sh <repo> [--with-verify]
# Existing hooks are backed up as <name>.bak-<timestamp>; nothing is deleted.
set -euo pipefail

usage() {
  echo "usage: $0 <repo> [--with-verify]" >&2
  exit 2
}

[ $# -ge 1 ] || usage
REPO_ARG="$1"
shift
WITH_VERIFY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --with-verify) WITH_VERIFY=1 ;;
    *) usage ;;
  esac
  shift
done

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="$(cd "$REPO_ARG" && pwd)"
git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1 || {
  echo "not a git repository: $REPO" >&2
  exit 2
}

GIT_DIR="$(cd "$REPO" && cd "$(git rev-parse --git-dir)" && pwd)"
HOOKS="$GIT_DIR/hooks"
mkdir -p "$HOOKS"
STAMP="$(date +%Y%m%d-%H%M%S)"

install_hook() {
  local name="$1" src="$2"
  if [ -f "$HOOKS/$name" ]; then
    cp -a "$HOOKS/$name" "$HOOKS/$name.bak-$STAMP"
    echo "backup: $HOOKS/$name.bak-$STAMP"
  fi
  cp "$src" "$HOOKS/$name"
  chmod +x "$HOOKS/$name"
  echo "installed: $HOOKS/$name"
}

install_hook pre-commit "$KIT/hooks/pre-commit"
echo "pre-commit runs: guard --staged (fast, deterministic, local)"

if [ "$WITH_VERIFY" = "1" ]; then
  install_hook pre-push "$KIT/hooks/pre-push"
  mkdir -p "$REPO/.dev-agent"
  if [ ! -f "$REPO/.dev-agent/verify.env" ]; then
    cp "$KIT/verify/config.env.example" "$REPO/.dev-agent/verify.env"
    echo "created: $REPO/.dev-agent/verify.env (edit TEST_CMD or E2E_CMD before pushing)"
  else
    echo "kept: $REPO/.dev-agent/verify.env"
  fi
  EXCLUDE="$GIT_DIR/info/exclude"
  touch "$EXCLUDE"
  if ! grep -qxF '.dev-agent/' "$EXCLUDE"; then
    printf '\n# dev-agent-kit local verify config\n.dev-agent/\n' >>"$EXCLUDE"
    echo "excluded locally: .dev-agent/"
  fi
  echo "pre-push runs: verify/run.sh, evidence in $GIT_DIR/dev-agent-evidence"
  echo "It fails closed until .dev-agent/verify.env has a real TEST_CMD or E2E_CMD."
fi

echo "done; git --no-verify bypasses either hook, so CI remains the hard gate"
