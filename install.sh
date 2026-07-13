#!/usr/bin/env bash

UNISYNC_DIR="$HOME/.unisync"
BIN_DIR="$HOME/.local/bin"

check_prerequisites() {
    # Check for required commands
    echo -n "Checking prerequisites..."
    for cmd in git openssl tar; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: $cmd is not installed. Please install it and try again."
            exit 1
        fi
    done
    echo " [OK]"
}

prepare_environment() {
    # Check if the unisync directory exists, if not create it
    echo -n "Preparing environment..."
    if [[ ! -d "$UNISYNC_DIR" ]]; then
        mkdir -p "$UNISYNC_DIR"
        mkdir -p "$UNISYNC_DIR/repo"
        touch "$UNISYNC_DIR/config"
    fi

    # Check if the bin directory exists, if not create it
    if [[ ! -d "$BIN_DIR" ]]; then
        mkdir -p "$BIN_DIR"
    fi
    echo " [OK]"
}

populate_config() {
    cat << 'EOF' > "$UNISYNC_DIR/config"
# Example configuration for unisync

[global]
repo = "git@github.com:username/my-assets.git"
cipher = "aes-256-cbc"

[dotfiles]
source = "assets/dotfiles.tar.enc"
dest = "~/.bashrc"

[dev-certs]
# This entry targets an entire directory tree
source = "assets/certs.tar.enc"
dest = "~/development/certs/"

EOF
}

clone_repo() {
    echo "Cloning the Git repository for your assets..."
    _success=false
    local repo_url
    while [ "$_success" = false ]; do
        read -p "  Enter the Git repository URL for your assets: " repo_url
        if git ls-remote "$repo_url" &> /dev/null; then
            _success=true
        else
            echo "  Error: Unable to access the repository. Please check the URL and try again."
        fi
    done
    git clone "$repo_url" "$UNISYNC_DIR/repo"
    echo " [OK]"
}

get_unisync() {
    echo -n "Downloading unisync script..."
    wget -qO "$BIN_DIR/uni" "https://raw.githubusercontent.com/MarcinZemlok/unisync/refs/heads/master/uni.sh"
    chmod +x "$BIN_DIR/uni"
    echo " [OK]"
}

populate_environment() {
    # Check if config file exists, if not create it
    if [[ ! -f "$UNISYNC_DIR/config" ]]; then
        populate_config
    fi

    # Check if repository is cloned, if not clone it
    if [[ ! -d "$UNISYNC_DIR/repo/.git" ]]; then
        clone_repo
    fi

    # Check if uni script exists, if not download it
    if [[ ! -f "$BIN_DIR/uni" ]]; then
        get_unisync
    fi
}

check_prerequisites
prepare_environment
populate_environment

