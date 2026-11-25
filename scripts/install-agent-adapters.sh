#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
usage() {
  echo "usage: $0 <repo> [--agents opencode,claude] [--profile <profile-dir>]" >&2
  exit 2
}

[ $# -ge 1 ] || usage
TARGET="$1"
shift
AGENTS="opencode,claude"
PROFILE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --agents) [ $# -ge 2 ] || usage; AGENTS="$2"; shift 2 ;;
    --profile) [ $# -ge 2 ] || usage; PROFILE="$2"; shift 2 ;;
    *) usage ;;
  esac
done
[ -d "$TARGET" ] || { echo "not a directory: $TARGET" >&2; exit 2; }
if [ -n "$PROFILE" ] && [ ! -d "$PROFILE" ]; then
  echo "profile is not a directory: $PROFILE" >&2
  exit 2
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
copy_tree() {
  local src="$1" dest="$2"
  [ -e "$src" ] || { echo "missing source: $src" >&2; exit 2; }
  if [ -e "$dest" ]; then
    cp -a "$dest" "$dest.bak-$STAMP"
    echo "backup: $dest.bak-$STAMP"
  fi
  mkdir -p "$dest"
  rsync -a --exclude='__pycache__' "$src/" "$dest/"
  echo "installed: $dest"
}
copy_file() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ]; then
    cp -a "$dest" "$dest.bak-$STAMP"
    echo "backup: $dest.bak-$STAMP"
  fi
  cp -a "$src" "$dest"
  echo "installed: $dest"
}
merge_tree() {
  local src="$1" dest="$2"
  mkdir -p "$dest"
  rsync -a --exclude='__pycache__' "$src/" "$dest/"
  echo "merged: $dest"
}

IFS=',' read -r -a LIST <<< "$AGENTS"
for agent in "${LIST[@]}"; do
  case "$agent" in
    opencode)
      copy_tree "$ROOT/skills" "$TARGET/.opencode/skills"
      copy_tree "$ROOT/commands" "$TARGET/.opencode/commands"
      copy_file "$ROOT/agents/judge.md" "$TARGET/.opencode/agent/judge.md"
      if [ -n "$PROFILE" ] && [ -d "$PROFILE/skills" ]; then
        merge_tree "$PROFILE/skills" "$TARGET/.opencode/skills"
      fi
      ;;
    claude)
      copy_tree "$ROOT/skills" "$TARGET/.claude/skills"
      copy_tree "$ROOT/commands" "$TARGET/.claude/commands"
      if [ -n "$PROFILE" ] && [ -d "$PROFILE/skills" ]; then
        merge_tree "$PROFILE/skills" "$TARGET/.claude/skills"
      fi
      ;;
    *)
      echo "unknown agent: $agent" >&2
      exit 2
      ;;
  esac
done
echo "neutral source stays in skills/, commands/ and agents/; the kit's own .gitignore ignores the generated adapter dirs, but the target repo must exclude or commit them intentionally"
