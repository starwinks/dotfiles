# !/bin/bash

# files to link
declare -A FILES=(
    ["bash/bashrc"]="$HOME/.bashrc"
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

# 1. get the directory of this script
DOTFILE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)


for src in "${!FILES[@]}"; do
    dest="${FILES[$src]}"
    src_file="$DOTFILE_DIR/$src"

    # 2. check if source file exists
    if [ ! -e "$src_file" ]; then
        echo -e "${YELLOW}WARNING: Source file $src_file does not exist!${NC}"
        continue
    fi

    # 3. create parent directory if it doesn't exist
    dest_parent=$(dirname "$dest")
    if [ ! -d "$dest_parent" ]; then
        echo -e "${YELLOW}Creating directory $dest_parent${NC}"
        mkdir -p "$dest_parent"

        
    fi

    # 4. some files like .ssh/config need to have specific permissions
    if [[ "$dest" == "$HOME/.ssh/config" ]]; then
        chmod 700 "$dest_parent"
        chmod 600 "$src_file"
    fi

    # 5. backup existing file if it exists 
    # note: a died symbolic link will be treated as a regular file and backed up)
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        # if it's a symbolic link, remove it
        if [ -L "$dest" ]; then
            echo -e "${YELLOW}Removing existing symbolic link $dest${NC}"
            rm "$dest"
        # if it's a regular file or directory, back it up
        else
            echo -e "${YELLOW}Backing up existing file $dest to $dest.bak${NC}"
            mv -f "$dest" "$dest.bak"
        fi
    fi

    # 6. create symbolic link
    ln -snf "$src_file" "$dest"
    echo -e "${GREEN}Linked $src_file -> $dest${NC}"
done