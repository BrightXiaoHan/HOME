emulate -L zsh

[[ -r "${ZDOTDIR:-$HOME}/env-core.zsh" ]] && source "${ZDOTDIR:-$HOME}/env-core.zsh"

if [[ -n ${__HOMECLI_ZSH_ENV_LOADED:-} ]]; then
  return
fi
typeset -g __HOMECLI_ZSH_ENV_LOADED=1

typeset -ga path

_homecli_path_contains() {
  local candidate="$1"
  local entry
  for entry in "${path[@]}"; do
    [[ "$entry" == "$candidate" ]] && return 0
  done
  return 1
}

_homecli_path_prepend() {
  local -a entries
  local entry
  entries=()
  for entry in "$@"; do
    [[ -n "$entry" ]] && entries+=("$entry")
  done
  (( ${#entries[@]} > 0 )) && path=("${entries[@]}" "${path[@]}")
}

_homecli_fish_add_path() {
  local -a entries
  local entry
  entries=()
  for entry in "$@"; do
    [[ -n "$entry" && -d "$entry" ]] || continue
    _homecli_path_contains "$entry" && continue
    entries+=("$entry")
  done
  (( ${#entries[@]} > 0 )) && path=("${entries[@]}" "${path[@]}")
}

export EDITOR="${EDITOR:-nvim}"

_homecli_path_prepend bin
_homecli_fish_add_path "$HOME/.local/bin"

if [[ -n ${HOMECLI_EXTRA_FISH_PATHS:-} ]]; then
  for __homecli_extra_path in ${(s.:.)HOMECLI_EXTRA_FISH_PATHS}; do
    _homecli_fish_add_path "$__homecli_extra_path"
  done
  unset __homecli_extra_path
fi

# Poetry
export POETRY_VIRTUALENVS_IN_PROJECT="${POETRY_VIRTUALENVS_IN_PROJECT:-true}"

# Related to https://github.com/BrightXiaoHan/HOME/issues/2
export CRYPTOGRAPHY_OPENSSL_NO_LEGACY="${CRYPTOGRAPHY_OPENSSL_NO_LEGACY:-1}"

# NodeJS
_homecli_path_prepend node_modules/.bin

[[ -r "${ZDOTDIR:-$HOME}/config-local.zsh" ]] && source "${ZDOTDIR:-$HOME}/config-local.zsh"

case "$(uname)" in
  Darwin)
    [[ -r "${ZDOTDIR:-$HOME}/config-osx.zsh" ]] && source "${ZDOTDIR:-$HOME}/config-osx.zsh"
    ;;
  Linux)
    [[ -r "${ZDOTDIR:-$HOME}/config-linux.zsh" ]] && source "${ZDOTDIR:-$HOME}/config-linux.zsh"
    ;;
esac

export PATH

unfunction _homecli_path_contains _homecli_path_prepend _homecli_fish_add_path 2>/dev/null || true
