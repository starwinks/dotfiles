# Shared environment configuration.

# Package manager and model download mirrors.
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
export HF_ENDPOINT="https://hf-mirror.com"

# PATH setup with deduplication.
typeset -U path PATH
path=(
    "$HOME/bin"
    "$HOME/.local/bin"
    $path
)

# Cargo environment
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Fast Node Manager (fnm)
if (( $+commands[fnm] )); then
  eval "$(fnm env --use-on-cd)"
fi
