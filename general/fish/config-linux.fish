set -l INSTALL_DIR (set -q HOMECLI_INSTALL_DIR; and echo $HOMECLI_INSTALL_DIR; or echo $HOME/.homecli)

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f $INSTALL_DIR/miniconda/bin/conda
    eval $INSTALL_DIR/miniconda/bin/conda "shell.fish" "hook" $argv | source
end
# <<< conda initialize <<<

set -gx PATH $INSTALL_DIR/bin $PATH
# Mamba
set -gx MAMBA_ROOT_PREFIX $INSTALL_DIR/miniconda

# pipx
set -gx PIPX_HOME $INSTALL_DIR/pipx

# pyenv
set -gx PYENV_ROOT $INSTALL_DIR/pyenv
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

set -gx CC $INSTALL_DIR/miniconda/bin/gcc
set -gx CXX $INSTALL_DIR/miniconda/bin/g++
