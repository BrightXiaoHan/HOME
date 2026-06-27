# Keep zsh startup files together under the Home CLI zsh config directory.
if [[ -z ${ZDOTDIR:-} ]]; then
  __homecli_zdotdir="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
  if [[ -d "$__homecli_zdotdir" ]]; then
    export ZDOTDIR="$__homecli_zdotdir"
  else
    __homecli_zshenv="${${(%):-%N}:A}"
    export ZDOTDIR="${__homecli_zshenv:h}"
  fi
  unset __homecli_zdotdir __homecli_zshenv
fi

# Non-interactive-safe environment for scripts/SSH command execution.
[[ -r "${ZDOTDIR:-$HOME}/env-core.zsh" ]] && source "${ZDOTDIR:-$HOME}/env-core.zsh"
