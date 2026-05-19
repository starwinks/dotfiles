#!/bin/bash

# Dotfiles deployment script
# Creates symbolic links from dotfiles repo to home directory
# Supports both bash and zsh configurations

# files to link: "source_path_in_dotfiles" -> "destination_path_in_home"
declare -A FILES=(
    ["bash/bashrc"]="$HOME/.bashrc"
    ["zsh/zshrc"]="$HOME/.zshrc"
    ["git/gitconfig"]="$HOME/.gitconfig"
    ["ssh/config"]="$HOME/.ssh/config"
    ["conda/condarc"]="$HOME/.condarc"
    ["vim/vimrc"]="$HOME/.vimrc"
    ["profile"]="$HOME/.profile"
)

# colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Get the directory of this script
DOTFILE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Helper: check if file should be skipped (e.g. secrets files)
is_secret_file() {
    [[ "$1" == */secrets.zsh ]] || [[ "$1" == */secrets.bash ]]
}

for src in "${!FILES[@]}"; do
    dest="${FILES[$src]}"
    src_file="$DOTFILE_DIR/$src"

    # Skip if source doesn't exist
    if [ ! -e "$src_file" ]; then
        echo -e "${YELLOW}WARNING: Source file $src_file does not exist!${NC}"
        continue
    fi

    # Skip secret files (they're gitignored, user should create them manually)
    if is_secret_file "$src"; then
        echo -e "${YELLOW}SKIP: $src is a secrets file (create manually)${NC}"
        continue
    fi

    # Create parent directory if needed
    dest_parent=$(dirname "$dest")
    if [ ! -d "$dest_parent" ]; then
        echo -e "${YELLOW}Creating directory $dest_parent${NC}"
        mkdir -p "$dest_parent"
    fi

    # Set permissions for SSH config
    if [[ "$dest" == "$HOME/.ssh/config" ]]; then
        chmod 700 "$dest_parent"
        chmod 600 "$src_file"
    fi

    # Backup or remove existing file/link
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        if [ -L "$dest" ]; then
            echo -e "${YELLOW}Removing existing symbolic link $dest${NC}"
            rm "$dest"
        else
            echo -e "${YELLOW}Backing up existing file $dest to $dest.bak${NC}"
            mv -f "$dest" "$dest.bak"
        fi
    fi

    # Create symbolic link
    ln -snf "$src_file" "$dest"
    echo -e "${GREEN}Linked $src_file -> $dest${NC}"
done

echo ""
echo -e "${GREEN}Deployment complete!${NC}"
echo "Note: secrets files were skipped. Create them manually if needed:"
echo "  - zsh/modules/secrets.zsh (copy from secrets.example.zsh)"
echo "  - bash/modules/secrets.bash (copy from secrets.example.bash)"
echo ""
echo "Restart your shell or run:"
echo "  source ~/.zshrc  # for zsh"
echo "  source ~/.bashrc # for bash"