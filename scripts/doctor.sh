#!/usr/bin/env bash
set -uo pipefail

ROOT="${1:-$PWD}"
KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "$ROOT" && pwd)" || exit 2
FAIL=0

ok() { printf 'ok    %s\n' "$1"; }
warn() { printf 'warn  %s\n' "$1"; }
bad() { printf 'FAIL  %s\n' "$1"; FAIL=1; }

echo "DevAgentKit doctor"
echo "repo: $ROOT"
echo

if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then ok "git repo"; else bad "no es un repo git"; fi

for name in guard/guard.sh verify/run.sh AGENTS.md skills; do
  if [ -e "$ROOT/$name" ]; then ok "$name"; else warn "$name no está en el repo (puede estar en el kit)"; fi
done

for hook in pre-commit pre-push; do
  if [ -x "$ROOT/.git/hooks/$hook" ]; then ok "hook $hook"; else warn "hook $hook no instalado"; fi
done

CONFIG="$ROOT/.dev-agent/config"
if [ -f "$CONFIG" ]; then
  PROFILE="$(sed -n 's/^DEV_AGENT_PROFILE=//p' "$CONFIG" | tail -1)"
  if [ -n "$PROFILE" ]; then
    ok "perfil activo: $PROFILE"
    if [ -f "$ROOT/.dev-agent/profiles/$PROFILE/profile.env" ]; then ok "perfil $PROFILE instalado"; else bad "perfil $PROFILE no está en .dev-agent/profiles"; fi
  else
    bad "config sin DEV_AGENT_PROFILE"
  fi
else
  warn "sin .dev-agent/config; guard omitirá el perfil"
fi

for cfg in "$ROOT/verify/config.env" "$ROOT/.dev-agent/verify.env"; do
  if [ -f "$cfg" ]; then
    if grep -qE '^(SMOKE_CMD|TEST_CMD)=' "$cfg"; then
      if grep -qE '^(SMOKE_CMD|TEST_CMD)=["'\'' ]*$' "$cfg"; then warn "$cfg existe pero está vacío"; else ok "$cfg tiene comando"; fi
    else
      warn "$cfg sin SMOKE_CMD/TEST_CMD"
    fi
  else
    warn "falta $cfg"
  fi
done

if [ -f "$ROOT/.dev-agent/verify.env" ]; then
  if grep -qE '^TEST_CMD=.*[^"'\'' ]' "$ROOT/.dev-agent/verify.env"; then ok "pre-push con TEST_CMD"; else warn "pre-push fallará hasta que TEST_CMD tenga valor"; fi
fi

if [ -d "$ROOT/.claude/skills" ] || [ -d "$ROOT/.opencode/skills" ]; then
  ok "adaptadores de skills presentes"
else
  warn "sin adaptadores .claude/.opencode; el agente puede usar la fuente global"
fi

if [ -f "$ROOT/CLAUDE.md" ] || [ -L "$ROOT/CLAUDE.md" ]; then ok "CLAUDE.md"; else warn "sin CLAUDE.md; Claude Code no leerá AGENTS.md automáticamente"; fi
if [ -L "$HOME/.agents/AGENTS.md" ] || [ -f "$HOME/.agents/AGENTS.md" ]; then ok "norma global enlazada"; else warn "sin ~/.agents/AGENTS.md"; fi

if command -v codegraph >/dev/null 2>&1; then
  if [ -d "$ROOT/.codegraph" ]; then ok "CodeGraph indexado"; else warn "CodeGraph instalado pero sin índice; ejecuta dev-agent codegraph"; fi
else
  warn "CodeGraph no instalado"
fi

if command -v engram >/dev/null 2>&1; then
  if [ -f "$ROOT/.engram/config.json" ]; then ok "Engram configurado"; else warn "Engram instalado pero sin .engram/config.json"; fi
else
  warn "Engram no instalado"
fi

if [ -f "$ROOT/docs/TECHDOC.md" ]; then ok "referencia tech-doc"; else warn "sin docs/TECHDOC.md"; fi
if [ -e "$ROOT/docs/techdoc.html" ] || [ -L "$ROOT/docs/techdoc.html" ]; then ok "enlace HTML local"; else warn "sin enlace HTML local; usa --build-techdoc-html"; fi

echo
if [ "$FAIL" = "1" ]; then
  echo "doctor: faltan piezas obligatorias"
  exit 1
fi
echo "doctor: núcleo correcto; los warn son opcionales o pendientes"
