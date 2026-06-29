[[ -r "${ZDOTDIR:-$HOME}/env.zsh" ]] && source "${ZDOTDIR:-$HOME}/env.zsh"
[[ -r "${ZDOTDIR:-$HOME}/cmd.zsh" ]] && source "${ZDOTDIR:-$HOME}/cmd.zsh"

setopt interactive_comments
unsetopt nomatch
setopt hist_ignore_dups
setopt share_history
bindkey -e
# Be explicit for SSH/minimal terminals where erase/backspace differs.
if [[ -t 0 ]]; then
  stty erase '^?' 2>/dev/null || true
fi
bindkey '^?' backward-delete-char
bindkey '^H' backward-delete-char
bindkey '^[[3~' delete-char
[[ -n ${terminfo[kdch1]:-} ]] && bindkey "${terminfo[kdch1]}" delete-char

HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
HISTSIZE="${HISTSIZE:-10000}"
SAVEHIST="${SAVEHIST:-10000}"

autoload -Uz compinit
__homecli_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
mkdir -p "${__homecli_zcompdump:h}" 2>/dev/null
compinit -i -d "$__homecli_zcompdump"
unset __homecli_zcompdump

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi
