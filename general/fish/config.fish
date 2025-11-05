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
fish_add_path --path ~/.local/bin

# Poetry
set -gx POETRY_VIRTUALENVS_IN_PROJECT true

# Related to https://github.com/BrightXiaoHan/HOME/issues/2
set -gx CRYPTOGRAPHY_OPENSSL_NO_LEGACY 1

# NodeJS
set -gx PATH node_modules/.bin $PATH

set -l __config_dir (path dirname (status --current-filename))

set -l __local_config $__config_dir/config-local.fish
if test -f $__local_config
    source $__local_config
end

switch (uname)
    case Darwin
        source $__config_dir/config-osx.fish
    case Linux
        source $__config_dir/config-linux.fish
end

source $__config_dir/cmd.fish

if status is-interactive
    if command -q starship
        starship init fish | source
    end
    if command -q zoxide
        zoxide init fish | source
    end
end
