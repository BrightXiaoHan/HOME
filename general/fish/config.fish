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
set -gx PATH ~/bin $PATH
set -gx PATH ~/.local/bin $PATH
set -gx PATH ~/.cache/homecli/bin $PATH
set -gx PATH ~/.cache/homecli/nodejs/bin $PATH

# NodeJS
set -gx PATH node_modules/.bin $PATH

switch (uname)
  case Darwin
    source (dirname (status --current-filename))/config-osx.fish
  case Linux
    source (dirname (status --current-filename))/config-linux.fish
  case '*'
    source (dirname (status --current-filename))/config-windows.fish
end

set LOCAL_CONFIG (dirname (status --current-filename))/config-local.fish
if test -f $LOCAL_CONFIG
  source $LOCAL_CONFIG
end


# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
eval ~/.cache/homecli/miniconda/bin/conda "shell.fish" "hook" $argv | source
~/.cache/homecli/miniconda/bin/conda config --set auto_activate_base false
# <<< conda initialize <<<
