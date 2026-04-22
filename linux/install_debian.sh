#!/bin/bash
set -e
# All setup assumes a ubuntu based distro
# Note: `apt install` and `apt-get install` are both the same, but apt install is easier/has less options

# Get the absolute path of the directory where the script is located
# Get the git root dir
GIT_ROOT_DIR="$(git rev-parse --show-toplevel)"

SCRIPT_DIR="$GIT_ROOT_DIR/scripts"

. $SCRIPT_DIR/utils.sh

configure_linux_settings() {
    info "Configuring Linux settings"
    # Switch caps and esc
    dconf write /org/gnome/desktop/input-sources/xkb-options "['caps:escape']"
}

install_linux_apps() {
    if ! command -v wezterm &> /dev/null; then
        info "Installing Wezterm"
        curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /etc/apt/keyrings/wezterm-fury.gpg
        echo 'deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
        sudo apt update
        sudo apt install wezterm
    else
        info "Wezterm is already installed."
    fi
}

install_linux_cli_tools() {
    info "Checking for Docker..."
    if ! command -v docker &> /dev/null; then
        info "Installing Docker"
        curl -fsSL https://get.docker.com -o install-docker.sh
        sudo sh install-docker.sh
        sudo rm install-docker.sh
        # Post install steps
        sudo groupadd docker || true
        sudo usermod -aG docker $USER
        info "Docker group membership added. Please log out and log back in for it to take effect."
        # Start docker on boot
        sudo systemctl enable docker.service
        sudo systemctl enable containerd.service
    else
        info "Docker is already installed."
    fi

    info "Checking for OpenSSH Server..."
    # Check if sshd service is active or if package is installed
    if ! dpkg -s openssh-server &> /dev/null && ! systemctl is-active --quiet sshd; then
        info "Installing OpenSSH Server"
        sudo apt install openssh-server -y
    else
        info "OpenSSH Server is already installed or running."
    fi

    info "Checking for ZSH..."
    if ! command -v zsh &> /dev/null; then
        info "Install ZSH"
        sudo apt install zsh -y
    else
        info "ZSH is already installed."
    fi

    # Setting zsh as default shell should happen regardless of install, but only if it's not already the default
    if [ "$(basename "$SHELL")" != "zsh" ]; then
        info "Setting zsh as default shell"
        if command -v zsh &> /dev/null; then
            sudo chsh -s $(which zsh)
            info "Default shell changed to ZSH. Please log out and log back in for the change to take effect."
        else
            warning "ZSH is not installed. Cannot set it as default."
        fi
    else
        info "ZSH is already the default shell."
    fi

    info "Checking for libfuse2 (for AppImage)..."
    if ! dpkg -s libfuse2 &> /dev/null; then
        info "Install libfuse2"
        sudo apt install libfuse2 -y
    else
        info "libfuse2 is already installed."
    fi

    info "Checking for Nerd Fonts (JetBrains Mono)..."
    # Simple check: see if the directory exists and is not empty
    FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerd"
    if [ ! -d "$FONT_DIR" ] || [ -z "$(ls -A $FONT_DIR)" ]; then
        info "Install nerd fonts (JetBrains Mono)"
        # Create a specific directory for these fonts
        mkdir -p "$FONT_DIR"
        TMP_ZIP=$(mktemp --suffix=.zip)
        wget -O "$TMP_ZIP" https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip && \
            unzip -o "$TMP_ZIP" -d "$FONT_DIR" && \
            rm "$TMP_ZIP" && \
            info "Updating font cache..." && \
            fc-cache -fv
    else
        info "Nerd Fonts (JetBrains Mono) directory exists. Assuming fonts are installed."
    fi
}
