# Shared environment configuration.

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
