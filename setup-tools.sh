#!/usr/bin/env bash
# One-shot tool installer for Debian/Ubuntu dev containers.
# Intended to be run from a Dockerfile so installs are cached in a layer.
# Safe to re-run; each step is idempotent.
set -euo pipefail

info() { printf '\033[1;34m[info]\033[0m %s\n' "$1"; }
ok()   { printf '\033[1;32m[ ok ]\033[0m %s\n' "$1"; }

SUDO=""
if [[ $EUID -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1; then SUDO="sudo"; fi
fi

apt_install() {
  info "Installing apt packages..."
  export DEBIAN_FRONTEND=noninteractive
  $SUDO apt-get update -qq
  $SUDO apt-get install -y -qq --no-install-recommends \
    zsh \
    tmux \
    stow \
    git \
    curl \
    ca-certificates \
    unzip \
    build-essential \
    fzf \
    bat \
    ripgrep \
    fd-find \
    direnv \
    locales
  # Debian aliases: batcat / fdfind — link friendlier names into ~/.local/bin
  mkdir -p "$HOME/.local/bin"
  command -v batcat  >/dev/null && ln -snf "$(command -v batcat)"  "$HOME/.local/bin/bat"
  command -v fdfind  >/dev/null && ln -snf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  ok "apt packages installed"
}

install_neovim() {
  if command -v nvim >/dev/null 2>&1; then ok "neovim present"; return; fi
  info "Installing neovim (appimage)..."
  local arch; arch="$(uname -m)"
  local url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${arch}.tar.gz"
  curl -fsSL "$url" -o /tmp/nvim.tar.gz
  $SUDO tar -C /opt -xzf /tmp/nvim.tar.gz
  $SUDO ln -snf "/opt/nvim-linux-${arch}/bin/nvim" /usr/local/bin/nvim
  rm -f /tmp/nvim.tar.gz
  ok "neovim installed"
}

install_starship() {
  if command -v starship >/dev/null 2>&1; then ok "starship present"; return; fi
  info "Installing starship..."
  curl -fsSL https://starship.rs/install.sh | $SUDO sh -s -- -y >/dev/null
  ok "starship installed"
}

install_zoxide() {
  if command -v zoxide >/dev/null 2>&1; then ok "zoxide present"; return; fi
  info "Installing zoxide..."
  curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash >/dev/null
  ok "zoxide installed"
}

install_lazygit() {
  if command -v lazygit >/dev/null 2>&1; then ok "lazygit present"; return; fi
  info "Installing lazygit..."
  local ver
  ver="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
    | grep -Po '"tag_name": "v\K[^"]*')"
  local arch; arch="$(uname -m)"; [[ "$arch" == "aarch64" ]] && arch="arm64" || arch="x86_64"
  curl -fsSL "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${ver}_Linux_${arch}.tar.gz" \
    -o /tmp/lazygit.tar.gz
  tar -xzf /tmp/lazygit.tar.gz -C /tmp lazygit
  $SUDO install /tmp/lazygit /usr/local/bin/
  rm -f /tmp/lazygit /tmp/lazygit.tar.gz
  ok "lazygit installed"
}

install_lsd() {
  if command -v lsd >/dev/null 2>&1; then ok "lsd present"; return; fi
  info "Installing lsd..."
  local arch; arch="$(uname -m)"; [[ "$arch" == "aarch64" ]] && arch="aarch64" || arch="x86_64"
  local url
  url="$(curl -fsSL https://api.github.com/repos/lsd-rs/lsd/releases/latest \
    | grep -Po "\"browser_download_url\": \"\K[^\"]*${arch}-unknown-linux-gnu.tar.gz")"
  curl -fsSL "$url" -o /tmp/lsd.tar.gz
  tar -xzf /tmp/lsd.tar.gz -C /tmp
  $SUDO install /tmp/lsd-*/lsd /usr/local/bin/
  rm -rf /tmp/lsd.tar.gz /tmp/lsd-*
  ok "lsd installed"
}

install_yazi() {
  if command -v yazi >/dev/null 2>&1; then ok "yazi present"; return; fi
  info "Installing yazi..."
  local arch; arch="$(uname -m)"; [[ "$arch" == "aarch64" ]] && arch="aarch64" || arch="x86_64"
  curl -fsSL "https://github.com/sxyazi/yazi/releases/latest/download/yazi-${arch}-unknown-linux-gnu.zip" \
    -o /tmp/yazi.zip
  unzip -q /tmp/yazi.zip -d /tmp
  $SUDO install /tmp/yazi-*/yazi /usr/local/bin/
  $SUDO install /tmp/yazi-*/ya   /usr/local/bin/ 2>/dev/null || true
  rm -rf /tmp/yazi.zip /tmp/yazi-*
  ok "yazi installed"
}

install_mise() {
  if command -v mise >/dev/null 2>&1; then ok "mise present"; return; fi
  info "Installing mise..."
  curl -fsSL https://mise.run | sh >/dev/null
  ok "mise installed (use 'mise use -g node@lts' etc.)"
}

main() {
  apt_install
  install_neovim
  install_starship
  install_zoxide
  install_lazygit
  install_lsd
  install_yazi
  install_mise
  ok "All tools installed."
}

main "$@"
