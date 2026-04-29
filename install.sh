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
SOFTLINKS_PERSONAL_CONFIG="$REPO_DIR/softlinks_config_personal.conf"
SOFTLINKS_WORK_CONFIG="$REPO_DIR/softlinks_config_work.conf"

terminal_only="n"
for arg in "$@"; do
    case "$arg" in
        --terminal-only) terminal_only="y" ;;
    esac
done

prompt_user_options() {
    if detect_work_machine; then
        is_work_machine="y"
    else
        is_work_machine="n"
    fi

    if [[ "$terminal_only" == "y" ]]; then
        overwrite_dotfiles="y"
        install_apps="y"
        info "Terminal-only mode: overwriting dotfiles and installing Brewfile.terminal only."
        return
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
        diff_configs+=("$SOFTLINKS_PERSONAL_CONFIG")
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
    if [[ "$install_apps" != "y" ]]; then return; fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
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

        install_brewfile "$REPO_DIR/homebrew/Brewfile.terminal"

        if [[ "$terminal_only" == "y" ]]; then return; fi

        install_brewfile "$REPO_DIR/homebrew/Brewfile.mac"
        if [[ "$is_work_machine" == "y" ]]; then
            info "Installing work Brewfile"
            install_brewfile "$REPO_DIR/homebrew/Brewfile.mac_work"
        else
            info "Installing personal Brewfile"
            install_brewfile "$REPO_DIR/homebrew/Brewfile.mac_personal"
        fi
    else
        printf "\n"
        info "===================="
        info "Setting Up Prerequisites"
        info "===================="

        install_linux_prerequisites
        install_homebrew

        printf "\n"
        info "===================="
        info "Installing CLI tools"
        info "===================="

        install_brewfile "$REPO_DIR/homebrew/Brewfile.terminal"

        printf "\n"
        info "===================="
        info "Installing Linux-specific non-brew CLI tools"
        info "===================="
        install_linux_cli_tools

        if [[ "$terminal_only" == "y" ]]; then return; fi

        printf "\n"
        info "===================="
        info "Installing Linux-specific Apps"
        info "===================="
        install_linux_apps
    fi
}

apply_platform_defaults() {
    if [[ "$terminal_only" == "y" ]]; then return; fi

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
    elif [[ "$terminal_only" != "y" ]]; then
        configs+=("$SOFTLINKS_PERSONAL_CONFIG")
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

    if [[ "$is_work_machine" == "y" ]]; then
        # work.gitconfig is symlinked to ~/.gitconfig. Work tooling auto-appends
        # machine-specific sections ([trace2], [githooks], etc.) below the
        # "# Work specific" marker. skip-worktree stops git from seeing those
        # changes in git status or accidentally overwriting the file on
        # git checkout. To commit intentional changes: temporarily disable with
        # `git update-index --no-skip-worktree git/global-config/work.gitconfig`,
        # stage and commit, then re-enable.
        info "Marking git/global-config/work.gitconfig as skip-worktree (work tooling manages sections below line 27)..."
        git -C "$REPO_DIR" update-index --skip-worktree git/global-config/work.gitconfig
    fi
}

setup_git_filters() {
    printf "\n"
    info "===================="
    info "Git Filters"
    info "===================="

    # Safety net for work.gitconfig: if skip-worktree is ever disabled and the
    # file is manually staged, this clean filter strips everything from the
    # "# Work specific" marker onward so the work-tooling sections ([trace2],
    # [githooks], etc.) can never accidentally land in a commit.
    # The smudge filter is a no-op — git never rewrites the file on checkout.
    # .gitattributes routes work.gitconfig through this filter (committed).
    # The filter definition lives in .git/config because it is machine-local.
    info "Registering 'strip-work-tooling' git filter for work.gitconfig..."
    git -C "$REPO_DIR" config filter.strip-work-tooling.clean "sed '/^# Work specific - kept here/,\$d'"
    git -C "$REPO_DIR" config filter.strip-work-tooling.smudge cat
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
setup_git_filters
setup_managed_files
success "Dotfiles set up successfully."

printf "\n"
if [[ -t 0 ]]; then
  info "Restarting zsh to apply changes..."
  exec zsh
fi
