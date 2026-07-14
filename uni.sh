#!/usr/bin/env bash
set -e

BIN_DIR="$HOME/.local/bin"
UNISYNC_DIR="$HOME/.unisync"
ASSETS_REPO_DIR="$UNISYNC_DIR/repo"
ASSETS_DIR="$ASSETS_REPO_DIR/assets"
CONFIG_FILE_NAME="$UNISYNC_DIR/config"
PASSPHRASE_ENV="UNISYNC_PASSPHRASE"

check_config() {
    if [[ ! -f "$CONFIG_FILE_NAME" ]]; then
        echo "Error: Configuration file not found at $CONFIG_FILE_NAME. Please run the install script first."
        exit 1
    fi
}

get_password() {
    if [ -z "${!PASSPHRASE_ENV}" ]; then
        read -s -p "Enter asset decryption password: " PASSWORD
        echo ""
    else
        PASSWORD="${!PASSPHRASE_ENV}"
    fi
}

check_asset_name() {
    local asset_name="$1"
    if ! grep -q "^\s*${asset_name}\s*=" "$CONFIG_FILE_NAME"; then
        echo "Error: Asset '$asset_name' not found in configuration. Please check your config file."
        exit 1
    fi
}

check_and_update_repo() {
    if [[ ! -d "$ASSETS_REPO_DIR" ]]; then
        echo "Error: Assets repository not found at $ASSETS_REPO_DIR. Please run the install script first."
        exit 1
    fi
    echo "Updating the Git repository..."
    git -C "$ASSETS_REPO_DIR" pull
    echo " [OK]"
}

# --- Core Archive + Crypto Commands ---

cmd_get() {
    name="$1"
    if [[ -z "$name" ]]; then
        echo "Error: No asset name provided for push command."
        exit 1
    fi

    echo "Pulling, decrypting, and unpacking archives..."
    check_and_update_repo
    check_asset_name "$name"

    source=$(grep "^\s*${name}\s*=" "$CONFIG_FILE_NAME" | awk -F '=' '{print $2}' | awk -F '|' '{print $1}' | xargs)
    dest=$(grep "^\s*${name}\s*=" "$CONFIG_FILE_NAME" | awk -F '=' '{print $2}' | awk -F '|' '{print $2}' | xargs)
    full_source="$ASSETS_DIR/$source"
    full_dest=$(eval "realpath $dest")

    # Debugging section
    echo -e "\n***** Debugging Information *****\n"
    echo "Name: $name"
    echo "Source: $source"
    echo "Destination: $dest"
    echo "Full Source Path: $full_source"
    echo "Full Destination Path: $full_dest"
    echo -e "\n*********************************\n"
    ###

    # Copy the source archive to a temporary location
    temp_archive=$(mktemp)
    cp "$full_source" "$temp_archive"

    # Decrypt and extract the archive to the destination
    openssl enc -d -${CIPHER} -pbkdf2 -iter 100000 -in "$temp_archive" | tar -xzvf - -C "$(dirname $full_dest)"
    
    rm "$temp_archive"
    echo " [OK]"
}

cmd_push() {
    name="$1"
    if [[ -z "$name" ]]; then
        echo "Error: No asset name provided for push command."
        exit 1
    fi

    echo "Packing, encrypting, and pushing updates..."
    check_and_update_repo
    check_asset_name "$name"

    source=$(grep "^\s*${name}\s*=" "$CONFIG_FILE_NAME" | awk -F '=' '{print $2}' | awk -F '|' '{print $1}' | xargs)
    dest=$(grep "^\s*${name}\s*=" "$CONFIG_FILE_NAME" | awk -F '=' '{print $2}' | awk -F '|' '{print $2}' | xargs)
    full_source="$ASSETS_DIR/$source"
    full_dest=$(eval "realpath $dest")

    # Debugging section
    echo -e "\n***** Debugging Information *****\n"
    echo "Name: $name"
    echo "Source: $source"
    echo "Destination: $dest"
    echo "Full Source Path: $full_source"
    echo "Full Destination Path: $full_dest"
    echo -e "\n*********************************\n"
    ###

    # Create a temporary archive of the source
    temp_archive=$(mktemp)
    tar -czvf "$temp_archive" -C "$(dirname "$full_dest")" "$(basename "$full_dest")"

    # Encrypt the archive
    # get_password
    openssl enc -e -${CIPHER} -pbkdf2 -iter 100000 -in "$temp_archive" -out "$full_source"

    # Add asset to the assets_list.txt if not already present
    if ! grep -q "^\s*${name}\s*" "$ASSETS_REPO_DIR/assets_list.txt"; then
        echo "$name" >> "$ASSETS_REPO_DIR/assets_list.txt"
    fi

    # Commit and push changes to the repository
    git -C "$ASSETS_REPO_DIR" add "assets/$source"
    git -C "$ASSETS_REPO_DIR" add "assets_list.txt"
    git -C "$ASSETS_REPO_DIR" commit -m "Update asset: ${name}"
    git -C "$ASSETS_REPO_DIR" push

    rm "$temp_archive"
    echo " [OK]"
}

cmd_update() {
    echo -n "Updating unisync script..."
    wget -qO "$BIN_DIR/uni" "https://raw.githubusercontent.com/MarcinZemlok/unisync/refs/heads/master/uni.sh"
    chmod +x "$BIN_DIR/uni"
    echo " [OK]"
}

# Global configuration variables
check_config
CIPHER=$(grep -E '^\s*cipher\s*=' "$CONFIG_FILE_NAME" | awk -F '=' '{print $2}' | xargs)

# --- Subcommand Router ---
case "$1" in
    list)   cat "$ASSETS_REPO_DIR/assets_list.txt" ;;
    get)    cmd_get $2 ;;
    push)   cmd_push $2 ;;
    edit)   ${EDITOR:-nano} "$CONFIG_FILE_NAME" ;;
    update) cmd_update ;;
    *)
        echo -e "\n***** UNISYNC help *****\n"
        echo "Usage: uni [edit|list|status|get|push]"
        echo -e "\nCommands:"
        echo "  edit    - Edit the configuration file"
        echo "  list    - List all available assets"
        echo "  get     - Pull, decrypt, and unpack an asset (usage: uni get <asset_name>)"
        echo "  push    - Pack, encrypt, and push updates to an asset (usage: uni push <asset_name>)"
        echo "  update  - Update uni.sh script"
        echo -e "\n*************************\n"
        exit 1 ;;
esac