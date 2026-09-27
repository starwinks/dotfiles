# =============================================================================
# modules/keybindings.zsh - Keybindings configuration
# =============================================================================

# Standard Emacs keybindings
bindkey -e

# Home & End
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[[1~" beginning-of-line
bindkey "^[[4~" end-of-line
bindkey "^[OH" beginning-of-line
bindkey "^[OF" end-of-line

# Delete & Insert
bindkey "^[[3~" delete-char
bindkey "^[[2~" overwrite-mode

# Word navigation (Ctrl+Left / Ctrl+Right)
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word
bindkey "^[Oc" forward-word
bindkey "^[Od" backward-word

# History search (Ctrl+R)
bindkey '^r' history-incremental-search-backward

# Up / Down arrow prefix search (type prefix, then press Up to search history)
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search
bindkey "^[OA" up-line-or-beginning-search
bindkey "^[OB" down-line-or-beginning-search
