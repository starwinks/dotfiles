# Machine-specific environment configuration.

# Proxy configuration
# Windows host IP for proxy forwarding

WIN_IP="127.0.0.1"
PROXY_PORT="7890"
export http_proxy="http://${WIN_IP}:${PROXY_PORT}"
export https_proxy="http://${WIN_IP}:${PROXY_PORT}"
export all_proxy="http://${WIN_IP}:${PROXY_PORT}"

# Local loopback, campus network traffic direct connection
export no_proxy="localhost,127.0.0.1,::1,172.17.0.0/16,${WIN_IP},.edu.cn,114.212.0.0/16"


# =============================================================================
# Package Managers & Tool Environments
# =============================================================================

# Homebrew (Linuxbrew) environment
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"

# Homebrew mirrors (NJU)
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
export HF_ENDPOINT="https://hf-mirror.com"

# Conda (lazy loaded)
if [ -f "/home/starwink/miniconda3/bin/conda" ]; then
  conda() {
    unset -f conda
    __conda_setup="$('/home/starwink/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
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
    conda "$@"
  }
fi

# nvidia toolkit
export PATH=/usr/local/cuda-12.8/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64:$LD_LIBRARY_PATH
