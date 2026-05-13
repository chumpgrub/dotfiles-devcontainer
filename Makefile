.PHONY: install stow unstow tools test

install:
	./install.sh

stow:
	stow --restow --target=$$HOME .

unstow:
	stow -D --target=$$HOME .

tools:
	./setup-tools.sh

test:
	docker build -t dotfiles-devcontainer-test -f test/Dockerfile .
	docker run --rm -it dotfiles-devcontainer-test
