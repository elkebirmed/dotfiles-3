#!/bin/bash
# -*-mode:sh-*- vim:ft=shell-script

# ~/dotfiles.sh
# =============================================================================
# Idempotent manual setup script to install or update shell dependencies.

set -e

info() {
	printf "\033[36m%s\033[0m\n" "$*" >&2
}

warn() {
	printf "\033[33mWarning: %s\033[0m\n" "$*" >&2
}

error() {
	printf "\033[31mError: %s\033[0m\n" "$*" >&2
	exit 1
}

is_installed() {
	type -P "$1" >/dev/null 2>&1
}

is_directory() {
    [ -d "$1" ]
}

info "[Dependencies] Update repositories & Upgrade dependencies"
sudo apt update && sudo apt upgrade -y

info "[Dependencies] Install dependencies"
sudo apt install -y \
    git \
    vim \
    zsh

# Bash-it
if ! is_directory ~/.bash_it; then
    info "[Prompt] Install Bash-it"
    git clone --quiet --depth=1 https://github.com/Bash-it/bash-it.git ~/.bash_it
    ~/.bash_it/install.sh --silent
fi

# Oh-my-zsh
if ! is_directory ~/.oh-my-zsh; then
    info "[Prompt] Install Oh-My-Zsh"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended
fi

# ZSH autosuggestions
if ! is_directory ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions; then
    info "[Prompt] Install Zsh-autosuggestions plugin"
    git clone --quiet --depth=1 https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
else
    info "[Prompt] Update Zsh-autosuggestions plugin"
    cd ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
    git pull --quiet
fi

# ZSH syntax highlighting
if ! is_directory ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting; then
    info "[Prompt] Install Zsh-syntax-highlighting plugin"
    git clone --quiet --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
else
    info "[Prompt] Update Zsh-syntax-highlighting plugin"
    cd ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
    git pull --quiet
fi

# Powerlevel10k
if ! is_directory ~/.oh-my-zsh/custom/themes/powerlevel10k; then
    info "[Prompt] Install Powerlevel10k theme"
    git clone --quiet --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
else
    info "[Prompt] Update Powerlevel10k theme"
    cd ~/.oh-my-zsh/custom/themes/powerlevel10k
    git pull --quiet
fi

# NVM
if ! is_installed nvm; then
    info "[NVM] Install"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
    nvm install node
fi

# TODO: Install Yarn, Docker, etc.

# Chezmoi
if ! is_installed chezmoi; then
    info "[Chezmoi] Install"
    sh -c "$(curl -fsLS chezmoi.io/get)"
fi

# Change shell to zsh
if ! [[ $(echo $SHELL) == *"zsh"* ]]; then
    info "[ZSH] Change shell to zsh"
    chsh -s "$(which zsh)"
fi

# Apply dotfiles
info "[Dotfiles] Apply dotfiles"
chezmoi apply

info "Done ✔️"