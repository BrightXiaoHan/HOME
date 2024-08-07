set fish_greeting ""

set -gx TERM xterm-256color

# theme
set -g theme_color_scheme terminal-dark
set -g fish_prompt_pwd_dir_length 1
set -g theme_display_user yes
set -g theme_hide_hostname no
set -g theme_hostname always

set -gx EDITOR nvim

set -gx PATH bin $PATH
set -gx PATH ~/.local/bin $PATH

# Poetry
set -gx POETRY_VIRTUALENVS_IN_PROJECT true

# Related to https://github.com/BrightXiaoHan/HOME/issues/2
set -gx CRYPTOGRAPHY_OPENSSL_NO_LEGACY 1

# NodeJS
set -gx PATH node_modules/.bin $PATH

# proxy alias
alias setproxy="set ALL_PROXY 'socks5://127.0.0.1:1080'"
alias unsetproxy="set -e ALL_PROXY"
alias ip="curl http://ip-api.com/json/?lang=zh-CN"
alias sethttpproxy="set HTTPS_PROXY 'http://127.0.0.1:7890'"
alias unsethttpproxy="set -e HTTPS_PROXY"

set LOCAL_CONFIG (dirname (status --current-filename))/config-local.fish
if test -f $LOCAL_CONFIG
  source $LOCAL_CONFIG
end

switch (uname)
  case Darwin
    source (dirname (status --current-filename))/config-osx.fish
  case Linux
    source (dirname (status --current-filename))/config-linux.fish
end

# if starship and zoxide installed, init them
if type starship > /dev/null 2>&1
  starship init fish | source
end
if type zoxide > /dev/null 2>&1
  zoxide init fish | source
end

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /opt/homebrew/Caskroom/miniconda/base/bin/conda
    eval /opt/homebrew/Caskroom/miniconda/base/bin/conda "shell.fish" "hook" $argv | source
else
    if test -f "/opt/homebrew/Caskroom/miniconda/base/etc/fish/conf.d/conda.fish"
        . "/opt/homebrew/Caskroom/miniconda/base/etc/fish/conf.d/conda.fish"
    else
        set -x PATH "/opt/homebrew/Caskroom/miniconda/base/bin" $PATH
    end
end
# <<< conda initialize <<<
