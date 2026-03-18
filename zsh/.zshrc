# zsh Options
setopt HIST_IGNORE_ALL_DUPS

# > Start of code to profile
# zmodload zsh/zprof


# Custom functions 
[ -f "$HOME/.config/zsh/functions.zsh" ] && source "$HOME/.config/zsh/functions.zsh"

# Custom zsh (.zshrc equivalent)
[ -f "$HOME/.config/zsh/custom.zsh" ] && source "$HOME/.config/zsh/custom.zsh"

# Zsh Plugin Settings
[ -f "$HOME/.config/zsh/plugin_settings.zsh" ] && source "$HOME/.config/zsh/plugin_settings.zsh"

# Aliases
[ -f "$HOME/.config/zsh/aliases.zsh" ] && source "$HOME/.config/zsh/aliases.zsh"

# Work
[ -f "$HOME/.config/zsh/work.zsh" ] && source "$HOME/.config/zsh/work.zsh"

# Linux
[[ "$(uname)" == "Linux" ]] && [ -f "$HOME/.config/zsh/linux.zsh" ] && source "$HOME/.config/zsh/linux.zsh"

# > End of code to profile
# zprof
