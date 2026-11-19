#!/usr/bin/env bash
set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="$(cd "${1:-.}" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

for name in .gga .gga-rules.md; do
  if [ -f "$REPO/$name" ]; then
    cp -a "$REPO/$name" "$REPO/$name.bak-$STAMP"
    echo "backup: $REPO/$name.bak-$STAMP"
  fi
done

cp "$KIT/gga/project.gga.example" "$REPO/.gga"
cp "$KIT/gga/REVIEW-RULES.md" "$REPO/.gga-rules.md"
echo "installed: $REPO/.gga"
echo "installed: $REPO/.gga-rules.md"
echo "edit PROVIDER in .gga: claude, opencode, codex, ollama:<model>, gemini..."
echo "run: $KIT/scripts/review-gga.sh $REPO"
echo "do not run 'gga install': it would replace the kit pre-commit hook"
