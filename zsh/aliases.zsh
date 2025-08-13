#!/bin/zsh
#
# .aliases - Set whatever shell aliases you want.
#

# -------------------------------------------------------------------
# System commands 
# -------------------------------------------------------------------
alias shutdown='sudo shutdown now'
alias restart='sudo reboot'
alias suspend='sudo pm-suspend'
alias c='clear'
alias e='exit'
alias vi='vim' # Mask builtin with better default

# -------------------------------------------------------------------
# Git
# -------------------------------------------------------------------
# List all git aliases for easy discovery
# Git helper function - shows aliases on --help
g() {
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "🔧 Git Aliases:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Read this file and extract git aliases with their comments
    awk '
    /^# [^-]/ { comment = substr($0, 3) }
    /^alias g.*=.*git/ { 
      split($0, parts, "=")
      alias_name = substr(parts[1], 7)  # Remove "alias "
      alias_command = parts[2]
      gsub(/^'\''|'\''$/, "", alias_command)  # Remove quotes
      if (comment != "") {
        printf "\033[90m%s\033[0m\n", comment
        comment = ""
      }
      printf "\033[1;36m%s\033[0m %s\n", alias_name, alias_command
    }
    ' "${(%):-%x}"  # Current file path in zsh
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💡 Usage: g <git_command> or use any alias above"
  else
    git "$@"
  fi
}
# List all git aliases
alias galiases='g --help'
# Git add with fzf
alias gafzf='git ls-files -m -o --exclude-standard | grep -v "__pycache__" | fzf -m --print0 | xargs -0 -o -t git add' 
# Git rm with fzf, removes file from git index (not from disk)
alias grmfzf='git ls-files -m -o --exclude-standard | fzf -m --print0 | xargs -0 -o -t git rm' 
# Git restore with fzf, will revert file to last commit state
alias grfzf='git diff --name-only | fzf -m --print0 | xargs -0 -o -t git restore' 
# Git restore --staged with fzf, opposite of git add where changes remain, but no longer staged for commit 
alias grsfzf='git diff --name-only | fzf -m --print0 | xargs -0 -o -t git restore --staged' 
# Git diff with fzf, shows changes in file
alias gdfzf='git diff --name-only | fzf -m --print0 | xargs -0 -o -t git diff' 
# Git checkout a branch with fzf (10 most recent branches)
alias gcofzf='git reflog | grep checkout | cut -d '\'' '\'' -f 8 | awk '\''NF && !seen[$0]++'\'' | fzf | xargs -r git checkout'

alias ga='git add'
alias gp='git pull'		
alias gpo='git pull origin'
alias gpu='git push'
alias gl='git log --all --decorate --oneline --graph'
# Pretty log graph
alias glog='git log --graph --oneline --all'
alias gs='git status'
# Git status short format
alias gss="git status -s"
alias gd='git diff'
alias gc="echo 'Use gcm for commit, gco for checkout --- '"
alias gcm='git commit -m'
# Add all and commit with message
alias gcma='git commit -am'
alias gb='git branch'
alias gco='git checkout'
alias gcob='git checkout -b'
alias gra='git remote add'
alias grr='git remote rm'
alias gcl='git clone'
alias gf='git fetch'
# Show recent branch history
alias gbranches='git reflog | grep checkout | cut -d '\'' '\'' -f 8 | awk '\''NF && !seen[$0]++'\'' | head ${1} | cat -n'

# -------------------------------------------------------------------
# Updating built-ins
# -------------------------------------------------------------------
eval $(thefuck --alias)
# Use zoxide instead of cd
if command -v z &> /dev/null; then
    alias cd=z
fi

alias del='echo Moving to ~/.Trash/ ...; mv -i $* ~/.Trash/'

# Safe options, this could be dangerous for other apps that aren't expecting these
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

alias python='python3'
alias pip='pip3'

# -------------------------------------------------------------------
# Misc 
# -------------------------------------------------------------------
# Ranger
alias r=". ranger"

# Better ls
alias ls="eza --all --icons=always"

# Misc 
alias please='sudo'
alias zshrc='code "${ZDOTDIR:-$HOME}"/.zshrc'
alias zdot='cd ${ZDOTDIR:-~}'

# fix common typos
alias quit='exit'
alias cd..='cd ..'

# -------------------------------------------------------------------
# Neovim
# -------------------------------------------------------------------
# If poetry is installed and an environment exists, run "poetry run nvim"
 poetry_run_nvim() {
   if command -v poetry >/dev/null 2>&1 && [ -f "poetry.lock" ]; then
     poetry run nvim "$@"
   else
     nvim "$@"
   fi
 }
 alias nvim='poetry_run_nvim'
 alias v='poetry_run_nvim'
