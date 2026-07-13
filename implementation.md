Here is the updated architectural and implementation plan, adjusted to handle assets as **encrypted archives** (tarballs). This allows any asset entry to seamlessly represent either a single file or a deeply nested directory tree while maintaining a zero-dependency Bash footprint.

---

## 🛠️ Updated Architecture & Security Model

To handle entire directory structures, the tool will first compress the target local file or folder into an unencrypted `tar` archive in memory/temp storage, and then pipe that stream directly into `openssl` for encryption.

* **The Repository Layout:**
```text
your-asset-repo/
├── install.sh       # The public bootstrap script
├── stash.sh         # The main CLI tool
└── assets/          # Encrypted tar archives (.tar.enc)
    ├── dotfiles.tar.enc
    └── project_keys.tar.enc

```


* **Security & Archival Flow:**
* **Push:** `Local Path` $\rightarrow$ `tar` (archive) $\rightarrow$ `openssl` (encrypt) $\rightarrow$ `GitHub`
* **Pull/Sync:** `GitHub` $\rightarrow$ `openssl` (decrypt) $\rightarrow$ `tar` (extract) $\rightarrow$ `Local Path`



---

## 📝 Updated Configuration File (`~/.stashrc`)

Because an archive natively preserves directory structures, the configuration remains just as simple. The local destination will point to the *parent directory* or the exact target path depending on extraction.

```ini
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

```

---

## 💻 Updated Implementation Plan (Core Snippets)

The core shift happens within the `sync` and `push` functions, using standard Unix piping (`|`) to avoid writing unencrypted intermediary files to the disk.

### 1. The Core Script (`stash`)

```bash
#!/usr/bin/env bash
set -e

CONFIG_FILE="$HOME/.stashrc"
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
    list)   # ... list config blocks ... ;;
    status) # ... check if dest paths exist ... ;;
    sync)   cmd_sync ;;
    push)   cmd_push ;;
    "")     cmd_status && echo "---" && cmd_sync ;;
    *)      echo "Usage: stash [edit|list|status|sync|push]"; exit 1 ;;
esac

```

---

## 🚀 Updated Step-by-Step Execution Strategy

1. **Phase 1: Streaming Tar & OpenSSL Pipeline Proof of Concept**
* Lock down the exact `tar | openssl` pipe logic. Ensure that standardizing paths using `dirname` and `basename` prevents absolute path injection vulnerabilities inside the tarball.


2. **Phase 2: Robust Bash INI Parser**
* Write a clean loop capable of parsing multiline blocks (`source` and `dest`) tied to an asset identifier.


3. **Phase 3: Git & UI Aggregation**
* Implement status tracking (e.g., hash verification or simple presence checks of local destination directories) and build the clean single-command default sequence.


4. **Phase 4: Installer Deployment**
* Draft the `install.sh` bootstrap mechanism.



Would you like to write the robust **streaming push/pull logic** first to ensure directory structures compress and encrypt perfectly, or work on the **INI config parser**?