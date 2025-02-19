#!/bin/bash

# TODO: This doesn't run the vscode-extensions.sh 

# Equivelant as the 'source' command
. scripts/utils.sh
. scripts/prerequisites.sh
. scripts/brew-install-custom.sh
. scripts/osx-defaults.sh
. scripts/symlinks.sh
. linux/install.sh

info "Dotfiles intallation initialized..."
read -p "Overwrite existing dotfiles? [y/n] " overwrite_dotfiles
read -p "Install apps? [y/n] " install_apps

if [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ "$install_apps" == "y" ]]; then
        printf "\n"
        info "===================="
        info "Prerequisites"
        info "===================="

        install_xcode
        install_homebrew

        printf "\n"
        info "===================="
        info "Apps"
        info "===================="

        run_brew_bundle
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
        install_linux_apps
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

chmod +x ./scripts/symlinks.sh
if [[ "$overwrite_dotfiles" == "y" ]]; then
    warning "Deleting existing dotfiles..."
    ./scripts/symlinks.sh --delete --include-files
fi
./scripts/symlinks.sh --create

success "Dotfiles set up successfully."
