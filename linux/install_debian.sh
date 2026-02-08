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


# TODO: Extract these into their own functions for modularity/ ease of disabling
install_linux_cli_tools() {
    # Get sudo permissions from the start
    sudo apt update

    info "Checking for essential prerequisites"
    # Install curl, gpg, ca-certificates needed for adding repos/downloading, and build-essential for compiling
    # Don't bother installing if they already exist
    if ! command -v curl &> /dev/null || ! command -v gpg &> /dev/null || ! command -v ca-certificates &> /dev/null || ! command -v build-essential &> /dev/null; then
        info "Installing essential prerequisites"
        sudo apt-get install -y curl gpg ca-certificates build-essential
    else
        info "curl, gpg, ca-certificates, and build-essential are already installed."
    fi
    
    info "Checking for vim..."
    if ! command -v vim &> /dev/null; then
        info "Installing vim"
        sudo apt install vim -y
    else
        info "vim is already installed."
    fi

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

    # Have to install the binary as well as 
    info "Checking for zoxide..."
    if ! command -v zoxide &> /dev/null; then
        info "Install zoxide"
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    else
        info "zoxide is already installed."
    fi

    info "Checking for fixit..."
      if ! command -v fixit &> /dev/null; then
          echo "deb [arch=$(dpkg --print-architecture) trusted=yes] https://eugene-babichenko.github.io/fixit/ppa ./" | sudo tee /etc/apt/sources.list.d/fixit.list > /dev/null
          sudo apt update
          sudo apt install fixit
      else
          info "zoxide is already installed."
      fi



    info "Checking for Neovim..."
    if ! command -v nvim &> /dev/null; then
        info "Installing neovim"
        # Check CPU architecture
        ARCH=$(uname -m)
        if [ "$ARCH" = "x86_64" ]; then
            info "Detected x86_64 architecture"
            NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
        elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
            info "Detected ARM64 architecture"
            NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz"
        else
            error "Unsupported architecture: $ARCH"
            return 1
        fi
        
        curl -LO $NVIM_URL
        sudo rm -rf /opt/nvim
        sudo tar -C /opt -xzf nvim-linux-*.tar.gz
        info "Adding neovim to PATH"
        sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
        rm nvim-linux-*.tar.gz # Clean up downloaded archive
    else
        info "Neovim is already installed."
    fi
    
    info "Checking for Ranger..."
    if ! command -v ranger &> /dev/null; then
        info "Installing Ranger"
        sudo apt install ranger -y
    else
        info "Ranger is already installed."
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


    info "Checking for fzf..."
    if ! command -v fzf &> /dev/null; then
        info "Install fzf"
        sudo apt install fzf -y
    else
        info "fzf is already installed."
    fi

    info "Checking for starship..."
    if ! command -v starship &> /dev/null; then
        info "Install starship"
        curl -sS https://starship.rs/install.sh | sh -s -- -y # Add -y for non-interactive install
    else
        info "starship is already installed."
    fi

    info "Checking for eza..."
    if ! command -v eza &> /dev/null; then
        info "Install eza (ls replacement)"
        sudo apt install -y gpg
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
        sudo apt update
        sudo apt install -y eza
    else
        info "eza is already installed."
    fi

    info "Checking for bat..."
    # Check for the command itself and the symlink target
    if ! command -v bat &> /dev/null || ! command -v batcat &> /dev/null ; then
        info "Installing bat"
        sudo apt install bat -y
        # Create symlink only if batcat exists and bat doesn't (or points elsewhere)
        if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
             mkdir -p ~/.local/bin
             ln -sf /usr/bin/batcat ~/.local/bin/bat
             info "Created symlink for bat -> batcat in ~/.local/bin"
        fi
    else
        info "bat (or batcat) is already installed."
        # Ensure symlink exists if batcat is installed but bat isn't the direct command
        if command -v batcat &> /dev/null && [ "$(readlink -f $(which bat))" != "/usr/bin/batcat" ]; then
             mkdir -p ~/.local/bin
             ln -sf /usr/bin/batcat ~/.local/bin/bat
             info "Ensured symlink for bat -> batcat in ~/.local/bin"
        fi
    fi

    info "Checking for speedtest..."
    if ! command -v speedtest &> /dev/null; then
        info "Installing speedtest"
        # Ensure curl is installed
        if ! command -v curl &> /dev/null; then
            sudo apt-get install -y curl
        fi
        # Add repo and install
        curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
        sudo apt-get install speedtest -y
    else
        info "speedtest is already installed."
    fi

    info "Checking for Lazygit..."
    if ! command -v lazygit &> /dev/null; then
        info "Installing Lazygit"
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf lazygit.tar.gz lazygit
        sudo install lazygit -D -t /usr/local/bin/
        rm lazygit lazygit.tar.gz # Clean up
    else
        info "Lazygit is already installed."
    fi

    info "Checking for ripgrep (rg)..."
    if ! command -v rg &> /dev/null; then
        info "Installing ripgrep"
        sudo apt-get install ripgrep -y
    else
        info "ripgrep is already installed."
    fi

    info "Checking for Lua and Luarocks..."
    LUA_INSTALLED=false
    LUAROCKS_INSTALLED=false
    if command -v lua &> /dev/null || command -v lua5.4 &> /dev/null; then
        info "Lua is already installed."
        LUA_INSTALLED=true
    fi
    if command -v luarocks &> /dev/null; then
        info "Luarocks is already installed."
        LUAROCKS_INSTALLED=true
    fi

    if [ "$LUA_INSTALLED" = false ] || [ "$LUAROCKS_INSTALLED" = false ]; then
        info "Installing Lua 5.4 and/or Luarocks via apt"
        sudo apt install lua5.4 luarocks -y
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
