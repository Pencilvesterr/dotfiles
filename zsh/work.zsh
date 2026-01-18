# !/bin/zsh
# --- Machine specific, don't add to git

# -------------------------------------------------------------------
# Updating PATH
# -------------------------------------------------------------------
# Created by `pipx` on 2024-02-26 20:44:52
export PATH="$PATH:/Users/mcrouch/.local/bin"
# Required for ./jmake healthcheck
export PATH="/opt/homebrew/opt/util-linux/bin:$PATH"
# Add pyenv to path
export PATH="/Users/mcrouch/.pyenv/shims:${PATH}"

# Lazy-load pyenv to speed up shell startup
function _lazy_init_pyenv() {
  unset -f python python3 pip pip3 _lazy_init_pyenv
  eval "$(pyenv init - --no-rehash)"
  (pyenv rehash &) 2>/dev/null
}
function python()  { _lazy_init_pyenv; command python  "$@" }
function python3() { _lazy_init_pyenv; command python3 "$@" }
function pip()     { _lazy_init_pyenv; command pip     "$@" }
function pip3()    { _lazy_init_pyenv; command pip3    "$@" }
function pyenv()   { _lazy_init_pyenv; command pyenv   "$@" }
export PATH="/Users/mcrouch/.local/bin:$PATH"

# NVM is handdled with undg/zsh-nvm-lazy-load
# is handled with lazy-loading
export NVM_DIR="$HOME/.config/nvm"

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use # This loads nvm, --no-use i think makes lazy?

# Seems to be something to do with Atlassian dev boxes?
export PATH="/Users/mcrouch/.orbit/bin:$PATH"


# jenv - Background lazy loading for fast startup
# Strategy: Zero cost at startup, auto-loads in background after first prompt
# Wrapper functions ensure immediate availability if needed before background init completes

typeset -g _JENV_LOADED=0

# Core initialization function
_jenv_do_init() {
  if (( _JENV_LOADED )); then
    return 0
  fi
  _JENV_LOADED=1
  
  # Remove wrapper functions - no longer needed after init
  unfunction java javac mvn gradle jenv jinit 2>/dev/null
  
  # Initialize jenv
  export PATH="$HOME/.jenv/bin:$PATH"
  eval "$(jenv init - --no-rehash)"
  (jenv rehash &) 2>/dev/null
}

# Background initialization hook (runs after first prompt is displayed)
_jenv_background_init() {
  # Remove this hook to prevent repeated calls
  add-zsh-hook -d precmd _jenv_background_init
  
  # Initialize jenv in background (non-blocking)
  { _jenv_do_init } &!
}

# Wrapper functions for immediate use (if Java commands called before background init)
java()   { _jenv_do_init; command java   "$@" }
javac()  { _jenv_do_init; command javac  "$@" }
mvn()    { _jenv_do_init; command mvn    "$@" }
gradle() { _jenv_do_init; command gradle "$@" }
jenv()   { _jenv_do_init; command jenv   "$@" }
jinit()  { _jenv_do_init; echo "✓ jenv initialized" }

# Schedule background initialization after first prompt
autoload -Uz add-zsh-hook
add-zsh-hook precmd _jenv_background_init

# Added by work automatically?
export PATH="/Users/mcrouch/.orbit/bin:$PATH"

# Setting up atlas
export PATH="/opt/atlassian/bin:$PATH"
