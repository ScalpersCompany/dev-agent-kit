#!/usr/bin/env bash
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
usage() {
  echo "usage: $0 <repo> [--with-verify] [--with-gga] [--profile <name>] [--profiles-repo <path>] [--with-techdoc] [--techdoc-path <path>] [--build-techdoc-html]" >&2
  exit 2
}

[ $# -ge 1 ] || usage
REPO="$1"
shift
WITH_VERIFY=0
WITH_GGA=0
WITH_TECHDOC=0
BUILD_TECHDOC_HTML=0
TECHDOC_PATH_ARG="${TECHDOC_PATH:-}"
PROFILE=""
PROFILES_REPO="${DEV_AGENT_PROFILES:-$HOME/dev-agent-profiles}"
while [ $# -gt 0 ]; do
  case "$1" in
    --with-verify) WITH_VERIFY=1 ;;
    --with-gga) WITH_GGA=1 ;;
    --profile) [ $# -ge 2 ] || usage; PROFILE="$2"; shift ;;
    --profiles-repo) [ $# -ge 2 ] || usage; PROFILES_REPO="$2"; shift ;;
    --with-techdoc) WITH_TECHDOC=1 ;;
    --techdoc-path) [ $# -ge 2 ] || usage; TECHDOC_PATH_ARG="$2"; shift ;;
    --build-techdoc-html) WITH_TECHDOC=1; BUILD_TECHDOC_HTML=1 ;;
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

for item in AGENTS.md skills commands agents verify guard evals scripts docs profiles e2e; do
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
  GGA_ARGS=("$REPO")
  [ -n "$PROFILE" ] && GGA_ARGS+=(--profile "$PROFILES_REPO/profiles/$PROFILE")
  bash "$KIT/scripts/install-gga.sh" "${GGA_ARGS[@]}"
fi

if [ -n "$PROFILE" ]; then
  PROFILE_DIR="$PROFILES_REPO/profiles/$PROFILE"
  [ -d "$PROFILE_DIR" ] || {
    echo "profile not found: $PROFILE_DIR" >&2
    echo "clone dev-agent-profiles or pass --profiles-repo" >&2
    exit 2
  }
  mkdir -p "$REPO/.dev-agent/profiles"
  if [ -d "$REPO/.dev-agent/profiles/$PROFILE" ]; then
    cp -a "$REPO/.dev-agent/profiles/$PROFILE" "$REPO/.dev-agent/profiles/$PROFILE.bak-$STAMP"
    echo "backup: $REPO/.dev-agent/profiles/$PROFILE.bak-$STAMP"
  fi
  rsync -a --exclude='verify/config.env' "$PROFILE_DIR/" "$REPO/.dev-agent/profiles/$PROFILE/"
  if [ -f "$REPO/.dev-agent/config" ]; then
    cp -a "$REPO/.dev-agent/config" "$REPO/.dev-agent/config.bak-$STAMP"
    echo "backup: $REPO/.dev-agent/config.bak-$STAMP"
  fi
  printf 'DEV_AGENT_PROFILE=%s\n' "$PROFILE" >"$REPO/.dev-agent/config"
  EXCLUDE="$REPO/.git/info/exclude"
  touch "$EXCLUDE"
  if ! grep -qxF '.dev-agent/' "$EXCLUDE"; then
    printf '%s\n' '.dev-agent/' >>"$EXCLUDE"
  fi
  echo "profile: $PROFILE installed in $REPO/.dev-agent/profiles/$PROFILE"
fi

if [ "$WITH_TECHDOC" = "1" ]; then
  TECHDOC_ARGS=("$REPO")
  [ -n "$TECHDOC_PATH_ARG" ] && TECHDOC_ARGS+=(--techdoc-path "$TECHDOC_PATH_ARG")
  [ "$BUILD_TECHDOC_HTML" = "1" ] && TECHDOC_ARGS+=(--build-html)
  if ! bash "$KIT/scripts/install-techdoc.sh" "${TECHDOC_ARGS[@]}"; then
    echo "techdoc: omitido; el kit sigue instalado sin la referencia" >&2
  fi
fi

echo
echo "next: edit verify/config.env, run bash verify/run.sh, then bash guard/guard.sh"
echo "agents: gentle-ai sync or scripts/install-to-editors.sh for a specific skill"
echo "profiles: see docs/PERFILES-EN-REPOS.md; install.sh is the complete installer; bootstrap --profile installs one; dev-agent init is still pending"
