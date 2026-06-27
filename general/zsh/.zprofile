# Login-shell environment only. Interactive commands/functions live in .zshrc.
[[ -r "${ZDOTDIR:-$HOME}/env.zsh" ]] && source "${ZDOTDIR:-$HOME}/env.zsh"
