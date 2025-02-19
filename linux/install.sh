#!/bin/bash

# All setup assumes a ubuntu based distro
# Note: `apt install` and `apt-get install` are both the same, but apt install is easier/has less options

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. $SCRIPT_DIR/utils.sh

install_linux_apps() {
    # Switch caps and esc, I could do this in another area but fuck it, adding it here
    dconf write /org/gnome/desktop/input-sources/xkb-options "['caps:escape']"

    # Get sudo permissions from the start
    sudo apt update

    info "Installing Wezterm"
    curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /etc/apt/keyrings/wezterm-fury.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
    sudo apt update
    sudo apt install wezterm

    info "Installing docker"
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    # Add the repository to Apt sources:
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
        sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    sudo apt-get update
    # Post install steps
    sudo groupadd docker
    sudo usermod -aG docker $USER
    newgrp docker
    # Start docker on boot
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service

    info "Installing neovim"
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    sudo rm -rf /opt/nvim
    sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz

    info "Installing OpenSSH"
    sudo apt install openssh-server -y

    info "Install ZSH"
    sudo apt install zsh -y

    info "Setting zsh as default"
    chsh -s $(which zsh)

    info "Install zoxide"
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

    info "Install fzf"
    sudo apt install fzf

    info "Install the fuck"
    sudo apt update
    sudo apt install python3-dev python3-pip python3-setuptools
    pip3 install --user git+https://github.com/nvbn/thefuck --break-system-packages

    info "Install starship"
    curl -sS https://starship.rs/install.sh | sh

    info "Install eza (ls replacement)"
    sudo apt install -y gpg
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt update
    sudo apt install -y eza

    info "Installing bat"
    sudo apt install bat
    mkdir -p ~/.local/bin
    ln -s /usr/bin/batcat ~/.local/bin/bat

    info "Installing speedtest"
    sudo apt-get install curl
    curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
    sudo apt-get install speedtest

    info "Installing Lazygit"
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit -D -t /usr/local/bin/

    info "Installing ripgrep"
    sudo apt-get install ripgrep

    info "Installing luarocks"
    curl -L -R -O https://www.lua.org/ftp/lua-5.4.7.tar.gz
    tar zxf lua-5.4.7.tar.gz
    cd lua-5.4.7
    make all test
    cd ..
    rm -rf lua-5.4.5
    rm -rf lua-5.4.5.tar.gz

    sudo apt install luarocks

    info "Installing AppImage installer"
    sudo apt install libfuse2

    info "Install nerd fonts"
    wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip &&
        cd ~/.local/share/fonts &&
        unzip JetBrainsMono.zip &&
        rm JetBrainsMono.zip &&
        fc-cache -fv
}
