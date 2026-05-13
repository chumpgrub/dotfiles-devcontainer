#!/usr/bin/env bash
# Symlink-only installer for dev containers / DevPod workspaces.
# Idempotent — safe to run on every container create.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

info() { printf '\033[1;34m[info]\033[0m %s\n' "$1"; }
ok()   { printf '\033[1;32m[ ok ]\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$1" >&2; }
err()  { printf '\033[1;31m[fail]\033[0m %s\n' "$1" >&2; }

# -----------------------------------------------------------------------------
# Recursive linker.
#
# Walks the dotfiles tree and creates one symlink per *leaf* (file or non-
# existing directory) inside $HOME. When a directory already exists in $HOME
# (e.g. ~/.config created by a base image / feature), we descend into it and
# link individual children, instead of trying to replace the whole directory.
#
# This mirrors GNU stow's "folding" behavior, but works without stow and
# reports every action so failures aren't silent.
# -----------------------------------------------------------------------------
IGNORE_REGEX='^(\.git|\.gitignore|\.stow-local-ignore|README\.md|LICENSE|install\.sh|setup-tools\.sh|Makefile|test)$'

link_tree() {
  local src_root="$1" dest_root="$2"
  shopt -s dotglob nullglob
  local src
  for src in "$src_root"/*; do
    local name; name="$(basename "$src")"

    # Only apply the ignore list at the top level.
    if [[ "$src_root" == "$DOTFILES_DIR" ]] && [[ "$name" =~ $IGNORE_REGEX ]]; then
      continue
    fi

    local dest="$dest_root/$name"

    if [[ -L "$dest" ]]; then
      # Existing symlink — refresh it (handles repo path changes between runs).
      ln -snf "$src" "$dest"
      echo "    [link] $dest -> $src"
      continue
    fi

    if [[ -d "$src" ]] && [[ -d "$dest" ]]; then
      # Both sides are real directories: descend so we can fold inside.
      link_tree "$src" "$dest"
      continue
    fi

    if [[ -e "$dest" ]]; then
      # Real file/dir at the target (e.g. base image's pre-baked ~/.zshrc).
      # Back it up to $dest.pre-dotfiles once, then replace with our symlink.
      # Subsequent runs see the backup already exists and just remove the
      # stale dest, so we never overwrite the original backup.
      local backup="${dest}.pre-dotfiles"
      if [[ ! -e "$backup" ]]; then
        mv "$dest" "$backup"
        echo "    [back] $dest -> $backup"
      else
        rm -rf "$dest"
      fi
    fi

    mkdir -p "$dest_root"
    ln -s "$src" "$dest"
    echo "    [link] $dest -> $src"
  done
}

link_dotfiles() {
  info "Linking dotfiles from $DOTFILES_DIR into $HOME"
  link_tree "$DOTFILES_DIR" "$HOME"
  ok "Dotfiles linked"
}

install_tpm() {
  local tpm_dir="$HOME/.config/tmux/plugins/tpm"
  if [[ -d "$tpm_dir" ]]; then ok "TPM already installed"; return; fi
  command -v git >/dev/null || { warn "git missing — skipping TPM"; return; }
  info "Cloning TPM..."
  git clone --depth=1 https://github.com/tmux-plugins/tpm "$tpm_dir" >/dev/null
  ok "TPM installed (run prefix + I inside tmux to fetch plugins)"
}

install_zinit() {
  local zinit_home="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
  if [[ -d "$zinit_home" ]]; then ok "zinit already installed"; return; fi
  command -v git >/dev/null || { warn "git missing — skipping zinit"; return; }
  info "Cloning zinit..."
  mkdir -p "$(dirname "$zinit_home")"
  git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$zinit_home" >/dev/null
  ok "zinit installed"
}

run_setup_tools() {
  if [[ "${DOTFILES_SKIP_TOOLS:-0}" == "1" ]]; then
    info "DOTFILES_SKIP_TOOLS=1 — skipping setup-tools.sh"
    return
  fi
  if [[ -x "$DOTFILES_DIR/setup-tools.sh" ]]; then
    info "Running setup-tools.sh..."
    if ! "$DOTFILES_DIR/setup-tools.sh"; then
      err "setup-tools.sh failed — continuing so dotfiles still get linked"
    fi
  fi
}

main() {
  info "dotfiles-devcontainer install starting"
  info "  user:   $(id -un)"
  info "  home:   $HOME"
  info "  source: $DOTFILES_DIR"
  run_setup_tools
  link_dotfiles
  install_tpm
  install_zinit
  ok "Done."
}

main "$@"
