# Shared environment configuration.

# >>> mirrors >>>
# Mirrors for Homebrew, uv, fnm, corepack and Hugging Face. Managed by
# mirrors.sh: `bash mirrors.sh apply` rewrites this block, `bash mirrors.sh
# probe` verifies the sources.
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
export HOMEBREW_CASK_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-cask.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
export UV_PYTHON_INSTALL_MIRROR="https://mirror.nju.edu.cn/github-release/astral-sh/python-build-standalone"
export COREPACK_NPM_REGISTRY="https://registry.npmmirror.com"
export FNM_NODE_DIST_MIRROR="https://npmmirror.com/mirrors/node"
export HF_ENDPOINT="https://hf-mirror.com"
# <<< mirrors <<<

# PATH setup with deduplication.
typeset -U path PATH
path=(
    "$HOME/bin"
    "$HOME/.local/bin"
    $path
)

# Cargo environment
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Conda lazy loading. deploy.sh provides DOTFILES_CONDA_DIR for portable
# installations; the home miniconda3 fallback keeps the existing local setup
# working even before deploy.sh has generated paths.env.
if (( $+functions[conda] == 0 )); then
  typeset -g _DOTFILES_CONDA_DIR="${DOTFILES_CONDA_DIR:-}"
  if [[ -z "$_DOTFILES_CONDA_DIR" && -x "$HOME/miniconda3/bin/conda" ]]; then
    _DOTFILES_CONDA_DIR="$HOME/miniconda3"
  elif [[ -z "$_DOTFILES_CONDA_DIR" && $+commands[conda] -eq 1 ]]; then
    _DOTFILES_CONDA_DIR="${commands[conda]%/bin/conda}"
  fi

  if [[ -x "$_DOTFILES_CONDA_DIR/bin/conda" ]]; then
    conda() {
      unfunction conda
      local conda_exe="${_DOTFILES_CONDA_DIR}/bin/conda"
      local conda_setup
      if conda_setup="$($conda_exe shell.zsh hook 2>/dev/null)"; then
        eval "$conda_setup"
      elif [[ -r "$_DOTFILES_CONDA_DIR/etc/profile.d/conda.sh" ]]; then
        source "$_DOTFILES_CONDA_DIR/etc/profile.d/conda.sh"
      else
        export PATH="${_DOTFILES_CONDA_DIR}/bin:$PATH"
      fi
      unset conda_setup
      conda "$@"
    }
  fi
fi

# Fast Node Manager (fnm)
if (( $+commands[fnm] )); then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi
