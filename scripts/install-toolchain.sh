#!/usr/bin/env bash
# Install and configure the AI agent toolchain, then prove it.
# Read-only if everything is already present; network is used only for a missing tool.
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="${1:?usage: install-toolchain.sh <repo> --agents claude,opencode --yes}"
shift
AGENTS=""
ASSUME_YES=0
SKIP_SMOKE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --agents) [ $# -ge 2 ] || exit 2; AGENTS="$2"; shift 2 ;;
    --yes) ASSUME_YES=1; shift ;;
    --skip-smoke) SKIP_SMOKE=1; shift ;;
    -h|--help)
      echo "usage: install-toolchain.sh <repo> --agents claude,opencode [--yes] [--skip-smoke]" >&2
      exit 0
      ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
AGENTS="${AGENTS:-claude,opencode}"
REPO="$(cd "$REPO" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BIN="$HOME/.local/bin"
mkdir -p "$BIN"

say() { printf '%s\n' "$*"; }
die() { printf 'install-toolchain: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
ensure_network() {
  have curl || die "curl is required"
  have tar || die "tar is required"
}
ensure_bin_path() {
  case ":$PATH:" in *":$BIN:"*) ;; *) export PATH="$BIN:$PATH" ;; esac
}

persist_bin_path() {
  local line='export PATH="$HOME/.local/bin:$PATH" # dev-agent-kit: toolchain'
  for file in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [ -f "$file" ] || continue
    if ! grep -qF 'dev-agent-kit: toolchain' "$file"; then
      cp -a "$file" "$file.bak-toolchain-$STAMP"
      printf '\n%s\n' "$line" >>"$file"
      say "PATH: added ~/.local/bin to $file"
    fi
  done
}

install_jq() {
  have jq && return 0
  say "engram: jq is required for the Claude Code plugin; installing it"
  if have brew; then
    brew install jq
  elif have apt-get && sudo -n true 2>/dev/null; then
    sudo -n apt-get update -qq && sudo -n apt-get install -y -qq jq
  elif have dnf && sudo -n true 2>/dev/null; then
    sudo -n dnf install -y jq
  elif have pacman && sudo -n true 2>/dev/null; then
    sudo -n pacman -S --noconfirm jq
  elif have apk && sudo -n true 2>/dev/null; then
    sudo -n apk add jq
  else
    die "jq is missing and no non-interactive package manager is available; install jq and rerun"
  fi
  ensure_bin_path
  have jq || die "jq installation did not put jq on PATH"
}

install_engram() {
  if have engram; then say "engram: $(engram --version 2>/dev/null | head -1)"; return 0; fi
  ensure_network
  if have brew; then
    say "engram: installing with Homebrew"
    brew install gentleman-programming/tap/engram
    return 0
  fi
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"
  case "$os" in linux) os=linux ;; darwin) os=darwin ;; *) die "unsupported OS for engram: $os" ;; esac
  case "$arch" in x86_64|amd64) arch=amd64 ;; arm64|aarch64) arch=arm64 ;; *) die "unsupported architecture for engram: $arch" ;; esac
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/engram-install.XXXXXX")"
  trap 'rm -rf "$tmp"' RETURN
  say "engram: resolving latest release"
  release="$(curl -fsSL https://api.github.com/repos/Gentleman-Programming/engram/releases/latest)" || die "could not query the engram release metadata"
  version="$(printf '%s' "$release" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tag_name", "").lstrip("v"))')"
  [ -n "$version" ] || die "could not read the engram release version"
  asset="engram_${version}_${os}_${arch}.tar.gz"
  url="https://github.com/Gentleman-Programming/engram/releases/download/v${version}/${asset}"
  say "engram: downloading $asset"
  curl -fsSL "$url" -o "$tmp/$asset" || die "could not download $url"
  curl -fsSL "https://github.com/Gentleman-Programming/engram/releases/download/v${version}/checksums.txt" -o "$tmp/checksums.txt" || true
  if [ -s "$tmp/checksums.txt" ]; then
    if command -v sha256sum >/dev/null 2>&1; then
      ( cd "$tmp" && grep -E "[ ]${asset}$" checksums.txt | sha256sum -c - ) || die "engram checksum verification failed"
    elif command -v shasum >/dev/null 2>&1; then
      ( cd "$tmp" && grep -E "[ ]${asset}$" checksums.txt | shasum -a 256 -c - ) || die "engram checksum verification failed"
    else
      say "engram: no SHA-256 tool; skipping checksum verification" >&2
    fi
  fi
  tar -xzf "$tmp/$asset" -C "$tmp"
  bin="$(find "$tmp" -maxdepth 2 -type f -name engram -perm -u+x | head -1)"
  [ -n "$bin" ] || die "engram binary not found in the release archive"
  install -m 0755 "$bin" "$BIN/engram"
  ensure_bin_path
  have engram || die "engram was installed but is not on PATH"
  say "engram: installed $(engram --version 2>/dev/null | head -1)"
}

install_gga() {
  if have gga; then say "gga: $(gga --version 2>/dev/null | head -1)"; return 0; fi
  ensure_network
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/gga-install.XXXXXX")"
  trap 'rm -rf "$tmp"' RETURN
  say "gga: downloading the official installer"
  curl -fsSL https://raw.githubusercontent.com/Gentleman-Programming/gentleman-guardian-angel/main/install.sh -o "$tmp/install.sh" \
    || die "could not download the gga installer"
  # The upstream installer may ask before replacing an existing gga; this path is only for a missing one.
  bash "$tmp/install.sh"
  ensure_bin_path
  have gga || die "gga was installed but is not on PATH"
  say "gga: installed $(gga --version 2>/dev/null | head -1)"
}

install_gentle_ai() {
  if have gentle-ai; then say "gentle-ai: $(gentle-ai --version 2>/dev/null | head -1)"; return 0; fi
  ensure_network
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/gentle-ai-install.XXXXXX")"
  trap 'rm -rf "$tmp"' RETURN
  say "gentle-ai: downloading the official installer"
  curl -fsSL https://raw.githubusercontent.com/Gentleman-Programming/gentle-ai/main/scripts/install.sh -o "$tmp/install.sh" \
    || die "could not download the gentle-ai installer"
  bash "$tmp/install.sh" --method binary --dir "$BIN"
  ensure_bin_path
  have gentle-ai || die "gentle-ai was installed but is not on PATH"
  say "gentle-ai: installed $(gentle-ai --version 2>/dev/null | head -1)"
}

install_claude() {
  case ",$AGENTS," in *,claude,*) ;; *) return 0 ;; esac
  if have claude; then say "claude: $(claude --version 2>/dev/null | head -1)"; return 0; fi
  have npm || die "claude is selected but npm is missing; install Node.js/npm first"
  say "claude: installing the Claude Code CLI"
  npm install --global @anthropic-ai/claude-code
  have claude || die "claude was installed but is not on PATH"
  say "claude: installed $(claude --version 2>/dev/null | head -1)"
}

configure_engram() {
  have engram || die "engram is missing after installation"
  ENGRAM_BIN="$(command -v engram)"
  for config in "$HOME/.claude.json" "$HOME/.config/opencode/opencode.json" "$HOME/.codex/config.toml" "$HOME/.pi/agent/mcp.json" "$HOME/.hermes/config.yaml"; do
    [ -e "$config" ] && cp -a "$config" "$config.bak-toolchain-$STAMP"
  done
  for agent in ${AGENTS//,/ }; do
    case "$agent" in
      claude)
        install_jq
        if claude mcp get engram >/dev/null 2>&1; then
          say "engram: existing Claude Code MCP retained"
        else
          say "engram: setting up Claude Code MCP"
          if ! engram setup claude-code --allow-memory-writes || ! claude mcp get engram >/dev/null 2>&1; then
            if claude mcp get engram >/dev/null 2>&1; then
              say "engram: existing Claude Code MCP retained"
            else
              say "engram: Claude setup did not register the MCP; using the JSON fallback" >&2
              have claude || die "claude CLI is missing; cannot configure its MCP"
              claude mcp add-json engram "{\"type\":\"stdio\",\"command\":\"$ENGRAM_BIN\",\"args\":[\"mcp\",\"--tools=agent\"]}" -s user \
                || claude mcp get engram >/dev/null 2>&1 \
                || die "could not add the engram MCP to Claude Code"
            fi
          fi
        fi
        claude mcp get engram >/dev/null 2>&1 || die "Claude Code has no engram MCP after configuration"
        ;;
      opencode|codex|pi)
        say "engram: setting up $agent MCP"
        engram setup "$agent" || die "engram setup failed for $agent"
        ;;
      hermes)
        say "engram: checking the Hermes MCP entry"
        if ! grep -qE '^[[:space:]]*engram:' "$HOME/.hermes/config.yaml" 2>/dev/null; then
          have hermes || die "hermes CLI is missing; cannot configure its MCP"
          hermes mcp add engram --command engram --args mcp --tools=agent \
            || die "could not add the engram MCP to Hermes"
        fi
        ;;
    esac
  done
}

install_skills() {
  sources=("$KIT/skills")
  if [ -n "${DEV_AGENT_PROFILE:-}" ] && [ -d "${DEV_AGENT_PROFILE}/skills" ]; then sources+=("$DEV_AGENT_PROFILE/skills"); fi
  for agent in ${AGENTS//,/ }; do
    case "$agent" in
      claude) dest="$HOME/.claude/skills" ;;
      opencode) dest="$HOME/.config/opencode/skills" ;;
      codex) dest="$HOME/.codex/skills" ;;
      pi) dest="$HOME/.pi/agent/skills" ;;
      hermes) dest="$HOME/.hermes/skills" ;;
      *) continue ;;
    esac
    mkdir -p "$dest"
    [ -d "$dest" ] && cp -a "$dest" "$dest.bak-toolchain-$STAMP"
    for source in "${sources[@]}"; do
      [ -d "$source" ] || continue
      rsync -a --exclude='__pycache__' "$source/" "$dest/"
    done
    count="$(find "$dest" -maxdepth 2 -name SKILL.md | wc -l)"
    say "skills: $agent -> $dest ($count SKILL.md)"
  done
  if [ -d "$KIT/skills" ]; then
    mkdir -p "$HOME/.agents/skills"
    cp -a "$HOME/.agents/skills" "$HOME/.agents/skills.bak-toolchain-$STAMP" 2>/dev/null || true
    rsync -a --exclude='__pycache__' "$KIT/skills/" "$HOME/.agents/skills/"
  fi
}

smoke_install() {
  local failures=0
  check() { local label="$1"; shift; if "$@"; then say "smoke: ok $label"; else say "smoke: FAIL $label" >&2; failures=$((failures+1)); fi; }
  selected() { case ",$AGENTS," in *",$1,"*) return 0 ;; *) return 1 ;; esac; }
  for binary in engram gga gentle-ai; do check "$binary" command -v "$binary"; done
  if selected claude; then check "claude" command -v claude; fi
  check "engram version" engram --version
  check "engram doctor" engram doctor --json
  check "gga version" gga --version
  check "gentle-ai version" gentle-ai --version
  if selected claude; then
    check "claude engram MCP" claude mcp get engram
  fi
  if selected opencode; then
    check "opencode engram MCP" bash -c 'for i in 1 2 3; do opencode mcp list 2>/dev/null | grep -q "engram" && exit 0; sleep 1; done; grep -q "\"engram\"" "$HOME/.config/opencode/opencode.json" 2>/dev/null'
  fi
  if selected codex; then
    check "codex engram MCP" grep -q '^\[mcp_servers\.engram\]' "$HOME/.codex/config.toml"
  fi
  if selected pi; then
    check "pi engram MCP" grep -q 'engram' "$HOME/.pi/agent/mcp.json"
  fi
  if selected hermes; then
    check "hermes engram MCP" grep -q 'engram' "$HOME/.hermes/config.yaml"
  fi
  for agent in ${AGENTS//,/ }; do
    case "$agent" in
      claude) dest="$HOME/.claude/skills" ;;
      opencode) dest="$HOME/.config/opencode/skills" ;;
      codex) dest="$HOME/.codex/skills" ;;
      pi) dest="$HOME/.pi/agent/skills" ;;
      hermes) dest="$HOME/.hermes/skills" ;;
      *) continue ;;
    esac
    if find "$dest" -maxdepth 2 -name SKILL.md -print -quit 2>/dev/null | grep -q .; then
      say "smoke: ok skills/$agent"
    else
      say "smoke: FAIL skills/$agent" >&2
      failures=$((failures+1))
    fi
  done
  if [ "$failures" -ne 0 ]; then
    say "install-toolchain: $failures smoke checks failed" >&2
    return 1
  fi
  say "install-toolchain: smoke passed"
}

install_engram
install_gga
install_gentle_ai
install_claude
persist_bin_path
configure_engram
install_skills
if [ "$SKIP_SMOKE" = "0" ]; then smoke_install; fi
