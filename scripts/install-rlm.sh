#!/usr/bin/env bash
set -euo pipefail

RLM_VERSION="${RLM_AGENT_VERSION:-0.1.1}"
AGENTS=""
DRY_RUN=0
CHECK_ONLY=0
STAMP="$(date +%Y%m%d-%H%M%S)"

usage() {
  cat >&2 <<'EOF'
usage: install-rlm.sh [options]

Optional integration: rlm-agent is a personal MIT project that gives the agent a
persistent Python kernel, a context lake and background subagents. It is not a
quality gate and is never required by guard, verify or the team flow.

  --agents <list|all>   hermes,opencode,pi (default: detected adapters)
  --check               report installed version and adapters, change nothing
  --dry-run             print the commands, change nothing
  -h, --help            this help
EOF
  exit "${1:-2}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --agents) [ $# -ge 2 ] || usage; AGENTS="$2"; shift 2 ;;
    --check) CHECK_ONLY=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage 0 ;;
    *) echo "opción desconocida: $1" >&2; usage ;;
  esac
done

info() { echo "rlm: $*"; }
die() { echo "rlm: $*" >&2; exit 1; }

detected_agents() {
  local found=()
  [ -d "$HOME/.hermes" ] && found+=("hermes")
  [ -d "$HOME/.config/opencode" ] && found+=("opencode")
  [ -d "$HOME/.pi/agent" ] && found+=("pi")
  printf '%s\n' "${found[@]}"
}

agent_dir() {
  case "$1" in
    hermes) printf '%s\n' "$HOME/.hermes" ;;
    opencode) printf '%s\n' "$HOME/.config/opencode" ;;
    pi) printf '%s\n' "$HOME/.pi/agent" ;;
    *) return 1 ;;
  esac
}

if [ "$CHECK_ONLY" = 1 ]; then
  if command -v rlm-agent-install >/dev/null 2>&1; then
    info "instalador: $(command -v rlm-agent-install)"
  else
    info "instalador: no instalado"
  fi
  if command -v rlm-agent-update >/dev/null 2>&1; then
    info "actualizador: $(command -v rlm-agent-update)"
  else
    info "actualizador: no instalado"
  fi
  if [ -d "$HOME/.hermes/plugins/rlm" ]; then info "Hermes: plugin presente"; fi
  if [ -f "$HOME/.config/opencode/plugins/rlm.ts" ]; then info "OpenCode: plugin presente"; fi
  if [ -f "$HOME/.pi/agent/extensions/rlm.ts" ]; then info "Pi: extensión presente"; fi
  exit 0
fi

if ! command -v npm >/dev/null 2>&1; then
  die "npm no está instalado; no puedo instalar rlm-agent"
fi

if [ "$DRY_RUN" = 1 ]; then
  info "instalaría npm install -g rlm-agent@$RLM_VERSION"
  if [ -z "$AGENTS" ]; then
    AGENTS="$(detected_agents | paste -sd, -)"
  fi
  IFS=',' read -r -a selected <<<"$AGENTS"
  for agent in "${selected[@]}"; do
    dir="$(agent_dir "$agent")" || { info "omitido: $agent (sin adaptador)"; continue; }
    info "ejecutaría rlm-agent-install --editor $agent --dir $dir"
  done
  exit 0
fi

info "instalando rlm-agent@$RLM_VERSION"
npm install -g "rlm-agent@$RLM_VERSION"
command -v rlm-agent-install >/dev/null 2>&1 || die "rlm-agent-install no quedó en PATH"

if [ -z "$AGENTS" ] || [ "$AGENTS" = "all" ]; then
  AGENTS="$(detected_agents | paste -sd, -)"
fi
[ -n "$AGENTS" ] || die "no hay adaptadores de RLM detectados"

IFS=',' read -r -a selected <<<"$AGENTS"
installed=0
for agent in "${selected[@]}"; do
  case "$agent" in
    claude|codex)
      info "omitido: $agent (RLM no publica adaptador para este agente)"
      continue
      ;;
  esac
  dir="$(agent_dir "$agent")" || { info "omitido: $agent (agente desconocido)"; continue; }
  info "configurando $agent en $dir"
  case "$agent" in
    hermes)
      [ -d "$dir/plugins/rlm" ] && cp -a "$dir/plugins/rlm" "$dir/plugins/rlm.bak-rlm-$STAMP"
      ;;
    opencode)
      [ -f "$dir/plugins/rlm.ts" ] && cp -a "$dir/plugins/rlm.ts" "$dir/plugins/rlm.ts.bak-rlm-$STAMP"
      ;;
    pi)
      [ -f "$dir/extensions/rlm.ts" ] && cp -a "$dir/extensions/rlm.ts" "$dir/extensions/rlm.ts.bak-rlm-$STAMP"
      ;;
  esac
  rlm-agent-install --editor "$agent" --dir "$dir"
  installed=1
done
[ "$installed" = 1 ] || die "ningún adaptador instalado"
info "RLM instalado; reinicia el agente o usa /reset para cargar el plugin"
