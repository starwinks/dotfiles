# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# network settings
WIN_IP="127.0.0.1"
PROXY_PORT="7890"
export http_proxy="http://${WIN_IP}:${PROXY_PORT}"
export https_proxy="http://${WIN_IP}:${PROXY_PORT}"
export all_proxy="http://${WIN_IP}:${PROXY_PORT}"
# 本地回环, 校内流量等直连
export no_proxy="localhost,127.0.0.1,::1,172.17.0.0/16,${WIN_IP}, .edu.cn,114.212.0.0/16"

# =============================================================================
# Package Managers & Tool Environments
# =============================================================================

# Homebrew mirrors (Aliyun)
export HOMEBREW_API_DOMAIN="https://mirrors.aliyun.com/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.aliyun.com/homebrew-bottles"
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.aliyun.com/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.aliyun.com/homebrew/homebrew-core.git"
export HOMEBREW_CASK_GIT_REMOTE="https://mirrors.aliyun.com/homebrew/homebrew-cask.git"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/starwink/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/starwink/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/starwink/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/starwink/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Fast Node Manager (fnm)
if command -v fnm &>/dev/null; then
  eval "$(fnm env --use-on-cd)"
fi