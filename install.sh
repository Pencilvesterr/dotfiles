#!/bin/bash
set -e

# Equivelant as the 'source' command
. scripts/utils.sh
. scripts/prerequisites.sh
. scripts/brew-install-custom.sh
. scripts/osx-defaults.sh
. scripts/links.sh
. linux/install_debian.sh

SOFTLINKS_CONFIG="$SCRIPT_DIR/../softlinks_config.conf"
SOFTLINKS_WORK_CONFIG="$SCRIPT_DIR/../softlinks_config_work.conf"

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
        ./scripts/links.sh --show-diffs --work-conf || _diffs_exit=$?
    else
        info "Comparing with personal dotfiles..."
        ./scripts/links.sh --show-diffs || _diffs_exit=$?
    fi
    _diffs_exit="${_diffs_exit:-0}"
    [ "$_diffs_exit" -eq 0 ] && printf "\n"
    [ "$_diffs_exit" -gt 1 ] && exit "$_diffs_exit"


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
        ./scripts/links.sh --delete --include-files "$SOFTLINKS_CONFIG"
    else
        if [[ "$is_work_machine" != "y" ]]; then
            info "Adopting existing files into repo..."
            ./scripts/links.sh --adopt "$SOFTLINKS_CONFIG"
        fi
    fi
    ./scripts/links.sh --create "$SOFTLINKS_CONFIG"
    if [[ "$is_work_machine" == "y" ]]; then
        if [[ "$overwrite_dotfiles" == "y" ]]; then
            warning "Deleting existing work dotfiles..."
            ./scripts/links.sh --delete --include-files "$SOFTLINKS_WORK_CONFIG"
        else
            info "Adopting existing work files into repo..."
            ./scripts/links.sh --adopt "$SOFTLINKS_WORK_CONFIG"
        fi
        ./scripts/links.sh --create "$SOFTLINKS_WORK_CONFIG"
    fi

    # Link the correct .gitconfig based on machine type
    if [[ "$is_work_machine" == "y" ]]; then
        gitconfig_source="$(pwd)/git/global-config/work.gitconfig"
    else
        gitconfig_source="$(pwd)/git/global-config/personal.gitconfig"
    fi
    gitconfig_target="$HOME/.gitconfig"
    if [ -f "$gitconfig_target" ] && [ ! -L "$gitconfig_target" ] && [[ "$overwrite_dotfiles" != "y" ]]; then
        info "Adopting existing $gitconfig_target..."
        cp "$gitconfig_target" "$gitconfig_source"
        rm "$gitconfig_target"
        success "Adopted: $gitconfig_target -> $gitconfig_source"
    fi
    ln -sf "$gitconfig_source" "$gitconfig_target"
    success "Linked: $gitconfig_target -> $gitconfig_source"
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
