#!/usr/bin/env bash
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILES_REPO="${DEV_AGENT_PROFILES:-$HOME/dev-agent-profiles}"
TARGET=""
PROFILES=""
ACTIVE=""
AGENTS=""
WITH_CODEGRAPH=""
WITH_ENGRAM=""
WITH_TECHDOC=""
WITH_HTML=0
ASSUME_YES=0

usage() {
  cat >&2 <<'EOF'
usage: ./install.sh [options]

Interactive by default. Options for automation:
  --target <repo>          development repository (default: current directory)
  --profiles <list|all>    profile names, comma separated, or all
  --active <name>          active profile when more than one is installed
  --agents <list|all|none> claude,opencode,codex,pi,hermes
  --with-codegraph         index the repository with CodeGraph
  --no-codegraph           skip CodeGraph
  --with-engram            save the installation in Engram
  --no-engram              skip Engram
  --with-techdoc           clone or link scalpers-tech-doc
  --no-techdoc             skip tech-doc
  --build-techdoc-html     build and link the single HTML
  --yes                    accept defaults, no prompts
EOF
  exit 2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --target) [ $# -ge 2 ] || usage; TARGET="$2"; shift 2 ;;
    --profiles) [ $# -ge 2 ] || usage; PROFILES="$2"; shift 2 ;;
    --active) [ $# -ge 2 ] || usage; ACTIVE="$2"; shift 2 ;;
    --agents) [ $# -ge 2 ] || usage; AGENTS="$2"; shift 2 ;;
    --with-codegraph) WITH_CODEGRAPH=1; shift ;;
    --no-codegraph) WITH_CODEGRAPH=0; shift ;;
    --with-engram) WITH_ENGRAM=1; shift ;;
    --no-engram) WITH_ENGRAM=0; shift ;;
    --with-techdoc) WITH_TECHDOC=1; shift ;;
    --no-techdoc) WITH_TECHDOC=0; WITH_HTML=0; shift ;;
    --build-techdoc-html) WITH_HTML=1; WITH_TECHDOC=1; shift ;;
    --yes) ASSUME_YES=1; shift ;;
    -h|--help) usage ;;
    *) usage ;;
  esac
done

ask_yes() {
  local prompt="$1" default="$2" answer
  if [ "$ASSUME_YES" = "1" ]; then
    [ "$default" = "s" ]
    return
  fi
  printf '%s [%s]: ' "$prompt" "$default"
  read -r answer
  answer="${answer:-$default}"
  [ "$answer" = "s" ] || [ "$answer" = "S" ] || [ "$answer" = "si" ] || [ "$answer" = "sí" ]
}

profile_description() {
  python3 - "$1" <<'PY'
import json, sys
try:
    data = json.load(open(sys.argv[1], encoding="utf-8"))
    print(data.get("description", ""))
except Exception:
    print("")
PY
}

if [ -z "$TARGET" ]; then
  TARGET="$PWD"
  ask_target() {
    printf 'Repo de desarrollo [%s]: ' "$TARGET"
    read -r answer
    [ -n "$answer" ] && TARGET="$answer"
  }
  [ "$ASSUME_YES" = "1" ] || ask_target
fi
TARGET="${TARGET/#\~/$HOME}"
TARGET="$(cd "$TARGET" && pwd)" || { echo "no existe el repo: $TARGET" >&2; exit 2; }
git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1 || {
  echo "no es un repo git: $TARGET" >&2
  exit 2
}
case "$TARGET" in
  /|"$HOME"|"$KIT") echo "destino no permitido: $TARGET" >&2; exit 2 ;;
esac

if [ ! -d "$PROFILES_REPO/profiles" ]; then
  echo "clonando perfiles en $PROFILES_REPO"
  git clone https://github.com/ScalpersCompany/dev-agent-profiles.git "$PROFILES_REPO" || {
    echo "no se pudo clonar dev-agent-profiles" >&2
    exit 1
  }
fi

PROFILE_DIRS=()
PROFILE_NAMES=()
PROFILE_DESCS=()
while IFS= read -r dir; do
  [ -f "$dir/profile.json" ] || continue
  PROFILE_DIRS+=("$dir")
  PROFILE_NAMES+=("$(basename "$dir")")
  PROFILE_DESCS+=("$(profile_description "$dir/profile.json")")
done < <(find "$PROFILES_REPO/profiles" -mindepth 1 -maxdepth 1 -type d | sort)

if [ ${#PROFILE_NAMES[@]} -eq 0 ]; then
  echo "no hay perfiles en $PROFILES_REPO/profiles" >&2
  exit 1
fi

if [ -z "$PROFILES" ]; then
  if [ "$ASSUME_YES" = "1" ]; then
    PROFILES="all"
  else
    echo "Perfiles disponibles:"
    i=1
    for name in "${PROFILE_NAMES[@]}"; do
      printf '  %d) %-12s %s\n' "$i" "$name" "${PROFILE_DESCS[$((i-1))]}"
      i=$((i+1))
    done
    printf '  %d) %s\n' "$i" "todos"
    printf 'Perfil o perfiles (número, nombre, lista o todos) [1]: '
    read -r PROFILES
    PROFILES="${PROFILES:-1}"
  fi
fi

SELECTED=()
add_profile() {
  local name="$1" found=0 existing
  for existing in "${SELECTED[@]:-}"; do
    [ "$existing" = "$name" ] && found=1
  done
  [ "$found" = "1" ] || SELECTED+=("$name")
}
for token in ${PROFILES//,/ }; do
  if [ "$token" = "all" ] || [ "$token" = "todos" ] || [ "$token" = "*" ]; then
    for name in "${PROFILE_NAMES[@]}"; do add_profile "$name"; done
    continue
  fi
  if [[ "$token" =~ ^[0-9]+$ ]]; then
    idx=$((token-1))
    if [ "$idx" -ge 0 ] && [ "$idx" -lt ${#PROFILE_NAMES[@]} ]; then
      add_profile "${PROFILE_NAMES[$idx]}"
      continue
    fi
    if [ "$token" -eq $((${#PROFILE_NAMES[@]}+1)) ]; then
      for name in "${PROFILE_NAMES[@]}"; do add_profile "$name"; done
      continue
    fi
  fi
  found=0
  for name in "${PROFILE_NAMES[@]}"; do
    [ "$token" = "$name" ] && found=1 && add_profile "$name"
  done
  [ "$found" = "1" ] || { echo "perfil desconocido: $token" >&2; exit 2; }
done
[ ${#SELECTED[@]} -gt 0 ] || { echo "no hay perfiles seleccionados" >&2; exit 2; }

if [ -z "$ACTIVE" ]; then
  ACTIVE="${SELECTED[0]}"
  if [ ${#SELECTED[@]} -gt 1 ] && [ "$ASSUME_YES" = "0" ]; then
    printf 'Perfil activo %s [%s]: ' "${SELECTED[*]}" "$ACTIVE"
    read -r answer
    [ -n "$answer" ] && ACTIVE="$answer"
  fi
fi
found=0
for name in "${SELECTED[@]}"; do [ "$name" = "$ACTIVE" ] && found=1; done
[ "$found" = "1" ] || { echo "el perfil activo no está seleccionado: $ACTIVE" >&2; exit 2; }

AGENT_NAMES=(claude opencode codex pi hermes)
if [ -z "$AGENTS" ]; then
  if [ "$ASSUME_YES" = "1" ]; then
    AGENTS="all"
  else
    echo "Agentes:"
    i=1
    for name in "${AGENT_NAMES[@]}"; do printf '  %d) %s\n' "$i" "$name"; i=$((i+1)); done
    printf '  %d) todos\n' "$i"
    printf 'Agentes (número, nombre, lista o todos) [todos]: '
    read -r AGENTS
    AGENTS="${AGENTS:-all}"
  fi
fi

SELECTED_AGENTS=()
add_agent() {
  local name="$1" found=0 existing
  for existing in "${SELECTED_AGENTS[@]:-}"; do [ "$existing" = "$name" ] && found=1; done
  [ "$found" = "1" ] || SELECTED_AGENTS+=("$name")
}
for token in ${AGENTS//,/ }; do
  if [ "$token" = "none" ] || [ "$token" = "ninguno" ]; then
    continue
  fi
  if [ "$token" = "all" ] || [ "$token" = "todos" ] || [ "$token" = "*" ]; then
    for name in "${AGENT_NAMES[@]}"; do add_agent "$name"; done
    continue
  fi
  if [[ "$token" =~ ^[0-9]+$ ]]; then
    idx=$((token-1))
    if [ "$idx" -ge 0 ] && [ "$idx" -lt ${#AGENT_NAMES[@]} ]; then add_agent "${AGENT_NAMES[$idx]}"; continue; fi
    if [ "$token" -eq $((${#AGENT_NAMES[@]}+1)) ]; then for name in "${AGENT_NAMES[@]}"; do add_agent "$name"; done; continue; fi
  fi
  found=0
  for name in "${AGENT_NAMES[@]}"; do [ "$token" = "$name" ] && found=1 && add_agent "$name"; done
  [ "$found" = "1" ] || { echo "agente desconocido: $token" >&2; exit 2; }
done

if [ -z "$WITH_CODEGRAPH" ]; then
  if ask_yes "¿Indexar con CodeGraph?" "s"; then WITH_CODEGRAPH=1; else WITH_CODEGRAPH=0; fi
fi
if [ -z "$WITH_ENGRAM" ]; then
  if ask_yes "¿Guardar la instalación en Engram?" "s"; then WITH_ENGRAM=1; else WITH_ENGRAM=0; fi
fi
if [ -z "$WITH_TECHDOC" ]; then
  if ask_yes "¿Enlazar tech-doc?" "n"; then WITH_TECHDOC=1; else WITH_TECHDOC=0; fi
fi
if [ "$WITH_TECHDOC" = "1" ] && [ "$WITH_HTML" = "0" ] && [ "$ASSUME_YES" = "0" ]; then
  if ask_yes "¿Construir HTML de tech-doc?" "n"; then WITH_HTML=1; fi
fi

echo
echo "Destino: $TARGET"
echo "Perfiles: ${SELECTED[*]} (activo: $ACTIVE)"
echo "Agentes: ${SELECTED_AGENTS[*]:-ninguno}"
echo "CodeGraph: $([ "$WITH_CODEGRAPH" = 1 ] && echo sí || echo no)"
echo "Engram: $([ "$WITH_ENGRAM" = 1 ] && echo sí || echo no)"
echo "Tech-doc: $([ "$WITH_TECHDOC" = 1 ] && echo sí || echo no)"
echo "HTML de tech-doc: $([ "$WITH_HTML" = 1 ] && echo sí || echo no)"
if [ "$ASSUME_YES" = "0" ]; then
  printf 'Continuar [S/n]: '
  read -r answer
  case "${answer:-s}" in s|S|si|sí|"") ;; *) echo "cancelado" >&2; exit 0 ;; esac
fi

BOOT_ARGS=("$TARGET" --with-verify --profile "$ACTIVE")
if [ "$WITH_TECHDOC" = "1" ]; then
  BOOT_ARGS+=(--with-techdoc)
  [ "$WITH_HTML" = "1" ] && BOOT_ARGS+=(--build-techdoc-html)
fi
bash "$KIT/scripts/bootstrap.sh" "${BOOT_ARGS[@]}"

for name in "${SELECTED[@]}"; do
  [ "$name" = "$ACTIVE" ] && continue
  mkdir -p "$TARGET/.dev-agent/profiles/$name"
  rsync -a --exclude='verify/config.env' "$PROFILES_REPO/profiles/$name/" "$TARGET/.dev-agent/profiles/$name/"
done
printf 'DEV_AGENT_PROFILE=%s\n' "$ACTIVE" >"$TARGET/.dev-agent/config"

python3 - "$TARGET" "$PROFILES_REPO" "$ACTIVE" "${SELECTED[@]}" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

target = Path(sys.argv[1])
profiles_repo = Path(sys.argv[2])
active = sys.argv[3]
names = sys.argv[4:]
entries = []
for name in names:
    source = profiles_repo / "profiles" / name
    commit = "unknown"
    result = subprocess.run(
        ["git", "-C", str(profiles_repo), "rev-parse", "HEAD"],
        capture_output=True,
        text=True,
    )
    if result.returncode == 0:
        commit = result.stdout.strip()
    entries.append({"name": name, "source": str(source), "commit": commit})
lock = {"schema": 1, "active": active, "profiles": entries}
(target / ".dev-agent" / "profiles.lock").write_text(
    json.dumps(lock, indent=2, ensure_ascii=False) + "\n",
    encoding="utf-8",
)
PY

STAMP="$(date +%Y%m%d-%H%M%S)"
for hook in pre-commit pre-push; do
  if [ -f "$TARGET/.git/hooks/$hook" ]; then
    sed -i "s#/home/scalpers/dev-agent-kit#$KIT#g" "$TARGET/.git/hooks/$hook"
  fi
done

ADAPTERS=()
for name in "${SELECTED_AGENTS[@]}"; do
  case "$name" in
    claude|opencode) ADAPTERS+=("$name") ;;
  esac
done
if [ ${#ADAPTERS[@]} -gt 0 ]; then
  bash "$KIT/scripts/install-agent-adapters.sh" "$TARGET" \
    --agents "$(IFS=,; echo "${ADAPTERS[*]}")" \
    --profile "$PROFILES_REPO/profiles/$ACTIVE"
fi

for name in "${SELECTED_AGENTS[@]}"; do
  if [ "$name" = "claude" ] && [ ! -e "$TARGET/CLAUDE.md" ] && [ ! -L "$TARGET/CLAUDE.md" ]; then
    ln -s AGENTS.md "$TARGET/CLAUDE.md"
  fi
done

for dest in "$TARGET/.claude/skills" "$TARGET/.opencode/skills"; do
  [ -d "$dest" ] || continue
  for name in "${SELECTED[@]}"; do
    [ -d "$PROFILES_REPO/profiles/$name/skills" ] && rsync -a "$PROFILES_REPO/profiles/$name/skills/" "$dest/"
  done
done

install_global_skills() {
  local dest="$1"
  [ -d "$dest" ] && cp -a "$dest" "$dest.bak-$STAMP"
  mkdir -p "$dest"
  rsync -a "$KIT/skills/" "$dest/"
  for name in "${SELECTED[@]}"; do
    [ -d "$PROFILES_REPO/profiles/$name/skills" ] && rsync -a "$PROFILES_REPO/profiles/$name/skills/" "$dest/"
  done
}
for name in "${SELECTED_AGENTS[@]}"; do
  case "$name" in
    codex) install_global_skills "$HOME/.codex/skills" ;;
    pi) install_global_skills "$HOME/.pi/agent/skills" ;;
    hermes) install_global_skills "$HOME/.hermes/skills" ;;
  esac
done

EXCLUDE="$TARGET/.git/info/exclude"
touch "$EXCLUDE"
for entry in '.opencode/' '.claude/skills/' '.claude/commands/' '.claude/agents/' '.codegraph/' '.engram/'; do
  grep -qxF "$entry" "$EXCLUDE" || printf '%s\n' "$entry" >>"$EXCLUDE"
done

if [ "$WITH_CODEGRAPH" = "1" ]; then
  if command -v codegraph >/dev/null 2>&1; then
    if [ -d "$TARGET/.codegraph" ]; then
      codegraph sync "$TARGET" || echo "codegraph: sync falló; revisa el índice" >&2
    else
      codegraph init "$TARGET" || echo "codegraph: init falló; revisa el repo" >&2
    fi
  else
    echo "codegraph: no instalado; se omite el índice" >&2
  fi
fi

if [ "$WITH_ENGRAM" = "1" ]; then
  if command -v engram >/dev/null 2>&1; then
    slug="$(basename "$TARGET" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-')"
    mkdir -p "$TARGET/.engram"
    if [ ! -f "$TARGET/.engram/config.json" ]; then
      printf '{"project_name":"%s"}\n' "$slug" >"$TARGET/.engram/config.json"
    fi
    engram save "DevAgentKit instalado en $slug" "Instalación automática: kit, perfiles $ACTIVE, skills, hooks, CodeGraph y Engram." \
      --type config --project "$slug" || echo "engram: no se pudo guardar la instalación" >&2
  else
    echo "engram: no instalado; se omite la memoria" >&2
  fi
fi

mkdir -p "$HOME/.local/bin"
if [ -e "$HOME/.local/bin/dev-agent" ] || [ -L "$HOME/.local/bin/dev-agent" ]; then
  cp -a "$HOME/.local/bin/dev-agent" "$HOME/.local/bin/dev-agent.bak-$STAMP"
fi
ln -sfn "$KIT/bin/dev-agent" "$HOME/.local/bin/dev-agent"

if [ -x "$KIT/scripts/doctor.sh" ] || [ -f "$KIT/scripts/doctor.sh" ]; then
  bash "$KIT/scripts/doctor.sh" "$TARGET" || true
fi

echo
echo "Instalación terminada."
echo "Siguiente: dev-agent doctor"
echo "Si $HOME/.local/bin no está en PATH, usa $KIT/bin/dev-agent o añade la ruta."
