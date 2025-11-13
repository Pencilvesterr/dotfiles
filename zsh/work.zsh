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

# Lazy-load jenv export hook only when a Java tool is needed
function _lazy_init_jenv() {
  unset -f java javac mvn gradle jenv _lazy_init_jenv
  eval "$(jenv init - --no-rehash)"
  (jenv rehash &) 2>/dev/null
}

function java()   { _lazy_init_jenv; command java   "$@" }
function javac()  { _lazy_init_jenv; command javac  "$@" }
function mvn()    { _lazy_init_jenv; command mvn    "$@" }
function gradle() { _lazy_init_jenv; command gradle "$@" }
function jenv()   { _lazy_init_jenv; command jenv   "$@" }

# Added by work automatically?
export PATH="/Users/mcrouch/.orbit/bin:$PATH"

# Setting up atlas
export PATH="/opt/atlassian/bin:$PATH"
