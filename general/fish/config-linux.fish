set -l INSTALL_DIR (set -q HOMECLI_INSTALL_DIR; and echo $HOMECLI_INSTALL_DIR; or echo $HOME/.homecli)

# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba init' !!
set -gx MAMBA_EXE "$INSTALL_DIR/bin/mamba"
set -gx MAMBA_ROOT_PREFIX "$INSTALL_DIR/miniconda"
$MAMBA_EXE shell hook --shell fish --root-prefix $MAMBA_ROOT_PREFIX | source
micromamba activate
# <<< mamba initialize <<<

fish_add_path --path $INSTALL_DIR/bin
alias node="$INSTALL_DIR/miniconda/bin/node"
alias npm="$INSTALL_DIR/miniconda/bin/npm"
alias fish="$INSTALL_DIR/miniconda/bin/fish"
alias tmux="$INSTALL_DIR/miniconda/bin/tmux"
# Mamba
set -gx MAMBA_ROOT_PREFIX $INSTALL_DIR/miniconda

set -gx CPPFLAGS "-I$CONDA_PREFIX/include " $CPPFLAGS
set -gx LDFLAGS "-L$CONDA_PREFIX/lib " $LDFLAGS
set -gx CONFIGURE_OPTS "-with-openssl=$CONDA_PREFIX " $CONFIGURE_OPTS

if not nvim --headless -c quit >/dev/null 2>&1
    alias nvim='nvim --appimage-extract-and-run'
end

set -gx CC $INSTALL_DIR/miniconda/bin/gcc
set -gx CXX $INSTALL_DIR/miniconda/bin/g++

# uv
set -gx UV_TOOL_DIR $INSTALL_DIR/uv/tool
set -gx UV_TOOL_BIN_DIR $INSTALL_DIR/uv/tool/bin
set -gx UV_PYTHON_INSTALL_DIR $INSTALL_DIR/uv/python
set -gx UV_PYTHON_PREFERENCE only-managed
fish_add_path --path $UV_TOOL_BIN_DIR
set -gx GIT_CONFIG_GLOBAL $INSTALL_DIR/HOME/general/gitconfig
set -gx SSH_HOME $INSTALL_DIR/HOME/general/ssh

# pnpm
set -gx PNPM_HOME $INSTALL_DIR/pnpm
fish_add_path --path $PNPM_HOME
