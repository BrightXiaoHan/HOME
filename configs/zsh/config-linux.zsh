INSTALL_DIR="${HOMECLI_INSTALL_DIR:-$HOME/.homecli}"
CONFIG_HOME="${XDG_CONFIG_HOME:-$INSTALL_DIR/config}"
DATA_HOME="${XDG_DATA_HOME:-$INSTALL_DIR/data}"
STATE_HOME="${XDG_STATE_HOME:-$INSTALL_DIR/state}"
CACHE_HOME="${XDG_CACHE_HOME:-$INSTALL_DIR/cache}"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$CONFIG_HOME}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$DATA_HOME}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$STATE_HOME}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$CACHE_HOME}"

# >>> mamba initialize >>>
# Mirrors the fish micromamba initialization using the zsh hook.
export MAMBA_EXE="$INSTALL_DIR/bin/mamba"
export MAMBA_ROOT_PREFIX="$INSTALL_DIR/miniconda"
if [[ -x "$MAMBA_EXE" ]]; then
  eval "$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX")"
  micromamba activate >/dev/null 2>&1 || true
fi
# <<< mamba initialize <<<

_homecli_fish_add_path "$INSTALL_DIR/bin"
alias node="$INSTALL_DIR/miniconda/bin/node"
alias npm="$INSTALL_DIR/miniconda/bin/npm"
alias tmux="$INSTALL_DIR/miniconda/bin/tmux"

export CPPFLAGS="-I${CONDA_PREFIX:-}/include ${CPPFLAGS:-}"
export LDFLAGS="-L${CONDA_PREFIX:-}/lib ${LDFLAGS:-}"
export CONFIGURE_OPTS="-with-openssl=${CONDA_PREFIX:-} ${CONFIGURE_OPTS:-}"

if command -v nvim >/dev/null 2>&1 && ! nvim --headless -c quit >/dev/null 2>&1; then
  alias nvim='nvim --appimage-extract-and-run'
fi

export CC="$INSTALL_DIR/miniconda/bin/gcc"
export CXX="$INSTALL_DIR/miniconda/bin/g++"

# uv
export UV_TOOL_DIR="$INSTALL_DIR/uv/tool"
export UV_TOOL_BIN_DIR="$INSTALL_DIR/uv/tool/bin"
export UV_PYTHON_INSTALL_DIR="$INSTALL_DIR/uv/python"
export UV_PYTHON_PREFERENCE=system
_homecli_fish_add_path "$UV_TOOL_BIN_DIR"

export GIT_CONFIG_GLOBAL="$CONFIG_HOME/git/config"
export CONDARC="$INSTALL_DIR/etc/mambarc"
export HOMECLI_SSH_DIR="$INSTALL_DIR/etc/ssh"
export PASSWORD_STORE_DIR="$INSTALL_DIR/password-store"
__homecli_ssh_config="$HOMECLI_SSH_DIR/config"
if [[ -f "$__homecli_ssh_config" ]]; then
  export GIT_SSH_COMMAND="ssh -F $__homecli_ssh_config -i $HOMECLI_SSH_DIR/id_rsa_git"
fi
unset __homecli_ssh_config

# pnpm
export PNPM_HOME="$INSTALL_DIR/pnpm"
_homecli_fish_add_path "$PNPM_HOME"

unset INSTALL_DIR CONFIG_HOME DATA_HOME STATE_HOME CACHE_HOME
