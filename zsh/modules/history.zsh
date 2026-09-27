# =============================================================================
# modules/history.zsh - History configuration
# =============================================================================

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

# Options
setopt EXTENDED_HISTORY          # Write the history file in the ':start:elapsed;command' format
setopt SHARE_HISTORY             # Share history between all active sessions
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate event first when trimming history
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when shell exits
