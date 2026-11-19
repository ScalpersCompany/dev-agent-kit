#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 [--path <techdoc>] [--allow-dirty] [--branch <branch>] [--commit <sha>] [--require-link]" >&2
  exit 2
}

TECHDOC="${TECHDOC_PATH:-}"
ALLOW_DIRTY=0
EXPECT_BRANCH=""
EXPECT_COMMIT=""
REQUIRE_LINK=0
while [ $# -gt 0 ]; do
  case "$1" in
    --path) [ $# -ge 2 ] || usage; TECHDOC="$2"; shift 2 ;;
    --allow-dirty) ALLOW_DIRTY=1; shift ;;
    --branch) [ $# -ge 2 ] || usage; EXPECT_BRANCH="$2"; shift 2 ;;
    --commit) [ $# -ge 2 ] || usage; EXPECT_COMMIT="$2"; shift 2 ;;
    --require-link) REQUIRE_LINK=1; shift ;;
    *) [ -z "$TECHDOC" ] || usage; TECHDOC="$1"; shift ;;
  esac
done

if [ -z "$TECHDOC" ]; then
  for candidate in \
    "$HOME/odoo-doodba-template/scalpers-tech-doc" \
    "$PWD/scalpers-tech-doc" \
    "$PWD/../scalpers-tech-doc"; do
    if [ -d "$candidate" ]; then TECHDOC="$candidate"; break; fi
  done
fi
[ -n "$TECHDOC" ] && [ -d "$TECHDOC" ] || { echo "techdoc not found; set TECHDOC_PATH or --path" >&2; exit 2; }
git -C "$TECHDOC" rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repository: $TECHDOC" >&2; exit 2; }

REMOTE="$(git -C "$TECHDOC" remote get-url origin 2>/dev/null || true)"
case "$REMOTE" in
  *ScalpersCompany/scalpers-tech-doc*|*scalpers-tech-doc*) ;;
  *) echo "wrong remote: ${REMOTE:-none}" >&2; exit 1 ;;
esac
[ -f "$TECHDOC/AGENTS.md" ] || { echo "missing AGENTS.md in $TECHDOC" >&2; exit 1; }

BRANCH="$(git -C "$TECHDOC" branch --show-current 2>/dev/null || true)"
HEAD="$(git -C "$TECHDOC" rev-parse --short HEAD 2>/dev/null || true)"
DIRTY="$(git -C "$TECHDOC" status --porcelain 2>/dev/null || true)"

if [ -n "$EXPECT_BRANCH" ] && [ "$BRANCH" != "$EXPECT_BRANCH" ]; then
  echo "branch mismatch: expected $EXPECT_BRANCH, got ${BRANCH:-detached}" >&2
  exit 1
fi
if [ -n "$EXPECT_COMMIT" ] && [ "$HEAD" != "$EXPECT_COMMIT" ] && [ "$(git -C "$TECHDOC" rev-parse "$EXPECT_COMMIT" 2>/dev/null || true)" != "$(git -C "$TECHDOC" rev-parse HEAD 2>/dev/null || true)" ]; then
  echo "commit mismatch: expected $EXPECT_COMMIT, got $HEAD" >&2
  exit 1
fi
if [ -n "$DIRTY" ] && [ "$ALLOW_DIRTY" != "1" ]; then
  echo "techdoc is dirty; commit and merge it in the company repo first, or pass --allow-dirty for a local review" >&2
  printf '%s\n' "$DIRTY" | head -10 >&2
  exit 1
fi

LINK="$HOME/.agents/AGENTS.md"
if [ -e "$LINK" ]; then
  LINK_TARGET="$(readlink -f "$LINK" 2>/dev/null || true)"
  AGENTS_TARGET="$(readlink -f "$TECHDOC/AGENTS.md" 2>/dev/null || true)"
  if [ "$LINK_TARGET" != "$AGENTS_TARGET" ]; then
    echo "warning: ~/.agents/AGENTS.md points to $LINK_TARGET, not $AGENTS_TARGET" >&2
    [ "$REQUIRE_LINK" = "1" ] && exit 1
  fi
else
  echo "warning: ~/.agents/AGENTS.md is not linked to the techdoc" >&2
  [ "$REQUIRE_LINK" = "1" ] && exit 1
fi

echo "techdoc: $TECHDOC"
echo "remote: $REMOTE"
echo "branch: ${BRANCH:-detached}"
echo "commit: $HEAD"
echo "dirty: ${DIRTY:+yes}${DIRTY:-no}"
echo "agents: $TECHDOC/AGENTS.md"
