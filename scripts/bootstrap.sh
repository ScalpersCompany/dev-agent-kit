#!/usr/bin/env bash
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
usage() {
  echo "usage: $0 <repo> [--with-verify] [--with-gga]" >&2
  exit 2
}

[ $# -ge 1 ] || usage
REPO="$1"
shift
WITH_VERIFY=0
WITH_GGA=0
while [ $# -gt 0 ]; do
  case "$1" in
    --with-verify) WITH_VERIFY=1 ;;
    --with-gga) WITH_GGA=1 ;;
    *) usage ;;
  esac
  shift
done

REPO="$(cd "$REPO" && pwd)"
git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1 || {
  echo "not a git repository: $REPO" >&2
  exit 2
}

STAMP="$(date +%Y%m%d-%H%M%S)"
backup() {
  local path="$1"
  if [ -e "$path" ]; then
    cp -a "$path" "$path.bak-$STAMP"
    echo "backup: $path.bak-$STAMP"
  fi
}

for item in AGENTS.md skills commands agents verify guard evals scripts docs profiles; do
  backup "$REPO/$item"
  if [ -d "$KIT/$item" ]; then
    mkdir -p "$REPO/$item"
    rsync -a --exclude='__pycache__' --exclude='runs' --exclude='config.env' "$KIT/$item/" "$REPO/$item/"
  else
    cp -a "$KIT/$item" "$REPO/$item"
  fi
  echo "installed: $REPO/$item"
done

if [ ! -f "$REPO/verify/config.env" ]; then
  cp "$KIT/verify/config.env.example" "$REPO/verify/config.env"
  echo "created: $REPO/verify/config.env (fill TEST_CMD before verify)"
fi

if [ "$WITH_VERIFY" = "1" ]; then
  bash "$KIT/scripts/install-hooks.sh" "$REPO" --with-verify
else
  bash "$KIT/scripts/install-hooks.sh" "$REPO"
fi

if [ "$WITH_GGA" = "1" ]; then
  bash "$KIT/scripts/install-gga.sh" "$REPO"
fi

echo
echo "next: edit verify/config.env, run bash verify/run.sh, then bash guard/guard.sh"
echo "agents: gentle-ai sync or scripts/install-to-editors.sh for a specific skill"
echo "profiles: see docs/PERFILES-EN-REPOS.md; the profile installer is not wired yet"
