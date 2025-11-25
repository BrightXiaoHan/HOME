#!/bin/bash
set -euo pipefail

DIR=${HOMECLI_INSTALL_DIR:-$HOME/.homecli}
CONFIG_HOME=${HOMECLI_XDG_CONFIG_HOME:-$DIR/config}
DATA_HOME=${HOMECLI_XDG_DATA_HOME:-$DIR/data}
STATE_HOME=${HOMECLI_XDG_STATE_HOME:-$DIR/state}
CACHE_HOME=${HOMECLI_XDG_CACHE_HOME:-$DIR/cache}

export HOMECLI_INSTALL_DIR="$DIR"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$CONFIG_HOME}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$DATA_HOME}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$STATE_HOME}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$CACHE_HOME}"
export PATH="$DIR/bin:$DIR/miniconda/bin:$PATH"
export MAMBA_ROOT_PREFIX="$DIR/miniconda"

cd "$DIR/HOME"

git pull
PYTHONPATH="./:${PYTHONPATH:-}" python3 homecli/install.py -c update
"$DIR/bin/mamba" update --all
