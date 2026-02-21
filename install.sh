#!/bin/bash
set -e

# Equivelant as the 'source' command
. scripts/utils.sh
. scripts/prerequisites.sh
. scripts/brew-install-custom.sh
. scripts/osx-defaults.sh
. scripts/links.sh
. linux/install_debian.sh

# Load environment variables from .env if present
if [ -f ".env" ]; then
    . .env
fi

# WORK_HOSTNAMES should be a space-separated list defined in .env
# e.g. WORK_HOSTNAMES="hostname1 hostname2"
read -ra WORK_HOSTNAMES <<< "${WORK_HOSTNAMES:-}"

prompt_user_options() {
    # Auto-detect work machine by hostname
    CURRENT_HOSTNAME=$(hostname -s)
    is_work_machine="n"
    for wh in "${WORK_HOSTNAMES[@]}"; do
        if [ "$CURRENT_HOSTNAME" == "$wh" ]; then
            is_work_machine="y"
            info "Work machine detected (hostname: $CURRENT_HOSTNAME)"
            break
        fi
    done

    printf "\n"
    info "Checking existing dotfiles..."
    if [[ "$is_work_machine" == "y" ]]; then
        info "Comparing with work dotfiles..."
        if ./scripts/links.sh --show-diffs --work-conf; then printf "\n"; fi
    else
        info "Comparing with personal dotfiles..."
        if ./scripts/links.sh --show-diffs; then printf "\n"; fi
    fi


    read -p "Overwrite existing dotfiles? [y/n] " overwrite_dotfiles
    read -p "Install apps? [y/n] " install_apps
}

install_platform_apps() {
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
    else
        if [[ "$install_apps" == "y" ]]; then
            printf "\n"
            info "===================="
            info "Installing Ubuntu Apps"
            info "===================="
            install_linux_cli_tools
            install_linux_apps
        fi
    fi
}

apply_platform_defaults() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        printf "\n"
        info "===================="
        info "OSX System Defaults"
        info "===================="

        register_keyboard_shortcuts
        apply_osx_system_defaults
    else
        if [[ "$install_apps" == "y" ]]; then
            configure_linux_settings
        fi
    fi
}

setup_terminal() {
    printf "\n"
    info "===================="
    info "Terminal"
    info "===================="

    info "Adding .hushlogin file to suppress 'last login' message in terminal..."
    touch ~/.hushlogin
}

setup_links() {
    printf "\n"
    info "===================="
    info "Symbolic Links"
    info "===================="

    chmod +x ./scripts/links.sh
    if [[ "$overwrite_dotfiles" == "y" ]]; then
        warning "Deleting existing dotfiles..."
        ./scripts/links.sh --delete --include-files
    else
        if [[ "$is_work_machine" != "y" ]]; then
            info "Adopting existing files into repo..."
            ./scripts/links.sh --adopt
        fi
    fi
    ./scripts/links.sh --create
    if [[ "$is_work_machine" == "y" ]]; then
        if [[ "$overwrite_dotfiles" == "y" ]]; then
            warning "Deleting existing work dotfiles..."
            ./scripts/links.sh --delete --include-files --work-conf
        else
            info "Adopting existing work files into repo..."
            ./scripts/links.sh --adopt --work-conf
        fi
        ./scripts/links.sh --create --work-conf
    fi
}

info "Dotfiles installation initialized..."
prompt_user_options
install_platform_apps
apply_platform_defaults
setup_terminal
setup_links
success "Dotfiles set up successfully."

printf "\n"

info "Restarting zsh to apply changes..."
exec zsh
