#!/usr/bin/env bash
set -uo pipefail

usage() {
  cat >&2 <<'EOF'
usage: install-gga.sh <repo> [--profile <profile-dir>] [--provider <name>] [--with-pre-push]

Copies the DevAgentKit core GGA rules and, when --profile is given, appends that
profile's gga/REVIEW-RULES.md. A profile with only AGENTS.fragment.md is accepted as
a compatibility fallback and reported as such.
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
  PROFILE_NAME="$(basename "$PROFILE")"
  PROFILE_RULES="$PROFILE/gga/REVIEW-RULES.md"
  if [ -f "$PROFILE_RULES" ]; then
    printf '\n## Active profile GGA rules: %s\n\n' "$PROFILE_NAME" >>"$REPO/.gga-rules.md"
    cat "$PROFILE_RULES" >>"$REPO/.gga-rules.md"
    printf '\n' >>"$REPO/.gga-rules.md"
    echo "appended profile GGA rules: $PROFILE_RULES"
  elif [ -f "$PROFILE/AGENTS.fragment.md" ]; then
    echo "warning: $PROFILE_NAME has no gga/REVIEW-RULES.md; using AGENTS.fragment.md" >&2
    printf '\n## Active profile rules: %s\n\n' "$PROFILE_NAME" >>"$REPO/.gga-rules.md"
    cat "$PROFILE/AGENTS.fragment.md" >>"$REPO/.gga-rules.md"
    printf '\n' >>"$REPO/.gga-rules.md"
    echo "appended profile fallback rules: $PROFILE/AGENTS.fragment.md"
  else
    echo "profile has no gga/REVIEW-RULES.md or AGENTS.fragment.md: $PROFILE" >&2
    exit 2
  fi
else
  echo "profile GGA rules: not applied (pass --profile <profile-dir> to install them)"
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
