# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login exists.

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

# Helper function to prepend to PATH without duplication
pathadd() {
    case ":$PATH:" in
        *":$1:"*) ;;
        *) [ -d "$1" ] && PATH="$1:$PATH" ;;
    esac
}

# set PATH so it includes user's private bin if it exists
pathadd "$HOME/bin"
pathadd "$HOME/.local/bin"

# include cargo environment if it exists
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

export PATH