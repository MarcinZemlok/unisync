#!/usr/bin/env bash
set -e

CONFIG_FILE="$HOME/.config/unisync"
PASSPHRASE_ENV="STASH_PASSPHRASE"

get_password() {
    if [ -z "${!PASSPHRASE_ENV}" ]; then
        read -s -p "Enter asset decryption password: " PASSWORD
        echo ""
    else
        PASSWORD="${!PASSPHRASE_ENV}"
    fi
}

# --- Core Archive + Crypto Commands ---

cmd_sync() {
    get_password
    echo "Pulling, decrypting, and unpacking archives..."
    # git pull
    
    # Loop placeholder over config items:
    # For each asset, create destination path if it doesn't exist: mkdir -p "$dest"
    
    # Streaming Decryption & Extraction:
    # openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -in "$source" -k "$PASSWORD" | tar -xzvf - -C "$dest"
}

cmd_push() {
    get_password
    echo "Packing, encrypting, and pushing updates..."
    
    # Loop placeholder over config items:
    # Streaming Compression & Encryption:
    # tar -czvf - -C "$(dirname "$dest")" "$(basename "$dest")" | openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -out "$source" -k "$PASSWORD"
    
    # git add, git commit -m "Update encrypted archives", git push
}

# --- Subcommand Router ---
case "$1" in
    edit)   ${EDITOR:-nano} "$CONFIG_FILE" ;;
    list)   echo "... list config blocks ..." ;;
    status) echo "... check if dest paths exist ..." ;;
    sync)   cmd_sync ;;
    push)   cmd_push ;;
    "")     cmd_status && echo "---" && cmd_sync ;;
    *)      echo "Usage: uni [edit|list|status|sync|push]"; exit 1 ;;
esac