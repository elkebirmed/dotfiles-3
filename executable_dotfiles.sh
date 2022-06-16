#!/bin/sh
# -*-mode:sh-*- vim:ft=shell-script

# ~/dotfiles.sh
# =============================================================================
# Idempotent manual setup script to install or update shell dependencies.

set -e

command_exists() {
    command -v "$@" >/dev/null 2>&1
}

error() {
    printf -- "%sError: $*%s\n" >&2 "$RED" "$RESET"
}

setup_color() {
    # Only use colors if connected to a terminal
    if [ -t 1 ]; then
        RED=$(printf '\033[31m')
        GREEN=$(printf '\033[32m')
        # YELLOW=$(printf '\033[33m')
        BLUE=$(printf '\033[34m')
        BOLD=$(printf '\033[1m')
        RESET=$(printf '\033[m')
    else
        RED=""
        GREEN=""
        # YELLOW=""
        BLUE=""
        BOLD=""
        RESET=""
    fi
}

setup_dependencies() {
    printf -- "\n%sSetting up dependencies:%s\n\n" "$BOLD" "$RESET"

    # Install Homebrew packages
    if command -v brew > /dev/null; then
        printf -- "%sInstalling/updating apps using Homebrew...%s\n" "$BLUE" "$RESET"
        brew bundle --global
    fi
}

setup_prompts() {
    printf -- "\n%sSetting up shell frameworks:%s\n\n" "$BOLD" "$RESET"

    # Install Oh My Zsh
    PACKAGE_NAME='Oh My Zsh'
    printf -- "%sInstalling/updating %s...%s\n" "$BLUE" "$PACKAGE_NAME" "$RESET"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    # Install Zsh plugins
    PACKAGE_NAME='zsh-autosuggestions'
    printf -- "%sInstalling/updating Zsh plugin: %s...%s\n" "$BLUE" "$PACKAGE_NAME" "$RESET"
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

    PACKAGE_NAME='zsh-syntax-highlighting'
    printf -- "%sInstalling/updating Zsh plugin: %s...%s\n" "$BLUE" "$PACKAGE_NAME" "$RESET"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

    PACKAGE_NAME='Powerlevel10k'
    printf -- "%sInstalling/updating Zsh theme: %s...%s\n" "$BLUE" "$PACKAGE_NAME" "$RESET"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
}

setup_applications() {
    printf -- "\n%sSetting up CLI applications:%s\n\n" "$BOLD" "$RESET"

    # Install Nano syntax highlighting files
    PACKAGE_NAME='Nano syntax highlighting'
    CHEZMOIPATH=$(chezmoi source-path)
    rm -rf "$CHEZMOIPATH"/dot_nano/nanorc
    printf -- "%sInstalling/updating %s...%s\n" "$BLUE" "$PACKAGE_NAME" "$RESET"
    import_repo 'https://github.com/scopatz/nanorc/archive/master.tar.gz' "${HOME}/.nano" || {
        error "import of ${PACKAGE_NAME} failed"
        exit 1
    }

    # Install Ultimate Vim Configuration
    PACKAGE_NAME='Ultimate vimrc'
    printf -- "%sInstalling/updating %s...%s\n" "$BLUE" "$PACKAGE_NAME" "$RESET"
    import_repo 'https://github.com/amix/vimrc/archive/master.tar.gz' "${HOME}/.vim_runtime" || {
        error "import of ${PACKAGE_NAME} failed"
        exit 1
    }

    # Install micro plugins
    if command -v micro; then
        printf -- "%sInstalling/updating micro plugins...%s\n" "$BLUE" "$RESET"
        OUT_OF_DATE='installed but out-of-date'
        if  micro -plugin install filemanager | tee -a /dev/tty | grep -q "$OUT_OF_DATE"; then
            micro -plugin update  filemanager
        fi
        if  micro -plugin install manipulator | tee -a /dev/tty | grep -q "$OUT_OF_DATE"; then
            micro -plugin update  manipulator
        fi
        if  micro -plugin install misspell | tee -a /dev/tty | grep -q "$OUT_OF_DATE"; then
            micro -plugin update  misspell
        fi
        if  micro -plugin install misspell | tee -a /dev/tty | grep -q "$OUT_OF_DATE"; then
            micro -plugin update  misspell
        fi
        if  micro -plugin install wc | tee -a /dev/tty | grep -q "$OUT_OF_DATE"; then
            micro -plugin update  wc
        fi
    fi
}

# shellcheck source=/dev/null
setup_devtools() {
    printf -- "\n%sSetting up development tools:%s\n\n" "$BOLD" "$RESET"

    command_exists git || {
        error "git is not installed"
        exit 1
    }

    # Install ASDF Versionn Manager
    # https://asdf-vm.com/
    if ! command -v brew > /dev/null; then
        printf -- "%sInstalling/updating ASDF Extendable Version Manager...%s\n" "$BLUE" "$RESET"
        export ASDF_DIR="${ASDF_DIR:-$HOME/.asdf}" && (
            ASDF_NEW=false
            if [ ! -d "$ASDF_DIR" ]; then
                git clone https://github.com/asdf-vm/asdf.git "$NVM_DIR"
                ASDF_NEW=true
            fi
            cd "$ASDF_DIR"
            if [ $ASDF_NEW ]; then
                git checkout "$(git describe --abbrev=0 --tags)"
            else
                asdf update
            fi
        ) && \. "$ASDF_DIR/nvm.sh" && ([ -z "$BASH_VERSION" ] || \. "$ASDF_DIR/completions/asdf.bash")
    fi

    printf -- "%sInstalling/updating ASDF plugins...%s\n" "$BLUE" "$RESET"
    asdf plugin add golang
    asdf plugin add nodejs
    asdf plugin add php
    asdf plugin add python
    asdf plugin add ruby
    asdf plugin update --all

    printf -- "%sImporting PGP keyrings for ASDF plugins...%s\n" "$BLUE" "$RESET"
    "$HOME"/.asdf/plugins/nodejs/bin/import-release-team-keyring

    # asdf install golang latest
    asdf install nodejs latest
    asdf install php latest
    asdf install python latest

    # Install NVM
    printf -- "%sInstalling/updating Node Version Manager...%s\n" "$BLUE" "$RESET"
    export NVM_DIR="$HOME/.nvm" && (
        NVM_NEW=false
        if [ ! -d "$NVM_DIR" ]; then
            git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
            NVM_NEW=true
        fi
        cd "$NVM_DIR"
        if [ ! $NVM_NEW ]; then
            git fetch --tags origin
        fi
        HASH=$(git describe --abbrev=0 --tags --match "v[0-9]*" "$(git rev-list --tags --max-count=1)")
        git checkout "$HASH"
    ) && \. "$NVM_DIR/nvm.sh" && \. "$NVM_DIR/bash_completion"

    # Install Node.js
    printf -- "%sInstalling/updating Node.js...%s\n" "$BLUE" "$RESET"
    nvm install node
}

finalize_dotfiles() {
    printf -- "\n%sFinalizing dotfiles:%s\n\n" "$BOLD" "$RESET"

    printf -- "%sUpdating dotfiles at destination...%s\n" "$BLUE" "$RESET"
    chezmoi apply
}

main() {
    printf -- "\n%sDotfiles setup script%s\n" "$BOLD" "$RESET"

    command_exists chezmoi || {
        error "chezmoi is not installed"
        exit 1
    }

    sudo apt update && sudo apt upgrade -y
    sudo apt install -y \
        git \
        vim \
        neovim \
        zsh
    
    chsh -s $(which zsh)

    setup_dependencies
    setup_color
    setup_prompts
    setup_applications
    setup_devtools
    finalize_dotfiles

    printf -- "\n%sDone.%s\n\n" "$GREEN" "$RESET"

    # if [ -n "`$SHELL -c 'echo $ZSH_VERSION'`" ]; then
    #    [ -s "$HOME/.zshrc" ] && \. "$HOME/.zshrc"
    # elif [ -n "`$SHELL -c 'echo $BASH_VERSION'`" ]; then
    #    [ -s "$HOME/.bashrc" ] && \. "$HOME/.bashrc"
    # fi
}

main "$@"