# =============================================================================
# modules/completion.zsh - Fast, cached Tab completion with interactive menu
# =============================================================================

# Fast compinit with cache check (only re-dumps once every 24 hours)
autoload -Uz compinit
_zcompdump="${ZDOTDIR:-$HOME}/.zcompdump-${(%):-%m}-$ZSH_VERSION"
if [[ -s "$_zcompdump" && (! -n "${_zcompdump}(#qN.md-1)") ]]; then
  compinit -C -d "$_zcompdump"
else
  compinit -d "$_zcompdump"
fi
unset _zcompdump

# Menu selection with arrow keys
zstyle ':completion:*' menu select

# Case-insensitive matching, and treat '-' and '_' identically
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Colored completion list matching system LS_COLORS
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Nicely formatted group descriptions
zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'
zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
