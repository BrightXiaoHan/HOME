set -l INSTALL_DIR (set -q HOMECLI_INSTALL_DIR; and echo $HOMECLI_INSTALL_DIR; or echo $HOME/.homecli)
set -l CONFIG_HOME (set -q XDG_CONFIG_HOME; and echo $XDG_CONFIG_HOME; or echo $INSTALL_DIR/config)
set -l DATA_HOME (set -q XDG_DATA_HOME; and echo $XDG_DATA_HOME; or echo $INSTALL_DIR/data)
set -l STATE_HOME (set -q XDG_STATE_HOME; and echo $XDG_STATE_HOME; or echo $INSTALL_DIR/state)
set -l CACHE_HOME (set -q XDG_CACHE_HOME; and echo $XDG_CACHE_HOME; or echo $INSTALL_DIR/cache)

if not set -q XDG_CONFIG_HOME
    set -gx XDG_CONFIG_HOME $CONFIG_HOME
end
if not set -q XDG_DATA_HOME
    set -gx XDG_DATA_HOME $DATA_HOME
end
if not set -q XDG_STATE_HOME
    set -gx XDG_STATE_HOME $STATE_HOME
end
if not set -q XDG_CACHE_HOME
    set -gx XDG_CACHE_HOME $CACHE_HOME
end

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
set -gx UV_PYTHON_PREFERENCE only-system
fish_add_path --path $UV_TOOL_BIN_DIR
set -gx GIT_CONFIG_GLOBAL $CONFIG_HOME/git/config
set -gx CONDARC $INSTALL_DIR/etc/mambarc
set -gx HOMECLI_SSH_DIR $INSTALL_DIR/etc/ssh
set -l __homecli_ssh_config $HOMECLI_SSH_DIR/config
if test -f $__homecli_ssh_config
    set -gx GIT_SSH_COMMAND "ssh -F $__homecli_ssh_config"
    function ssh --description 'HOMECLI ssh' --wraps ssh
        command ssh -F $__homecli_ssh_config $argv
    end
    function scp --description 'HOMECLI scp' --wraps scp
        command scp -F $__homecli_ssh_config $argv
    end
    function sftp --description 'HOMECLI sftp' --wraps sftp
        command sftp -F $__homecli_ssh_config $argv
    end
end

# pnpm
set -gx PNPM_HOME $INSTALL_DIR/pnpm
fish_add_path --path $PNPM_HOME
