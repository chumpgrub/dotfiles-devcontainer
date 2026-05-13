#!/usr/bin/env bash
# Symlink-only installer for dev containers.
# Designed to be safe to run repeatedly (every container create).
# - No sudo
# - No package installs (see setup-tools.sh)
# - No chsh (set SHELL in devcontainer.json or Dockerfile)
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

info() { printf '\033[1;34m[info]\033[0m %s\n' "$1"; }
ok()   { printf '\033[1;32m[ ok ]\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$1"; }

require_stow() {
  if ! command -v stow >/dev/null 2>&1; then
    warn "stow not found — falling back to manual symlinks"
    return 1
  fi
}

manual_link() {
  # Fallback: walk $DOTFILES_DIR and symlink each top-level dotfile/dir into $HOME.
  # Used when stow isn't installed in the container.
  shopt -s dotglob nullglob
  for src in "$DOTFILES_DIR"/*; do
    local name; name="$(basename "$src")"
    case "$name" in
      .git|.gitignore|.stow-local-ignore|README.md|LICENSE|install.sh|setup-tools.sh|Makefile|test)
        continue ;;
    esac
    local dest="$HOME/$name"
    if [[ -L "$dest" ]] || [[ ! -e "$dest" ]]; then
      ln -snf "$src" "$dest"
    else
      warn "skipping $dest (exists and not a symlink)"
    fi
  done
}

stow_dotfiles() {
  info "Stowing dotfiles into \$HOME..."
  if require_stow; then
    cd "$DOTFILES_DIR"
    stow --restow --target="$HOME" .
  else
    manual_link
  fi
  ok "Dotfiles linked"
}

install_tpm() {
  local tpm_dir="$HOME/.config/tmux/plugins/tpm"
  if [[ -d "$tpm_dir" ]]; then
    ok "TPM already installed"
    return
  fi
  if ! command -v git >/dev/null 2>&1; then
    warn "git not installed — skipping TPM"
    return
  fi
  info "Cloning TPM..."
  git clone --depth=1 https://github.com/tmux-plugins/tpm "$tpm_dir" >/dev/null
  ok "TPM installed (run prefix + I inside tmux to fetch plugins)"
}

install_zinit() {
  local zinit_home="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
  if [[ -d "$zinit_home" ]]; then
    ok "zinit already installed"
    return
  fi
  if ! command -v git >/dev/null 2>&1; then
    warn "git not installed — skipping zinit"
    return
  fi
  info "Cloning zinit..."
  mkdir -p "$(dirname "$zinit_home")"
  git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$zinit_home" >/dev/null
  ok "zinit installed"
}

run_setup_tools() {
  # Skip with DOTFILES_SKIP_TOOLS=1 (e.g. when tools are baked into the image).
  if [[ "${DOTFILES_SKIP_TOOLS:-0}" == "1" ]]; then
    info "DOTFILES_SKIP_TOOLS=1 — skipping setup-tools.sh"
    return
  fi
  if [[ -x "$DOTFILES_DIR/setup-tools.sh" ]]; then
    info "Running setup-tools.sh..."
    "$DOTFILES_DIR/setup-tools.sh"
  fi
}

main() {
  info "Linking dotfiles from $DOTFILES_DIR"
  run_setup_tools
  stow_dotfiles
  install_tpm
  install_zinit
  ok "Done."
}

main "$@"
