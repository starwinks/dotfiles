# =============================================================================
# modules/plugins.zsh - Standalone plugin loader (independent from OMZ framework)
# =============================================================================

# 1. Directory jumping (z)
if [[ -r "$HOME/.oh-my-zsh/plugins/z/z.plugin.zsh" ]]; then
  source "$HOME/.oh-my-zsh/plugins/z/z.plugin.zsh"
elif (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
fi

# 2. Git shortcuts and helper functions
if [[ -r "$HOME/.oh-my-zsh/plugins/git/git.plugin.zsh" ]]; then
  source "$HOME/.oh-my-zsh/plugins/git/git.plugin.zsh"
fi

# 3. zsh-autosuggestions
if [[ -r "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
elif [[ -r "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# 4. zsh-syntax-highlighting (MUST be loaded last)
if [[ -r "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
elif [[ -r "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
