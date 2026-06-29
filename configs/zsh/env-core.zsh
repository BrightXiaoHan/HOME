emulate -L zsh

# Minimal, non-interactive-safe environment.
# This file is loaded from .zshenv, so keep it fast and silent:
# no prompts, no aliases, no compinit, no command substitutions that can hang.
if [[ -n ${__HOMECLI_ZSH_ENV_CORE_LOADED:-} ]]; then
  return
fi
typeset -g __HOMECLI_ZSH_ENV_CORE_LOADED=1

typeset -ga path

_homecli_core_path_contains() {
  local candidate="$1"
  local entry
  for entry in "${path[@]}"; do
    [[ "$entry" == "$candidate" ]] && return 0
  done
  return 1
}

_homecli_core_add_path() {
  local -a entries
  local entry
  entries=()
  for entry in "$@"; do
    [[ -n "$entry" && -d "$entry" ]] || continue
    _homecli_core_path_contains "$entry" && continue
    entries+=("$entry")
  done
  (( ${#entries[@]} > 0 )) && path=("${entries[@]}" "${path[@]}")
}

export EDITOR="${EDITOR:-nvim}"
export POETRY_VIRTUALENVS_IN_PROJECT="${POETRY_VIRTUALENVS_IN_PROJECT:-true}"
export CRYPTOGRAPHY_OPENSSL_NO_LEGACY="${CRYPTOGRAPHY_OPENSSL_NO_LEGACY:-1}"

_homecli_core_add_path "$HOME/.local/bin"

# If Home CLI is installed, expose its self-contained paths to non-interactive zsh too.
# This makes `ssh host 'zsh -c ...'` closer to an interactive login without loading
# prompt/completion/alias code.
__homecli_install_dir="${HOMECLI_INSTALL_DIR:-$HOME/.homecli}"
if [[ -n ${HOMECLI_INSTALL_DIR:-} || -d "$__homecli_install_dir/bin" || -d "$__homecli_install_dir/config" ]]; then
  export HOMECLI_INSTALL_DIR="$__homecli_install_dir"

  export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOMECLI_INSTALL_DIR/config}"
  export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOMECLI_INSTALL_DIR/data}"
  export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOMECLI_INSTALL_DIR/state}"
  export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOMECLI_INSTALL_DIR/cache}"
  if [[ -z ${STARSHIP_CONFIG:-} && -f "$XDG_CONFIG_HOME/starship.toml" ]]; then
    export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship.toml"
  fi

  export MAMBA_EXE="${MAMBA_EXE:-$HOMECLI_INSTALL_DIR/bin/mamba}"
  export MAMBA_ROOT_PREFIX="${MAMBA_ROOT_PREFIX:-$HOMECLI_INSTALL_DIR/miniconda}"

  export UV_TOOL_DIR="${UV_TOOL_DIR:-$HOMECLI_INSTALL_DIR/uv/tool}"
  export UV_TOOL_BIN_DIR="${UV_TOOL_BIN_DIR:-$HOMECLI_INSTALL_DIR/uv/tool/bin}"
  export UV_PYTHON_INSTALL_DIR="${UV_PYTHON_INSTALL_DIR:-$HOMECLI_INSTALL_DIR/uv/python}"
  export UV_PYTHON_PREFERENCE="${UV_PYTHON_PREFERENCE:-system}"

  export GIT_CONFIG_GLOBAL="${GIT_CONFIG_GLOBAL:-$XDG_CONFIG_HOME/git/config}"
  export CONDARC="${CONDARC:-$HOMECLI_INSTALL_DIR/etc/mambarc}"
  export HOMECLI_SSH_DIR="${HOMECLI_SSH_DIR:-$HOMECLI_INSTALL_DIR/etc/ssh}"
  export PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOMECLI_INSTALL_DIR/password-store}"
  export PNPM_HOME="${PNPM_HOME:-$HOMECLI_INSTALL_DIR/pnpm}"

  __homecli_ssh_config="$HOMECLI_SSH_DIR/config"
  if [[ -z ${GIT_SSH_COMMAND:-} && -f "$__homecli_ssh_config" ]]; then
    export GIT_SSH_COMMAND="ssh -F $__homecli_ssh_config -i $HOMECLI_SSH_DIR/id_rsa_git"
  fi

  _homecli_core_add_path \
    "$HOMECLI_INSTALL_DIR/bin" \
    "$MAMBA_ROOT_PREFIX/bin" \
    "$UV_TOOL_BIN_DIR" \
    "$PNPM_HOME"
fi

export PATH

unset __homecli_install_dir __homecli_ssh_config
unfunction _homecli_core_path_contains _homecli_core_add_path 2>/dev/null || true
