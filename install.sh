#!/bin/bash
set -e

REPO_DIR="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"

. "$REPO_DIR/scripts/utils.sh"
. "$REPO_DIR/scripts/prerequisites.sh"
. "$REPO_DIR/scripts/brew-install-custom.sh"
. "$REPO_DIR/scripts/non-homebrew-install.sh"
. "$REPO_DIR/mac_config/osx-defaults.sh"
. "$REPO_DIR/linux/install_debian.sh"

SOFTLINKS_CONFIG="$REPO_DIR/softlinks_config.conf"
SOFTLINKS_MAC_CONFIG="$REPO_DIR/softlinks_config_mac.conf"
SOFTLINKS_WORK_CONFIG="$REPO_DIR/softlinks_config_work.conf"


prompt_user_options() {
    if detect_work_machine; then
        is_work_machine="y"
    else
        is_work_machine="n"
    fi

    printf "\n"
    info "Checking existing dotfiles..."
    local diff_configs=("$SOFTLINKS_CONFIG")
    if [[ "$OSTYPE" == "darwin"* ]]; then
        diff_configs+=("$SOFTLINKS_MAC_CONFIG")
    fi
    if [[ "$is_work_machine" == "y" ]]; then
        diff_configs+=("$SOFTLINKS_WORK_CONFIG")
        info "Comparing with work dotfiles..."
    else
        info "Comparing with personal dotfiles..."
    fi
    ./scripts/links.sh --show-diffs "${diff_configs[@]}" || _diffs_exit=$?
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
            install_non_homebrew

            printf "\n"
            info "===================="
            info "Installing Apps"
            info "===================="

            install_brewfile "$REPO_DIR/homebrew/Brewfile"
            install_brewfile "$REPO_DIR/homebrew/Brewfile.mac"
            if [[ "$is_work_machine" == "y" ]]; then
                info "Installing work Brewfile"
                install_brewfile "$REPO_DIR/homebrew/Brewfile.work"
            else
                info "Installing personal Brewfile"
                install_brewfile "$REPO_DIR/homebrew/Brewfile.personal"
            fi
        fi
    else
        if [[ "$install_apps" == "y" ]]; then
            printf "\n"
            info "===================="
            info "Setting Up Prerequisites"
            info "===================="

            install_linux_prerequisites
            install_homebrew

            printf "\n"
            info "===================="
            info "Installing Apps"
            info "===================="

            install_brewfile "$REPO_DIR/homebrew/Brewfile"

            printf "\n"
            info "===================="
            info "Installing Linux-specific Apps"
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

    # Collect all applicable config files
    local configs=("$SOFTLINKS_CONFIG")
    if [[ "$OSTYPE" == "darwin"* ]]; then
        configs+=("$SOFTLINKS_MAC_CONFIG")
    fi
    if [[ "$is_work_machine" == "y" ]]; then
        configs+=("$SOFTLINKS_WORK_CONFIG")
    fi

    for config in "${configs[@]}"; do
        if [[ "$overwrite_dotfiles" == "y" ]]; then
            warning "Deleting existing dotfiles from $(basename "$config")..."
            ./scripts/links.sh --delete --include-files "$config"
        else
            info "Adopting existing files from $(basename "$config")..."
            ./scripts/links.sh --adopt "$config"
        fi
        ./scripts/links.sh --create "$config"
    done
}

setup_local_overrides() {
    printf "\n"
    info "===================="
    info "Local Overrides"
    info "===================="

    info "Marking zsh/local.zsh as skip-worktree (local changes will not be tracked)..."
    git -C "$REPO_DIR" update-index --skip-worktree zsh/local.zsh
}

setup_managed_files() {
    printf "\n"
    info "===================="
    info "Managed Files"
    info "===================="

    if [[ "$overwrite_dotfiles" != "y" ]]; then
        info "Adopting existing managed files into repo..."
        ./scripts/sync.sh pull
    fi
    ./scripts/sync.sh push
}

info "Dotfiles installation initialized..."
prompt_user_options
install_platform_apps
apply_platform_defaults
setup_terminal
setup_links
setup_local_overrides
setup_managed_files
success "Dotfiles set up successfully."

printf "\n"

info "Restarting zsh to apply changes..."
exec zsh
