set -l INSTALL_DIR (set -q HOMECLI_INSTALL_DIR; and echo $HOMECLI_INSTALL_DIR; or echo $HOME/.homecli)

# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba init' !!
set -gx MAMBA_EXE "$INSTALL_DIR/bin/mamba"
set -gx MAMBA_ROOT_PREFIX "$INSTALL_DIR/miniconda"
$MAMBA_EXE shell hook --shell fish --root-prefix $MAMBA_ROOT_PREFIX | source
micromamba activate
# <<< mamba initialize <<<

set -gx PATH $INSTALL_DIR/bin $PATH
# Mamba
set -gx MAMBA_ROOT_PREFIX $INSTALL_DIR/miniconda

# pipx
set -gx PIPX_HOME $INSTALL_DIR/pipx
set -gx PIPX_BIN_DIR $INSTALL_DIR/bin

# pyenv
set -gx MAKE_OPTS -j(nproc --ignore=1)  # pyenv set MAKE_OPTS to number of cores minus 1
set -gx PYENV_ROOT $INSTALL_DIR/pyenv
set -gx PATH $PYENV_ROOT/bin $PATH
# if pyenv exists, initialize it
if test -f $PYENV_ROOT/bin/pyenv
    pyenv init - | source
end

set -gx CPPFLAGS "-I$CONDA_PREFIX/include " $CPPFLAGS
set -gx LDFLAGS "-L$CONDA_PREFIX/lib " $LDFLAGS
set -gx CONFIGURE_OPTS "-with-openssl=$CONDA_PREFIX " $CONFIGURE_OPTS

if not nvim --headless -c quit > /dev/null 2>&1
    alias nvim='nvim --appimage-extract-and-run'
end

set -gx CC $INSTALL_DIR/miniconda/bin/gcc
set -gx CXX $INSTALL_DIR/miniconda/bin/g++
