# =============================================================================
# .zshrc — dev container edition
# =============================================================================

# Make ~/.local/bin available (where setup-tools.sh shims bat/fd live)
export PATH="$HOME/.local/bin:$PATH"

# direnv
command -v direnv >/dev/null && eval "$(direnv hook zsh)"

# -----------------------------------------------------------------------------
# zinit
# -----------------------------------------------------------------------------
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit ice depth=1
zinit light jeffreytse/zsh-vi-mode

zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found

autoload -Uz compinit && compinit
zinit cdreplay -q

# -----------------------------------------------------------------------------
# Prompt — starship (light, fast, no instant-prompt dance)
# -----------------------------------------------------------------------------
command -v starship >/dev/null && eval "$(starship init zsh)"

# -----------------------------------------------------------------------------
# Keys & history
# -----------------------------------------------------------------------------
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search
bindkey -v
export KEYTIMEOUT=1

HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
setopt appendhistory sharehistory hist_ignore_space hist_ignore_all_dups \
       hist_save_no_dups hist_ignore_dups hist_find_no_dups

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=**'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select
zstyle ':fzf-tab:complete:cd:*'             fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*'     fzf-preview 'ls --color $realpath'

# -----------------------------------------------------------------------------
# Aliases
# -----------------------------------------------------------------------------
command -v lsd >/dev/null && alias ls='lsd'
alias ll='ls -l'
alias la='ls -la'
alias c='clear'
alias ..='cd ../'
alias ...='cd ../../'

# Git
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gco='git checkout'
alias gl='git pull'
alias gp='git push'
alias gf='git fetch'

# Apps
alias nv='nvim'
alias lg='lazygit'
alias mux='tmuxinator'

# Debian aliases (in case ~/.local/bin shims aren't on PATH)
command -v batcat >/dev/null && ! command -v bat >/dev/null && alias bat='batcat'
command -v fdfind >/dev/null && ! command -v fd  >/dev/null && alias fd='fdfind'

# -----------------------------------------------------------------------------
# Shell integrations
# -----------------------------------------------------------------------------
command -v fzf    >/dev/null && eval "$(fzf --zsh)" 2>/dev/null
# zoxide uses `j` to avoid clashing with vi-mode z*
command -v zoxide >/dev/null && eval "$(zoxide init --cmd j zsh)"

# mise (language runtimes)
command -v mise >/dev/null && eval "$(mise activate zsh)"

# -----------------------------------------------------------------------------
# Editor
# -----------------------------------------------------------------------------
export EDITOR="nvim"
export VISUAL="nvim"

# -----------------------------------------------------------------------------
# Yazi cwd-on-quit helper
# -----------------------------------------------------------------------------
y() {
  local tmp; tmp="$(mktemp -t yazi-cwd.XXXXXX)" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# -----------------------------------------------------------------------------
# Opt-in: auto-attach tmux inside a container (set DOTFILES_AUTO_TMUX=1)
# -----------------------------------------------------------------------------
if [[ "${DOTFILES_AUTO_TMUX:-0}" == "1" ]] \
   && [ -f /.dockerenv ] \
   && command -v tmux >/dev/null \
   && [ -z "${TMUX:-}" ]; then
  if command -v tmuxinator >/dev/null && [ -f "$HOME/.config/tmuxinator/default.yml" ]; then
    tmux attach -t default 2>/dev/null || mux start default
  else
    tmux attach -t default 2>/dev/null || tmux new -s default
  fi
fi

# Per-machine overrides
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
