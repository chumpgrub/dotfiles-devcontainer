# dotfiles-devcontainer

Personal dotfiles tailored for **DevPod workspaces** and **dev containers** (Debian/Ubuntu, non-root user, neovim as editor).

DevPod's `--dotfiles` flag clones this repo into the workspace and runs `install.sh` once. That script installs tools (via `setup-tools.sh`), symlinks configs, and bootstraps TPM/zinit.

## Use it with DevPod

```bash
# Per-workspace
devpod up <workspace> --dotfiles https://github.com/markfurrow/dotfiles-devcontainer

# Or globally, so every workspace gets it
devpod context set-options -o DOTFILES_URL=https://github.com/markfurrow/dotfiles-devcontainer
```

## Use it manually

```bash
git clone https://github.com/markfurrow/dotfiles-devcontainer ~/.dotfiles
~/.dotfiles/install.sh
```

`install.sh` is idempotent — safe to re-run on every container create.

## Layout

| File | Purpose |
|------|---------|
| `install.sh` | Entry point. Runs `setup-tools.sh`, symlinks dotfiles via stow, installs TPM + zinit. |
| `setup-tools.sh` | apt + curl installer for the CLI toolchain. Idempotent. |
| `.zshrc`, `.config/*` | The actual configs. |
| `test/Dockerfile` | Smoke test on a fresh Ubuntu image. |

### Env-var escape hatches

- `DOTFILES_SKIP_TOOLS=1` — skip `setup-tools.sh` (use when tools are pre-baked into the image)
- `DOTFILES_AUTO_TMUX=1` — auto-attach to a `default` tmux session on shell start

## What's included

- **zsh** with zinit, starship prompt, fzf-tab, syntax-highlighting, autosuggestions, vi-mode
- **Neovim** (AstroNvim community config)
- **tmux** with TPM + vim-tmux-navigator, resurrect, continuum, yank
- CLI: fzf, bat, lsd, zoxide, ripgrep, fd, lazygit, yazi, direnv, mise
- Carbonfox/Nightfox theme across tmux, nvim, bat

## What's *not* included (vs the host dotfiles repo)

- macOS desktop tools (aerospace, sketchybar, yabai, ghostty)
- Host auth state (gh, op, github-copilot, glab-cli)
- Powerlevel10k (replaced with starship — faster cold start)
- Homebrew (replaced with apt + direct installers)
- `chsh` (set via `common-utils` feature or your base image's `SHELL` env)

## Manual usage

```bash
make stow     # symlink into $HOME
make unstow   # remove symlinks
make tools    # run setup-tools.sh
make test     # build + run the test Dockerfile
```
