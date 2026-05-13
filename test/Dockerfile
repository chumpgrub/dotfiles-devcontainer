# Smoke test for dotfiles-devcontainer.
#   docker build -t dotfiles-devcontainer-test -f test/Dockerfile .
#   docker run --rm -it dotfiles-devcontainer-test
#
# Verifies that setup-tools.sh + install.sh work end-to-end on a fresh Ubuntu
# image with a non-root user (matching how dev containers actually run).
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq \
 && apt-get install -y -qq --no-install-recommends sudo ca-certificates curl git \
 && useradd -m -s /bin/bash vscode \
 && echo 'vscode ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/vscode \
 && rm -rf /var/lib/apt/lists/*

USER vscode
WORKDIR /home/vscode

COPY --chown=vscode:vscode . /home/vscode/.dotfiles

RUN /home/vscode/.dotfiles/setup-tools.sh \
 && /home/vscode/.dotfiles/install.sh

# Sanity checks
RUN command -v zsh && command -v nvim && command -v tmux && command -v starship \
 && command -v lsd && command -v lazygit && command -v yazi \
 && test -L /home/vscode/.zshrc \
 && test -L /home/vscode/.config/nvim

CMD ["/usr/bin/zsh", "-l"]
