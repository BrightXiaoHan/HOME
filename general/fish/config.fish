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

function start-proxy
    shadowsocksr-cli --setting-url https://xxjcdy.cfd/link/suKDLaU0nUv6Ye1d
    shadowsocksr-cli -u
    shadowsocksr-cli --fast-node
    shadowsocksr-cli --http-proxy start
end

# proxy alias
alias setproxy="set ALL_PROXY 'socks5://127.0.0.1:1080'"
alias unsetproxy="set -e ALL_PROXY"
alias ip="curl http://ip-api.com/json/?lang=zh-CN"
alias sethttpproxy="set -gx HTTPS_PROXY 'http://127.0.0.1:7890'"
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

source (dirname (status --current-filename))/cmd.fish

# if starship and zoxide installed, init them
if type starship >/dev/null 2>&1
    starship init fish | source
end
if type zoxide >/dev/null 2>&1
    zoxide init fish | source
end
