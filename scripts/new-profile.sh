#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
usage() {
  echo "usage: $0 <name> [--language <language>] [--repo <target>] [--description <text>]" >&2
  exit 2
}

[ $# -ge 1 ] || usage
NAME="$1"
shift
LANGUAGE=""
REPO="$(pwd)"
DESCRIPTION=""
while [ $# -gt 0 ]; do
  case "$1" in
    --language) [ $# -ge 2 ] || usage; LANGUAGE="$2"; shift 2 ;;
    --repo) [ $# -ge 2 ] || usage; REPO="$2"; shift 2 ;;
    --description) [ $# -ge 2 ] || usage; DESCRIPTION="$2"; shift 2 ;;
    *) usage ;;
  esac
done

printf '%s' "$NAME" | grep -Eq '^[a-z][a-z0-9-]*$' || {
  echo "invalid name: use lowercase letters, digits and hyphens, starting with a letter" >&2
  exit 2
}
[ -d "$REPO" ] || {
  echo "target is not a directory: $REPO" >&2
  exit 2
}
[ -d "$ROOT/profiles/_template" ] || {
  echo "template not found: $ROOT/profiles/_template" >&2
  exit 2
}

DEST="$REPO/profiles/$NAME"
if [ -e "$DEST" ]; then
  STAMP="$(date +%Y%m%d-%H%M%S)"
  cp -a "$DEST" "$DEST.bak-$STAMP"
  echo "backup: $DEST.bak-$STAMP"
fi
mkdir -p "$(dirname "$DEST")"
cp -a "$ROOT/profiles/_template" "$DEST"

python3 - "$DEST/profile.json" "$NAME" "$LANGUAGE" "$DESCRIPTION" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
name = sys.argv[2]
language = sys.argv[3]
description = sys.argv[4] or f"{name} environment profile"
data = json.loads(path.read_text(encoding="utf-8"))
data["name"] = name
data["language"] = language
data["description"] = description
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY

sed -i "s/_template/$NAME/g" "$DEST/profile.env" "$DEST/README.md"
echo "created: $DEST"
echo "next: fill profile.json, profile.env, AGENTS.fragment.md, gga/REVIEW-RULES.md, guard/*.sh and verify/config.env.example"
echo "validate: python3 $ROOT/scripts/validate-profile.py $DEST"
