#!/bin/zsh
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
# Strategy: Set JAVA_HOME immediately, then full init in background
# This ensures scripts like ./jmake work immediately while keeping startup fast

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

# Wrapper functions for immediate use (if Java commands called before background init)
java()   { _jenv_do_init; command java   "$@" }
javac()  { _jenv_do_init; command javac  "$@" }
mvn()    { _jenv_do_init; command mvn    "$@" }
gradle() { _jenv_do_init; command gradle "$@" }
jenv()   { _jenv_do_init; command jenv   "$@" }
jinit()  { _jenv_do_init; echo "✓ jenv initialized" }

# Set JAVA_HOME immediately for scripts (like ./jmake) that need it
# This is fast and doesn't block shell startup
if [[ -s "$HOME/.jenv/version" ]]; then
  export PATH="$HOME/.jenv/bin:$PATH"
  JENV_VERSION=$(cat "$HOME/.jenv/version")
  if [[ -d "$HOME/.jenv/versions/$JENV_VERSION" ]]; then
    export JAVA_HOME="$HOME/.jenv/versions/$JENV_VERSION"
  fi
fi

# Start full jenv initialization in background immediately (non-blocking)
{ _jenv_do_init } &!

# Added by work automatically?
export PATH="/Users/mcrouch/.orbit/bin:$PATH"

# Setting up atlas
export PATH="/opt/atlassian/bin:$PATH"
