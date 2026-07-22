# zsh Options
# > Start of code to profile
# zmodload zsh/zprof

# Zsh Plugin Settings (must precede custom.zsh, which loads the plugins these settings configure)
[ -f "$HOME/.config/zsh/plugin_settings.zsh" ] && source "$HOME/.config/zsh/plugin_settings.zsh"

# Custom zsh (.zshrc equivalent)
[ -f "$HOME/.config/zsh/custom.zsh" ] && source "$HOME/.config/zsh/custom.zsh"

# Aliases
[ -f "$HOME/.config/zsh/aliases.zsh" ] && source "$HOME/.config/zsh/aliases.zsh"

# Work
[ -f "$HOME/.config/zsh/work.zsh" ] && source "$HOME/.config/zsh/work.zsh"

# Linux
[[ "$(uname)" == "Linux" ]] && [ -f "$HOME/.config/zsh/linux.zsh" ] && source "$HOME/.config/zsh/linux.zsh"

# Local machine-specific config (not tracked in git)
[ -f "$HOME/.config/zsh/local.zsh" ] && source "$HOME/.config/zsh/local.zsh"

# > End of code to profile
# zprof
