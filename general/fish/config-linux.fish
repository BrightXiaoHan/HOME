# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f ~/.cache/homecli/miniconda/bin/conda
    eval ~/.cache/homecli/miniconda/bin/conda "shell.fish" "hook" $argv | source
end
# <<< conda initialize <<<

set -gx PATH ~/.cache/homecli/bin $PATH
set -gx PATH ~/.cache/homecli/nodejs/bin $PATH

if not nvim --headless -c quit > /dev/null 2>&1
    alias nvim='nvim --appimage-extract-and-run'
end

set -gx CC ~/.cache/homecli/miniconda/bin/gcc
set -gx CXX ~/.cache/homecli/miniconda/bin/g++
