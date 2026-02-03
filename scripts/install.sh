#!/bin/bash
Usage() {
	echo "Usage: $0 --mode <mode> --install-dir <install-dir> [--tarfile <tarfile>] [--old-install-dir <old-install-dir>] [--help]"
	echo "args can be one or more of the following :"
	echo "    --mode | -m     : Installation mode. local-install, online-install, unpack or relink (local-install is default)"
	echo "    --tarfile | -t  : Tarfile to unpack. Only used when mode is unpack"
	echo "    --install-dir   : Installation directory. Default: $HOME/.homecli"
	echo "	  --old-install-dir: Old installation directory. Only used when mode is unpack. Default: /home/runner/.homecli"
	echo "	  --old-home-dir   : Old home directory. Only used when mode is unpack. Default: /home/runner"
	echo "    --help | -h     : Show this help message"
	exit 1
}

while true; do
	case "$1" in
	--mode | -m)
		MODE=$2
		shift 2
		;;
	--tarfile | -t)
		TARFILE=$2
		shift 2
		;;
	--install-dir)
		INSTALL_DIR=$2
		shift 2
		;;
	--old-install-dir)
		OLD_INSTALL_DIR=$2
		shift 2
		;;
	--old-home-dir)
		OLD_HOME_DIR=$2
		shift 2
		;;
	--help | -h)
		Usage
		;;
	-*)
		echo "Unknown option: $1"
		Usage
		;;
	*)
		break
		;;
	esac
done
# MODE: local-install, online-install or unpack. Default: online-install
if [ -z "$MODE" ]; then
  MODE=online-install
fi

# INSTALL_DIR: Installation directory. Default: $HOME/.homecli
if [ -z "$INSTALL_DIR" ]; then
  INSTALL_DIR=${HOMECLI_INSTALL_DIR:-$HOME/.homecli}
fi

# XDG-style roots inside install dir so configs remain self-contained
CONFIG_HOME=${HOMECLI_XDG_CONFIG_HOME:-$INSTALL_DIR/config}
DATA_HOME=${HOMECLI_XDG_DATA_HOME:-$INSTALL_DIR/data}
STATE_HOME=${HOMECLI_XDG_STATE_HOME:-$INSTALL_DIR/state}
CACHE_HOME=${HOMECLI_XDG_CACHE_HOME:-$INSTALL_DIR/cache}
NVIM_DATA_DIR=$DATA_HOME/nvim

mkdir -p "$CONFIG_HOME" "$DATA_HOME" "$STATE_HOME" "$CACHE_HOME"
mkdir -p "$INSTALL_DIR/bin"

if [ "$MODE" = "local-install" ]; then
	CWD="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
	DIR="$INSTALL_DIR/HOME/general"
	mkdir -p $INSTALL_DIR/HOME
	cp -r $CWD/.. $INSTALL_DIR/HOME
	cd $INSTALL_DIR/HOME

elif [ "$MODE" = "unpack" ]; then
	if [ -z "$TARFILE" ]; then
		echo "Error: tarfile is required for unpack mode."
    Usage
	fi

	if [ ! -f "$TARFILE" ]; then
		echo "Error: tarfile not found: $TARFILE"
		Usage
	fi
	# Github action runner default home dir is /home/runner
	OLD_INSTALL_DIR=${OLD_INSTALL_DIR:-/home/runner/.homecli}
	OLD_HOME_DIR=${OLD_HOME_DIR:-/home/runner}
	mkdir -p $INSTALL_DIR
	tar -xvf "$TARFILE" -C "$INSTALL_DIR"
	mkdir -p $INSTALL_DIR/miniconda
	tar -xvf $INSTALL_DIR/miniconda.tar.gz -C $INSTALL_DIR/miniconda
	DIR="$INSTALL_DIR/HOME/general"
elif [ "$MODE" = "online-install" ]; then
	DIR="$INSTALL_DIR/HOME/general"
	mkdir -p $INSTALL_DIR
	git clone --recurse-submodules https://github.com/BrightXiaoHan/HOME $INSTALL_DIR/HOME
	cd $INSTALL_DIR/HOME
elif [ "$MODE" = "relink" ]; then
	DIR="$INSTALL_DIR/HOME/general"
else
  echo "Error: Unknown mode: $MODE"
  Usage
fi

# if general/nvim not exist, clone it
if [ ! -d $DIR/nvim ]; then
  git clone https://github.com/BrightXiaoHan/nvchad-starter.git $DIR/nvim
fi

# get current dir
mkdir -p ~/.config

# test if python3 is installed
if ! [ -x "$(command -v python3)" ]; then
	echo 'Error: python3 is not installed.' >&2
	exit 1
fi

rm -f $DIR/nvim/lua/custom || true

ln -sfn $DIR/nvim "$CONFIG_HOME/nvim"
ln -sfn $DIR/tmux "$CONFIG_HOME/tmux"
ln -sfn $DIR/fish "$CONFIG_HOME/fish"

mkdir -p "$CONFIG_HOME/git"
ln -sfn $DIR/gitconfig "$CONFIG_HOME/git/config"

mkdir -p "$INSTALL_DIR/etc"
ln -sfn $DIR/ssh "$INSTALL_DIR/etc/ssh"
ln -sfn $DIR/mambarc "$INSTALL_DIR/etc/mambarc"

mkdir -p ~/.ssh
# add authorized_keys into .ssh/authorized_keys
if [ ! -f ~/.ssh/authorized_keys ]; then
	touch ~/.ssh/authorized_keys
fi
# if id_rsa.pub not in authorized_keys, add it
if ! grep -q "$(cat $INSTALL_DIR/HOME/general/ssh/id_rsa.pub)" ~/.ssh/authorized_keys; then
	cat $INSTALL_DIR/HOME/general/ssh/id_rsa.pub >>~/.ssh/authorized_keys
fi

if [ "$MODE" = "local-install" ] || [ "$MODE" = "online-install" ]; then
	PYTHONPATH="./:$PYTHONPATH" \
		PATH="$INSTALL_DIR/miniconda/bin:$INSTALL_DIR/nodejs/bin:$PATH" \
		HOMECLI_INSTALL_DIR=$INSTALL_DIR \
		XDG_CONFIG_HOME=$CONFIG_HOME \
		XDG_DATA_HOME=$DATA_HOME \
		XDG_STATE_HOME=$STATE_HOME \
		XDG_CACHE_HOME=$CACHE_HOME \
		python3 homecli/install.py
	if [ -d "$NVIM_DATA_DIR" ]; then
		ln -sfn "$NVIM_DATA_DIR" "$INSTALL_DIR/nvim"
	fi
elif [ "$MODE" = "unpack" ]; then
	mkdir -p "$DATA_HOME"
	# Move packaged nvim data into XDG data dir and link back
	if [ -d "$INSTALL_DIR/nvim" ] && [ ! -L "$INSTALL_DIR/nvim" ]; then
		rm -rf "$DATA_HOME/nvim"
		mv "$INSTALL_DIR/nvim" "$DATA_HOME/nvim"
	fi
	ln -sfn "$DATA_HOME/nvim" "$INSTALL_DIR/nvim"
	. $INSTALL_DIR/miniconda/bin/activate
  # find python in uv
  PYTHON_BIN_FOLDER=$(dirname $(find $INSTALL_DIR/uv/python -name python ! -type d | awk 'NR==1'))
	CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1 PATH=$PYTHON_BIN_FOLDER:$PATH conda-unpack

	# Re-link broken symlinks
	for file in $(find "$NVIM_DATA_DIR" -type l ! -exec test -e {} \; -print); do
		old=$(readlink -m $file)
		if [[ -n "$OLD_HOME_DIR" && $old == $OLD_HOME_DIR* ]]; then
			new=${old/#$OLD_HOME_DIR/$HOME}
			rm $file
			ln -sf $new $file
		fi
	done

	for file in $(find $INSTALL_DIR -type l ! -exec test -e {} \; -print); do
		old=$(readlink -m $file)
		if [[ $old == $OLD_INSTALL_DIR* ]]; then
			new=$(echo $old | sed "s|$OLD_INSTALL_DIR|$INSTALL_DIR|")
			rm $file
			ln -sf $new $file
		fi
	done

	for file in $(find $INSTALL_DIR -name "pyvenv.cfg"); do
		sed -i "s|$OLD_INSTALL_DIR|$INSTALL_DIR|g" $file
	done

	for file in $(find "$NVIM_DATA_DIR" -name "pyvenv.cfg"); do
		sed -i "s|$OLD_INSTALL_DIR|$INSTALL_DIR|g" $file
		sed -i "s|venv .*/nvim|venv $NVIM_DATA_DIR|g" $file
	done

	# Fix absolute paths embedded in UV tool scripts (e.g., conda-pack shebangs)
	for file in $(find "$INSTALL_DIR/bin" "$INSTALL_DIR/uv/tool" -type f 2>/dev/null); do
		if grep -q "$OLD_INSTALL_DIR" "$file" 2>/dev/null; then
			sed -i "s|$OLD_INSTALL_DIR|$INSTALL_DIR|g" "$file"
		fi
	done

	for file in $(find "$NVIM_DATA_DIR/mason/bin" -type l 2>/dev/null); do
		origin_file=$(readlink -m $file)
		sed -i "s|$OLD_HOME_DIR|$HOME|g" $origin_file
	done

	for file in $(find $INSTALL_DIR/bin -type l); do
		origin_file=$(readlink -m $file)
		sed -i "s|$OLD_INSTALL_DIR|$INSTALL_DIR|g" $origin_file
	done
elif [ "$MODE" = "relink" ]; then
	ln -sfn "$INSTALL_DIR/nvim" "$NVIM_DATA_DIR"
fi

# create wrapper to enter isolated fish session with XDG dirs
cat >"$INSTALL_DIR/bin/homecli-fish" <<EOF
#!/usr/bin/env bash
export HOMECLI_INSTALL_DIR="$INSTALL_DIR"
export XDG_CONFIG_HOME="$CONFIG_HOME"
export XDG_DATA_HOME="$DATA_HOME"
export XDG_STATE_HOME="$STATE_HOME"
export XDG_CACHE_HOME="$CACHE_HOME"
export MAMBA_ROOT_PREFIX="$INSTALL_DIR/miniconda"
export MAMBA_EXE="$INSTALL_DIR/bin/mamba"
export UV_TOOL_DIR="$INSTALL_DIR/uv/tool"
export UV_TOOL_BIN_DIR="$INSTALL_DIR/uv/tool/bin"
export UV_PYTHON_INSTALL_DIR="$INSTALL_DIR/uv/python"
export UV_PYTHON_PREFERENCE="only-managed"
export GIT_CONFIG_GLOBAL="$CONFIG_HOME/git/config"
export CONDARC="$INSTALL_DIR/etc/mambarc"
export HOMECLI_SSH_DIR="$INSTALL_DIR/etc/ssh"
export PATH="$INSTALL_DIR/bin:$INSTALL_DIR/miniconda/bin:$INSTALL_DIR/uv/tool/bin:\$PATH"
exec "$INSTALL_DIR/miniconda/bin/fish" "\$@"
EOF
chmod +x "$INSTALL_DIR/bin/homecli-fish"

# add fish wrapper alias to .bashrc if missing
if ! grep -q 'alias fish=.*homecli-fish' ~/.bashrc 2>/dev/null; then
	echo "alias fish='$INSTALL_DIR/bin/homecli-fish'" >>~/.bashrc
fi
