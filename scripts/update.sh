#!/usr/bin/env bash
set -euo pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
KIT="${DEV_AGENT_KIT:-$(cd "$(dirname "$SELF")/.." && pwd)}"
PROFILES_REPO="${DEV_AGENT_PROFILES:-$HOME/dev-agent-profiles}"
TARGET=""
DO_CORE=0
DO_PROFILES=0
CHECK_ONLY=0
ASSUME_YES=0
STAMP="$(date +%Y%m%d-%H%M%S)"

usage() {
  local code="${1:-2}"
  cat >&2 <<'EOF'
usage: dev-agent update [options]

Actualiza el núcleo y/o los perfiles desde su remoto configurado. No hace merge
forzado, no descarta cambios y no actualiza un repo con cambios locales.

  --core                 instala la actualización del kit (repo del wrapper)
  --profiles             actualiza dev-agent-profiles
  --target <repo>        sincroniza las copias .dev-agent/profiles del repo
  --check                muestra si hay actualización, sin aplicarla
  --yes                  no pide confirmación
  -h, --help             esta ayuda

Sin --core ni --profiles actualiza ambos. El remoto y la rama se leen de la
configuración git del repo; si no hay upstream, usa origin/<rama>.
EOF
  exit "$code"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --core) DO_CORE=1; shift ;;
    --profiles) DO_PROFILES=1; shift ;;
    --target) [ $# -ge 2 ] || usage; TARGET="$2"; shift 2 ;;
    --check) CHECK_ONLY=1; shift ;;
    --yes|-y) ASSUME_YES=1; shift ;;
    -h|--help) usage 0 ;;
    *) echo "opción desconocida: $1" >&2; usage ;;
  esac
done
if [ "$DO_CORE" = 0 ] && [ "$DO_PROFILES" = 0 ]; then
  DO_CORE=1
  DO_PROFILES=1
fi
if [ -n "$TARGET" ]; then
  TARGET="${TARGET/#\~/$HOME}"
  [ -d "$TARGET" ] || { echo "no existe el repo: $TARGET" >&2; exit 2; }
  TARGET="$(cd "$TARGET" && pwd)"
fi

die() { echo "update: $*" >&2; exit 1; }
info() { echo "update: $*"; }

git_dir() {
  [ -d "$1/.git" ] || [ -f "$1/.git" ] || die "$1 no es un repositorio git"
  git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "$1 no es un repositorio git"
}

tracked_changes() {
  git -C "$1" status --porcelain --untracked-files=no
}

upstream_ref() {
  local dir="$1" branch remote merge
  branch="$(git -C "$dir" symbolic-ref --short HEAD 2>/dev/null || true)"
  [ -n "$branch" ] || die "$dir está en HEAD detached; no actualizo"
  remote="$(git -C "$dir" config --get "branch.$branch.remote" || true)"
  merge="$(git -C "$dir" config --get "branch.$branch.merge" || true)"
  if [ -n "$remote" ] && [ -n "$merge" ]; then
    printf '%s/%s\n' "$remote" "${merge#refs/heads/}"
    return
  fi
  printf 'origin/%s\n' "$branch"
}

update_repo() {
  local label="$1" dir="$2" upstream remote behind ahead tag
  git_dir "$dir"
  local changes
  changes="$(tracked_changes "$dir")"
  if [ -n "$changes" ]; then
    echo "$changes" >&2
    die "$label tiene cambios locales en tracked; commitéalos o guárdalos antes de actualizar"
  fi
  upstream="$(upstream_ref "$dir")"
  remote="${upstream%%/*}"
  if ! git -C "$dir" remote get-url "$remote" >/dev/null 2>&1; then
    die "$label no tiene el remoto '$remote' configurado"
  fi
  info "$label: git fetch $remote"
  git -C "$dir" fetch --prune "$remote" || die "no se pudo actualizar $label desde $remote"
  git -C "$dir" rev-parse --verify --quiet "$upstream" >/dev/null || die "$label no tiene $upstream"
  behind="$(git -C "$dir" rev-list --count "HEAD..$upstream")"
  ahead="$(git -C "$dir" rev-list --count "$upstream..HEAD")"
  info "$label: $(git -C "$dir" symbolic-ref --short HEAD) · $ahead delante, $behind detrás de $upstream"
  if [ "$behind" -eq 0 ]; then
    info "$label: al día"
    return
  fi
  if [ "$CHECK_ONLY" = 1 ]; then
    info "$label: hay $behind commit(s) por aplicar (--check)"
    return
  fi
  if [ "$ahead" -gt 0 ]; then
    die "$label ha divergido de $upstream; no hago merge. Revisa y resuelve a mano"
  fi
  if [ "$ASSUME_YES" = 0 ]; then
    printf 'Aplicar %s commit(s) a %s? [s/N]: ' "$behind" "$label"
    read -r answer
    case "$answer" in s|S|si|sí) ;; *) info "$label: omitido"; return ;; esac
  fi
  tag="dev-agent-update-backup-$STAMP-$label"
  if git -C "$dir" rev-parse --verify HEAD >/dev/null 2>&1; then
    git -C "$dir" tag -f "$tag" HEAD >/dev/null 2>&1 || true
    info "$label: backup local $tag"
  fi
  git -C "$dir" merge --ff-only "$upstream" || die "$label: merge --ff-only falló"
  info "$label: actualizado a $(git -C "$dir" rev-parse --short HEAD)"
}

sync_target_profiles() {
  local target="$1" name src dst active
  [ -d "$target/.dev-agent/profiles" ] || {
    info "target: $target no tiene .dev-agent/profiles; no sincronizo perfiles"
    return
  }
  for dst in "$target"/.dev-agent/profiles/*; do
    [ -f "$dst/profile.json" ] || continue
    name="$(basename "$dst")"
    src="$PROFILES_REPO/profiles/$name"
    if [ ! -f "$src/profile.json" ]; then
      info "target: el perfil $name ya no existe en dev-agent-profiles; se conserva"
      continue
    fi
    if [ "$CHECK_ONLY" = 1 ]; then
      info "target: $name se actualizaría desde $src"
      continue
    fi
    cp -a "$dst" "$dst.bak-$STAMP"
    rsync -a --delete --exclude 'verify/config.env' "$src/" "$dst/"
    info "target: $name actualizado (backup $dst.bak-$STAMP)"
  done
  active="$(sed -n 's/^DEV_AGENT_PROFILE=//p' "$target/.dev-agent/config" 2>/dev/null | head -1 || true)"
  if [ -n "$active" ] && [ ! -f "$target/.dev-agent/profiles/$active/profile.json" ]; then
    info "target: el perfil activo '$active' no está instalado; revisa .dev-agent/config"
  fi
  if [ "$CHECK_ONLY" = 0 ]; then
    python3 - "$target" "$PROFILES_REPO" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

target = Path(sys.argv[1])
repo = Path(sys.argv[2])
lock = target / ".dev-agent" / "profiles.lock"
if not lock.exists():
    raise SystemExit(0)
try:
    data = json.loads(lock.read_text(encoding="utf-8"))
except Exception:
    raise SystemExit(0)
commit = subprocess.run(
    ["git", "-C", str(repo), "rev-parse", "HEAD"],
    capture_output=True,
    text=True,
).stdout.strip() or "unknown"
for entry in data.get("profiles", []):
    name = entry.get("name")
    if name and (repo / "profiles" / name / "profile.json").is_file():
        entry["source"] = str(repo / "profiles" / name)
        entry["commit"] = commit
lock.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
PY
    info "target: profiles.lock actualizado"
  fi
}

if [ "$DO_CORE" = 1 ]; then
  update_repo "core" "$KIT"
fi
if [ "$DO_PROFILES" = 1 ]; then
  update_repo "profiles" "$PROFILES_REPO"
  if [ -n "$TARGET" ]; then
    sync_target_profiles "$TARGET"
  fi
fi

info "terminado"
