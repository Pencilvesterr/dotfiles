#!/bin/bash
set -e
# TODO: This doesn't run the vscode-extensions.sh

# Equivelant as the 'source' command
. scripts/utils.sh
. scripts/prerequisites.sh
. scripts/brew-install-custom.sh
. scripts/osx-defaults.sh
. scripts/links.sh
. linux/install_debian.sh

info "Dotfiles intallation initialized..."
read -p "Overwrite existing dotfiles? [y/n] " overwrite_dotfiles
read -p "Install apps? [y/n] " install_apps
read -p "Work machine? [y/n] " is_work_machine

if [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ "$install_apps" == "y" ]]; then
        printf "\n"
        info "===================="
        info "Setting Up Prerequisites"
        info "===================="

        install_xcode
        install_homebrew

        printf "\n"
        info "===================="
        info "Installing Apps"
        info "===================="

        install_brewfile "$SCRIPT_DIR/../homebrew/Brewfile"
        if [[ "$is_work_machine" == "y" ]]; then
            info "Installing work Brewfile"
            install_brewfile "$SCRIPT_DIR/../homebrew/Brewfile.work"
        else
          info "Installing personal Brewfile"
          install_brewfile "$SCRIPT_DIR/../homebrew/Brewfile.personal"
        fi
    fi

    printf "\n"
    info "===================="
    info "OSX System Defaults"
    info "===================="

    register_keyboard_shortcuts
    apply_osx_system_defaults
else
    if [[ "$install_apps" == "y" ]]; then
        printf "\n"
        info "===================="
        info "Installing Ubuntu Apps"
        info "===================="
        install_linux_cli_tools
        install_linux_apps
        configure_linux_settings
    fi
fi

printf "\n"
info "===================="
info "Terminal"
info "===================="

info "Adding .hushlogin file to suppress 'last login' message in terminal..."
touch ~/.hushlogin

printf "\n"
info "===================="
info "Symbolic Links"
info "===================="

chmod +x ./scripts/links.sh
if [[ "$overwrite_dotfiles" == "y" ]]; then
    warning "Deleting existing dotfiles..."
    ./scripts/links.sh --delete --include-files
fi
./scripts/links.sh --create
if [[ "$is_work_machine" == "y" ]]; then
    info "Installing work hardlinks"
    warning "Deleting existing work dotfiles..."
    ./scripts/links.sh --delete --include-files --work-conf
    ./scripts/links.sh --create --work-conf
fi
success "Dotfiles set up successfully."

printf "\n"
info "===================="
info "Git Hooks"
info "===================="

# Install git hooks if we're in a git repository
if [ -d ".git" ]; then
    info "Installing git pre-commit hook..."
    if [ -f "git/hooks/pre-commit" ]; then
        cp git/hooks/pre-commit .git/hooks/pre-commit
        chmod +x .git/hooks/pre-commit
        success "Git pre-commit hook installed"
    else
        warning "Git hook file not found: git/hooks/pre-commit"
    fi
else
    warning "Not a git repository, skipping git hooks installation"
fi

info "Restarting zsh to apply changes..."
exec zsh
