#!/bin/bash
set -e

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "$SCRIPT_DIR/scripts/utils.sh"
. "$SCRIPT_DIR/scripts/prerequisites.sh"
. "$SCRIPT_DIR/scripts/brew-install-custom.sh"
. "$SCRIPT_DIR/scripts/osx-defaults.sh"
. "$SCRIPT_DIR/linux/install_debian.sh"

# Load .env — required before continuing
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    error "Missing .env file. Copy .env.example to .env and fill in your values."
    exit 1
fi
source "$SCRIPT_DIR/.env"

if [ -z "$WORK_HOSTNAMES" ]; then
    error "WORK_HOSTNAMES is not set in .env. See .env.example."
    exit 1
fi

is_work_machine() {
    local current_hostname
    current_hostname=$(hostname)
    for h in $WORK_HOSTNAMES; do
        [[ "$current_hostname" == "$h" ]] && return 0
    done
    return 1
}

info "Dotfiles installation initialized..."
read -p "Install apps? [y/n] " install_apps

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

        install_brewfile "$SCRIPT_DIR/homebrew/Brewfile"
        if is_work_machine; then
            info "Work machine detected — installing work Brewfile"
            install_brewfile "$SCRIPT_DIR/homebrew/Brewfile.work"
        else
            info "Personal machine — installing personal Brewfile"
            install_brewfile "$SCRIPT_DIR/homebrew/Brewfile.personal"
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
info "Dotfiles (chezmoi)"
info "===================="

# Ensure chezmoi is installed
if ! command -v chezmoi &>/dev/null; then
    info "Installing chezmoi..."
    brew install chezmoi
fi

# Bootstrap chezmoi config to point at this repo, with work detection data
mkdir -p ~/.config/chezmoi
if [ ! -f ~/.config/chezmoi/chezmoi.toml ]; then
    IS_WORK=false
    is_work_machine && IS_WORK=true
    cat > ~/.config/chezmoi/chezmoi.toml << EOF
sourceDir = "$SCRIPT_DIR"

[data]
  isWork = $IS_WORK
EOF
    info "Created chezmoi config (isWork=$IS_WORK) pointing to $SCRIPT_DIR"
fi

info "Applying dotfiles with chezmoi..."
chezmoi apply

success "Dotfiles set up successfully."

printf "\n"
info "Restarting zsh to apply changes..."
exec zsh
