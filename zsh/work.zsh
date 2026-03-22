#!/bin/zsh
# --- Machine specific, don't add to git

# -------------------------------------------------------------------
# Updating PATH
# -------------------------------------------------------------------
export PATH="$PATH:$HOME/.local/bin"
# Required for ./jmake healthcheck
export PATH="/opt/homebrew/opt/util-linux/bin:$PATH"

# Seems to be something to do with Atlassian dev boxes?

# Setting up atlas
export PATH="/opt/atlassian/bin:$PATH"

# -------------------------------------------------------------------
# NVM - installed via homebrew, lazy loaded for fast startup
# -------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"

typeset -g _NVM_LOADED=0

_nvm_do_init() {
  if (( _NVM_LOADED )); then
    return 0
  fi
  _NVM_LOADED=1

  # Remove wrapper functions - no longer needed after init
  unfunction nvm node npm npx yarn pnpm ninit 2>/dev/null

  # Load nvm (must run in current shell, cannot be backgrounded)
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
}

# Wrapper functions for immediate use (trigger init on first call)
nvm()   { _nvm_do_init; nvm   "$@" }
node()  { _nvm_do_init; command node  "$@" }
npm()   { _nvm_do_init; command npm   "$@" }
npx()   { _nvm_do_init; command npx   "$@" }
yarn()  { _nvm_do_init; command yarn  "$@" }
pnpm()  { _nvm_do_init; command pnpm  "$@" }
ninit() { _nvm_do_init; echo "✓ nvm initialized" }

# Set node PATH immediately for scripts that need node without triggering full init
# Only works if default alias points directly to a version (not an lts/* alias)
if [[ -s "$NVM_DIR/alias/default" ]]; then
  _nvm_default=$(< "$NVM_DIR/alias/default")
  if [[ "$_nvm_default" == v* ]] && [[ -d "$NVM_DIR/versions/node/$_nvm_default" ]]; then
    export PATH="$NVM_DIR/versions/node/$_nvm_default/bin:$PATH"
  fi
  unset _nvm_default
fi

# -------------------------------------------------------------------
# jenv - Background lazy loading for fast startup
# -------------------------------------------------------------------
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
