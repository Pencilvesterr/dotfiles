#!/bin/bash
set -e

# Get the absolute path of the directory where the script is located
# Get the git root dir
GIT_ROOT_DIR="$(git rev-parse --show-toplevel)"
SCRIPT_DIR="$GIT_ROOT_DIR/scripts"
. $SCRIPT_DIR/utils.sh




install_nvidia_gpu_docker() {
    # https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html
    info "Installing nvidia gpu docker"
    info "Adding nvidia container toolkit gpg key"
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list


    sudo apt-get update
    info "Installing nvidia container toolkit"
    sudo apt-get install -y nvidia-container-toolkit
    info "Configuring nvidia container runtime"
    sudo nvidia-ctk runtime configure --runtime=docker
    info "Restarting docker"
    sudo systemctl restart docker
}
