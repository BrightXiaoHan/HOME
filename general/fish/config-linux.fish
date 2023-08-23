# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f ~/.cache/homecli/miniconda/bin/conda
    eval ~/.cache/homecli/miniconda/bin/conda "shell.fish" "hook" $argv | source
end
# <<< conda initialize <<<

set -gx PATH ~/.cache/homecli/bin $PATH
set -gx PATH ~/.cache/homecli/nodejs/bin $PATH
set -gx PATH ~/.cache/homecli/miniconda/bin $PATH
set -gx LD_LIBRARY_PATH ~/.cache/homecli/miniconda/lib $LD_LIBRARY_PATH

if not nvim --headless -c quit > /dev/null 2>&1
    alias nvim='nvim --appimage-extract-and-run'
end

# x86_64 or aarch64
if test (uname -m) = "x86_64"
    set -gx CC ~/.cache/homecli/miniconda/bin/x86_64-conda-linux-gnu-gcc
else if test (uname -m) = "aarch64"
    set -gx CC ~/.cache/homecli/miniconda/bin/aarch64-conda-linux-gnu-gcc
end
