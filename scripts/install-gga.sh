#!/usr/bin/env bash
set -uo pipefail

usage() {
  cat >&2 <<'EOF'
usage: install-gga.sh <repo> [--profile <profile-dir>] [--provider <name>] [--with-pre-push]

Copies the DevAgentKit GGA rules and the example config into the repository.
Existing .gga and .gga-rules.md are backed up; nothing is deleted.
The provider is only written to .gga; credentials stay in the agent environment.
EOF
  exit 2
}

[ $# -ge 1 ] || usage
REPO_ARG="$1"
shift
PROFILE=""
PROVIDER=""
WITH_PRE_PUSH=0

while [ $# -gt 0 ]; do
  case "$1" in
    --profile) [ $# -ge 2 ] || usage; PROFILE="$2"; shift 2 ;;
    --provider) [ $# -ge 2 ] || usage; PROVIDER="$2"; shift 2 ;;
    --with-pre-push) WITH_PRE_PUSH=1; shift ;;
    -h|--help) usage ;;
    *) usage ;;
  esac
done

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="$(cd "$REPO_ARG" && pwd)" || exit 2
STAMP="$(date +%Y%m%d-%H%M%S)"

for name in .gga .gga-rules.md; do
  if [ -f "$REPO/$name" ]; then
    cp -a "$REPO/$name" "$REPO/$name.bak-$STAMP"
    echo "backup: $REPO/$name.bak-$STAMP"
  fi
done

cp "$KIT/gga/project.gga.example" "$REPO/.gga"
cp "$KIT/gga/REVIEW-RULES.md" "$REPO/.gga-rules.md"

if [ -n "$PROVIDER" ]; then
  sed -i "s/^PROVIDER=.*/PROVIDER=$PROVIDER/" "$REPO/.gga"
fi

if [ -n "$PROFILE" ]; then
  PROFILE="$(cd "$PROFILE" && pwd)" || {
    echo "profile not found: $PROFILE" >&2
    exit 2
  }
  if [ -f "$PROFILE/AGENTS.fragment.md" ]; then
    printf '\n## Active profile: %s\n\n' "$(basename "$PROFILE")" >>"$REPO/.gga-rules.md"
    cat "$PROFILE/AGENTS.fragment.md" >>"$REPO/.gga-rules.md"
    printf '\n' >>"$REPO/.gga-rules.md"
    echo "appended profile rules: $PROFILE/AGENTS.fragment.md"
  else
    echo "profile has no AGENTS.fragment.md: $PROFILE" >&2
    exit 2
  fi
fi

echo "installed: $REPO/.gga"
echo "installed: $REPO/.gga-rules.md"
echo "provider: $(sed -n 's/^PROVIDER=//p' "$REPO/.gga" | head -1)"
echo "run: $KIT/scripts/review-gga.sh $REPO --blocking --pr-mode --diff-only"
if [ "$WITH_PRE_PUSH" = "1" ]; then
  bash "$KIT/scripts/install-hooks.sh" "$REPO" --with-verify
  mkdir -p "$REPO/.dev-agent"
  printf 'GGA_PRE_PUSH=1\nGGA_PRE_PUSH_OPTS="--pr-mode --diff-only"\n' >"$REPO/.dev-agent/gga.env"
  echo "pre-push: GGA blocking enabled in $REPO/.dev-agent/gga.env"
fi
echo "do not run 'gga install': it would replace the kit pre-commit hook"
