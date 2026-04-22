# History
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
setopt APPEND_HISTORY
setopt SHARE_HISTORY

# OS Specific config
if [[ "$OSTYPE" == "darwin"* ]]; then
  # Homebrew
  eval "$(/opt/homebrew/bin/brew shellenv)"
  export HOMEBREW_NO_AUTO_UPDATE=1
else
  # Homebrew on Linux
  if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
    eval "$($HOME/.linuxbrew/bin/brew shellenv)"
  fi
fi

# Setup direnv
eval "$(direnv hook zsh)"


# Poetry
export PATH="$HOME/.local/bin:$PATH"

# Starship - defer init for faster startup
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
  # Set palette only once, not on every shell startup
  if [[ ! -f "${ZDOTDIR:-$HOME}/.starship_palette_set" ]]; then
    starship config palette $STARSHIP_THEME &>/dev/null && touch "${ZDOTDIR:-$HOME}/.starship_palette_set" &
  fi
fi

# Optimize compinit for faster startup - cache completions
autoload -Uz compinit

# Set the completion dump file location
ZSH_COMPDUMP="${ZDOTDIR:-$HOME}/.zcompdump"

# Only rebuild completions cache if it doesn't exist or is old
if [[ ! -f "$ZSH_COMPDUMP" ]] || [[ $(find "$ZSH_COMPDUMP" -mtime +1 2>/dev/null) ]]; then
  # Cache doesn't exist or is older than 1 day, rebuild it
  compinit -d "$ZSH_COMPDUMP"
  # Make sure it has correct permissions
  [[ -f "$ZSH_COMPDUMP" ]] && chmod go-w "$ZSH_COMPDUMP"
else
  # Use cached version without security check for speed (much faster)
  compinit -C -d "$ZSH_COMPDUMP"
fi

# Start zoxide, needs to come after compinit for completion to work
eval "$(zoxide init zsh)"


# If using git-auto-fetch plugin, sets interval to fetch changes
export GIT_AUTO_FETCH_INTERVAL=1200 # in seconds
# Don't prompt to import .env files in terminal for dotenv plugin
export ZSH_DOTENV_PROMPT=false

# Source zstyles you might use with antidote.
[[ -e ${ZDOTDIR:-~}/.zstyles ]] && source ${ZDOTDIR:-~}/.zstyles

# Load antidote binary
source $(brew --prefix)/opt/antidote/share/antidote/antidote.zsh

# Cache antidote plugins for faster startup
zsh_plugins=${ZDOTDIR:-~}/.zsh_plugins.zsh
if [[ ! $zsh_plugins -nt ${ZDOTDIR:-~}/.zsh_plugins.txt ]]; then
  echo "Caching antidote plugins for faster startup..."
  antidote bundle <${ZDOTDIR:-~}/.zsh_plugins.txt >|$zsh_plugins
fi
source $zsh_plugins

# Fix history search key bindings for partial search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1


# Disable highlight on paste
zle_highlight=('paste:none')

# -- Vi mode
# ANSI cursor escape codes:
# \e[0 q: Reset to the default cursor style.
# \e[1 q: Blinking block cursor.
# \e[2 q: Steady block cursor (non-blinking).
# \e[3 q: Blinking underline cursor.
# \e[4 q: Steady underline cursor (non-blinking).
# \e[5 q: Blinking bar cursor.
# \e[6 q: Steady bar cursor (non-blinking).
# TODO: Look into adding https://github.com/softmoth/zsh-vim-mode
bindkey -v
export KEYTIMEOUT=1 # Makes switching modes quicker
export VI_MODE_SET_CURSOR=true

# Change the cursor to block or beam depending on insert mode
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]]; then
    echo -ne '\e[2 q' # block
  else
    echo -ne '\e[6 q' # beam
  fi
}
zle -N zle-keymap-select
zle-line-init() {
  zle -K viins # initiate 'vi insert' as keymap (can be removed if 'binkey -V has been set elsewhere')
  echo -ne '\e[6 q'
}
zle -N zle-line-init
echo -ne '\e[6 q' # Use beam shape cursor on startup

# Yank to the system clipboard
function vi-yank-xclip {
  zle vi-yank
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "$CUTBUFFER" | pbcopy
  elif command -v xclip >/dev/null 2>&1; then
    echo "$CUTBUFFER" | xclip -selection clipboard
  elif command -v xsel >/dev/null 2>&1; then
    echo "$CUTBUFFER" | xsel --clipboard --input
  fi
}

zle -N vi-yank-xclip
bindkey -M vicmd 'y' vi-yank-xclip

# Add word movement bindings so that opt + left/right work in wezterm
bindkey "^[f" forward-word
bindkey "^[b" backward-word

# Make word-based operations stop at most punctuation (macOS-like behavior)
# Default WORDCHARS is: *?_-.[]~=/&;!#$%^(){}<>
WORDCHARS=''

