#!/bin/bash
set -e
# TODO: This doesn't run the vscode-extensions.sh

# Equivelant as the 'source' command
. scripts/utils.sh
. scripts/prerequisites.sh
. scripts/brew-install-custom.sh
. scripts/osx-defaults.sh
. scripts/symlinks.sh
. linux/install_debian.sh

info "Dotfiles intallation initialized..."
read -p "Overwrite existing dotfiles? [y/n] " overwrite_dotfiles
read -p "Install apps? [y/n] " install_apps
read -p "Work machine? [y/n] " is_work_machine

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

chmod +x ./scripts/symlinks.sh
if [[ "$overwrite_dotfiles" == "y" ]]; then
    warning "Deleting existing dotfiles..."
    ./scripts/symlinks.sh --delete --include-files
fi
./scripts/symlinks.sh --create
if [[ "$is_work_machine" == "y" ]]; then
    info "Installing work symlinks"
    warning "Deleting existing work dotfiles..."
    ./scripts/symlinks.sh --delete --include-files --work-conf
    ./scripts/symlinks.sh --create --work-conf
fi
success "Dotfiles set up successfully."

info "Restarting zsh to apply changes..."
/bin/zsh
