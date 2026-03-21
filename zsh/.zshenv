#
# .zshenv - Zsh environment file, loaded always.
#

# NOTE: .zshenv needs to live at ~/.zshenv, not in $ZDOTDIR!
# This should be done with the setup script in the READM
# And this file should only ever set environment variables

# Themes (onedark or nord)
export NVIM_THEME="nord"
export STARSHIP_THEME="nord"
export WEZTERM_THEME="nord"

# Locale settings
export LANG="en_AU.UTF-8" # Sets default locale for all categories
export LC_ALL="en_AU.UTF-8" # Overrides all other locale settings
export LC_CTYPE="en_AU.UTF-8" # Controls character classification and case conversion

# Use nvim as default editor, falling back to vim if not available
if command -v nvim >/dev/null 2>&1; then
  export EDITOR="nvim"
  export VISUAL="nvim"
else
  export EDITOR="vim"
  export VISUAL="vim"
fi

# Add /usr/local/bin to the beginning of the PATH environment variable.
# This ensures that executables in /usr/local/bin are found before other directories in the PATH.
export PATH="/usr/local/bin:$PATH"

# Hide computer name in terminal
export DEFAULT_USER="$(whoami)"

# Set software config files to be in ~/.config
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
# Set ZDOTDIR if you want to re-home Zsh.
export ZDOTDIR=${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}
