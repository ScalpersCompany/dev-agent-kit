#!/usr/bin/env bash
# Install optional linters and scanners used by guard, without editing repo config.
set -euo pipefail

BIN="$HOME/.local/bin"
mkdir -p "$BIN"
STAMP="$(date +%Y%m%d-%H%M%S)"

say() { printf '%s\n' "$*"; }
die() { printf 'install-dev-deps: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
ensure_path() {
  case ":$PATH:" in *":$BIN:"*) ;; *) export PATH="$BIN:$PATH" ;; esac
}
ensure_path

install_python_tool() {
  local tool="$1"
  have "$tool" && { say "$tool: $(command -v "$tool")"; return 0; }
  if have pipx; then
    pipx install "$tool"
  elif have pip3; then
    pip3 install --user "$tool"
  elif have python3 && python3 -m pip --version >/dev/null 2>&1; then
    python3 -m pip install --user "$tool"
  else
    die "$tool is missing and no pipx/pip3 is available"
  fi
  ensure_path
  have "$tool" || die "$tool was installed but is not on PATH"
  say "$tool: installed"
}

install_node_tool() {
  local tool="$1" package="$2"
  have "$tool" && { say "$tool: $(command -v "$tool")"; return 0; }
  if ! have npm; then
    say "$tool: npm is missing; skipped" >&2
    return 0
  fi
  npm install --global "$package"
  have "$tool" || die "$tool was installed but is not on PATH"
  say "$tool: installed"
}

install_gitleaks() {
  have gitleaks && { say "gitleaks: $(gitleaks version 2>/dev/null | head -1)"; return 0; }
  have curl || die "curl is required for gitleaks"
  have tar || die "tar is required for gitleaks"
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"
  case "$os" in linux) os=linux ;; darwin) os=darwin ;; *) die "unsupported OS for gitleaks: $os" ;; esac
  case "$arch" in x86_64|amd64) arch=x64 ;; arm64|aarch64) arch=arm64 ;; *) die "unsupported architecture for gitleaks: $arch" ;; esac
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/gitleaks-install.XXXXXX")"
  trap 'rm -rf "$tmp"' RETURN
  release="$(curl -fsSL https://api.github.com/repos/gitleaks/gitleaks/releases/latest)" || die "could not query the gitleaks release"
  version="$(printf '%s' "$release" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tag_name", "").lstrip("v"))')"
  [ -n "$version" ] || die "could not read the gitleaks version"
  asset="gitleaks_${version}_${os}_${arch}.tar.gz"
  url="https://github.com/gitleaks/gitleaks/releases/download/v${version}/${asset}"
  say "gitleaks: downloading $asset"
  curl -fsSL "$url" -o "$tmp/$asset" || die "could not download $url"
  tar -xzf "$tmp/$asset" -C "$tmp"
  bin="$(find "$tmp" -maxdepth 2 -type f -name gitleaks -perm -u+x | head -1)"
  [ -n "$bin" ] || die "gitleaks binary not found in the release archive"
  install -m 0755 "$bin" "$BIN/gitleaks"
  ensure_path
  have gitleaks || die "gitleaks was installed but is not on PATH"
  say "gitleaks: installed"
}

install_python_tool ruff
install_python_tool black
install_python_tool mypy
install_node_tool eslint eslint
install_node_tool tsc typescript
install_gitleaks

say
say "Herramientas instaladas. Los checks genéricos de guard siguen siendo opt-in:"
say "  ruff/black/mypy requieren configuración del repo; eslint/tsc requieren package.json/tsconfig."
say "  El perfil activo y gitleaks sí se ejecutan cuando corresponde."
