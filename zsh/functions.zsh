# fh (Find in history) - search in your command history and execute selected command
# This has been deprecated by ctrl+r using fzf
fh() {
  eval $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed 's/ *[0-9]* *//')
}
