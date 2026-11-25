#!/usr/bin/env bash
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
usage() {
  echo "usage: $0 <repo> [--techdoc-path <path>] [--build-html] [--remote <url>]" >&2
  exit 2
}

[ $# -ge 1 ] || usage
TARGET="$1"
shift
TECHDOC="${TECHDOC_PATH:-}"
BUILD_HTML=0
REMOTE="${TECHDOC_REMOTE:-git@github.com:ScalpersCompany/scalpers-tech-doc.git}"
BOOK="${TECHDOC_BOOK:-scalpers-methodology}"

while [ $# -gt 0 ]; do
  case "$1" in
    --techdoc-path) [ $# -ge 2 ] || usage; TECHDOC="$2"; shift 2 ;;
    --build-html) BUILD_HTML=1; shift ;;
    --remote) [ $# -ge 2 ] || usage; REMOTE="$2"; shift 2 ;;
    *) usage ;;
  esac
done

TARGET="$(cd "$TARGET" && pwd)"
git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1 || {
  echo "not a git repository: $TARGET" >&2
  exit 2
}
[ -n "$TECHDOC" ] || TECHDOC="$HOME/odoo-doodba-template/scalpers-tech-doc"
TECHDOC="${TECHDOC/#\~/$HOME}"

if [ ! -d "$TECHDOC/.git" ]; then
  mkdir -p "$(dirname "$TECHDOC")"
  if ! git clone "$REMOTE" "$TECHDOC"; then
    echo "techdoc: no se pudo clonar $REMOTE" >&2
    echo "techdoc: pide acceso al repo o usa --techdoc-path" >&2
    exit 1
  fi
fi

[ -f "$TECHDOC/AGENTS.md" ] || {
  echo "techdoc: falta $TECHDOC/AGENTS.md" >&2
  exit 1
}

STAMP="$(date +%Y%m%d-%H%M%S)"
AGENTS_HOME="${AGENTS_HOME:-$HOME/.agents}"
AGENTS_LINK="$AGENTS_HOME/AGENTS.md"
mkdir -p "$AGENTS_HOME"
if [ -e "$AGENTS_LINK" ] || [ -L "$AGENTS_LINK" ]; then
  CURRENT="$(readlink -f "$AGENTS_LINK" 2>/dev/null || true)"
  WANTED="$(readlink -f "$TECHDOC/AGENTS.md" 2>/dev/null || true)"
  if [ "$CURRENT" != "$WANTED" ]; then
    cp -a "$AGENTS_LINK" "$AGENTS_LINK.bak-$STAMP"
    echo "backup: $AGENTS_LINK.bak-$STAMP"
  fi
fi
ln -sfn "$TECHDOC/AGENTS.md" "$AGENTS_LINK"
echo "linked: $AGENTS_LINK -> $TECHDOC/AGENTS.md"

if [ "$BUILD_HTML" = "1" ]; then
  if [ -d "$TECHDOC/books" ]; then
    if ! make -C "$TECHDOC/books" single-html BOOK="$BOOK"; then
      echo "techdoc: no se pudo construir el HTML; se deja la referencia y el comando" >&2
    fi
  else
    echo "techdoc: no existe $TECHDOC/books; no se construye HTML" >&2
  fi
fi

HTML=""
if [ -d "$TECHDOC/books/$BOOK/build/single-html" ]; then
  HTML="$(find "$TECHDOC/books/$BOOK/build/single-html" -maxdepth 1 -type f -name '*.html' -print 2>/dev/null | sort | tail -1 || true)"
fi

mkdir -p "$TARGET/docs"
DOC="$TARGET/docs/TECHDOC.md"
if [ -f "$DOC" ]; then
  cp -a "$DOC" "$DOC.bak-$STAMP"
  echo "backup: $DOC.bak-$STAMP"
fi
{
  echo "# Tech-doc"
  echo
  echo "Referencia local a la documentación de empresa. El HTML es un artefacto de build:"
  echo "no se copia en este repo y no se versiona."
  echo
  echo "- Repo: \`$TECHDOC\`"
  echo "- Norma canónica: \`~/.agents/AGENTS.md\`"
  echo "- Libro: \`$BOOK\`"
  echo "- Build: \`cd $TECHDOC/books && make single-html BOOK=$BOOK\`"
  if [ -n "$HTML" ]; then
    echo "- HTML: \`$HTML\`"
    echo "- Enlace local: \`docs/techdoc.html\`"
  else
    echo "- HTML: pendiente; ejecuta el comando de build"
  fi
  echo
  echo "No copies este HTML en un repo público: contiene documentación privada de la empresa."
} >"$DOC"

if [ -n "$HTML" ]; then
  if [ -e "$TARGET/docs/techdoc.html" ] || [ -L "$TARGET/docs/techdoc.html" ]; then
    cp -a "$TARGET/docs/techdoc.html" "$TARGET/docs/techdoc.html.bak-$STAMP"
    echo "backup: $TARGET/docs/techdoc.html.bak-$STAMP"
  fi
  ln -sfn "$HTML" "$TARGET/docs/techdoc.html"
  echo "linked: $TARGET/docs/techdoc.html -> $HTML"
else
  echo "techdoc: HTML no encontrado; la referencia queda en $DOC"
fi

EXCLUDE="$TARGET/.git/info/exclude"
touch "$EXCLUDE"
for entry in 'docs/TECHDOC.md' 'docs/techdoc.html'; do
  if ! grep -qxF "$entry" "$EXCLUDE"; then
    printf '%s\n' "$entry" >>"$EXCLUDE"
  fi
done

if ! bash "$KIT/scripts/check-techdoc.sh" --path "$TECHDOC" --allow-dirty; then
  echo "techdoc: el check avisa; revisa el estado antes de usarlo como norma" >&2
fi

echo "techdoc: instalado en $TECHDOC"
echo "techdoc: referencia en $DOC"
