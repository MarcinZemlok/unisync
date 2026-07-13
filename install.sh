#!/usr/bin/env bash

wget https://raw.githubusercontent.com/MarcinZemlok/unisync/refs/heads/master/uni.sh -O $HOME/.local/bin/uni

if [[ ! -d "$HOME/.config" ]]; then
    mkdir -p "$HOME/.config"
fi

if [[ ! -d "$HOME/.config/unisync" ]]; then
    touch "$HOME/.config/unisync"
fi

cat << 'EOF' > "$HOME/.config/unisync"
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
