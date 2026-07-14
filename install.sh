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

### General Settings ###

cipher = "aes-256-cbc"

### Asset Mappings ###

dotfiles = assets/dotfiles.tar.enc | ~/.bashrc
dev-certs = assets/certs.tar.enc | ~/development/certs/

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

update_repo() {
    echo "Updating the Git repository..."
    git -C "$UNISYNC_DIR/repo" pull
    echo " [OK]"
}

validate_repo() {
    echo -n "Validating the structure of the cloned repository..."
    if [[ ! -d "$UNISYNC_DIR/repo/assets" ]]; then
        echo "Error: The repository does not contain an 'assets' directory. Please ensure the repository is structured correctly."
        exit 1
    fi

    if [[ ! -f "$UNISYNC_DIR/repo/assets_list.txt" ]]; then
        echo "Error: The repository does not contain an 'assets_list.txt' file. Please ensure the repository is structured correctly."
        exit 1
    fi
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
    update_repo
    validate_repo

    # Check if uni script exists, if not download it
    if [[ ! -f "$BIN_DIR/uni" ]]; then
        get_unisync
    fi
}

check_prerequisites
prepare_environment
populate_environment

