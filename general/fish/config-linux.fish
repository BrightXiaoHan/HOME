# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f ~/.cache/homecli/miniconda/bin/conda
    eval ~/.cache/homecli/miniconda/bin/conda "shell.fish" "hook" $argv | source
end
# <<< conda initialize <<<

set -gx PATH ~/.cache/homecli/bin $PATH
# Mamba
set -gx MAMBA_ROOT_PREFIX ~/.cache/homecli/miniconda

# pyenv
set -gx PYENV_ROOT ~/.cache/homecli/pyenv
set -gx PATH $PYENV_ROOT/bin $PATH
# if pyenv exists, initialize it
if test -f $PYENV_ROOT/bin/pyenv
    pyenv init - | source
end


set -gx LD_LIBRARY_PATH "$CONDA_PREFIX/lib"
set -gx CPPFLAGS "-I$CONDA_PREFIX/include " $CPPFLAGS
set -gx LDFLAGS "-L$CONDA_PREFIX/lib " $LDFLAGS
set -gx CONFIGURE_OPTS "-with-openssl=$CONDA_PREFIX " $CONFIGURE_OPTS

if not nvim --headless -c quit > /dev/null 2>&1
    alias nvim='nvim --appimage-extract-and-run'
end

set -gx CC ~/.cache/homecli/miniconda/bin/gcc
set -gx CXX ~/.cache/homecli/miniconda/bin/g++
