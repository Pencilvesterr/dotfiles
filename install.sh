#!/bin/bash
set -e

REPO_DIR="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"

. "$REPO_DIR/scripts/utils.sh"
. "$REPO_DIR/scripts/prerequisites.sh"
. "$REPO_DIR/scripts/brew-install-custom.sh"
. "$REPO_DIR/mac_config/osx-defaults.sh"
. "$REPO_DIR/linux/install_debian.sh"

SOFTLINKS_CONFIG="$REPO_DIR/softlinks_config.conf"
SOFTLINKS_WORK_CONFIG="$REPO_DIR/softlinks_config_work.conf"


prompt_user_options() {
    if detect_work_machine; then
        is_work_machine="y"
    else
        is_work_machine="n"
    fi

    printf "\n"
    info "Checking existing dotfiles..."
    if [[ "$is_work_machine" == "y" ]]; then
        info "Comparing with work dotfiles..."
        ./scripts/links.sh --show-diffs "$SOFTLINKS_CONFIG" "$SOFTLINKS_WORK_CONFIG" || _diffs_exit=$?
    else
        info "Comparing with personal dotfiles..."
        ./scripts/links.sh --show-diffs "$SOFTLINKS_CONFIG" || _diffs_exit=$?
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
