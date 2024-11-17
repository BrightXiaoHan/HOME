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

# remove config files
rm -rf ~/.config/nvim \
	~/.config/tmux \
	~/.config/fish \
	~/.gitconfig \
	~/.ssh/config \
	~/.ssh/id_rsa.pub \
	~/.mambarc

# remove nvim plugins
rm -rf ~/.local/share/nvim

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

# if general/NvChad not exist, clone it
if [ ! -d $DIR/NvChad ]; then
  git clone https://github.com/BrightXiaoHan/nvchad-starter.git $DIR/NvChad
fi

# get current dir
mkdir -p ~/.config

# test if python3 is installed
if ! [ -x "$(command -v python3)" ]; then
	echo 'Error: python3 is not installed.' >&2
	exit 1
fi

# link nvim dir if .config/nvim not exist
if [ ! -d ~/.config/nvim ]; then
	rm -f $DIR/NvChad/lua/custom || true
	ln -sf $DIR/NvChad/ ~/.config/nvim
else
	echo "nvim config already exist. Please backup or remove it."
	exit 1
fi

# link tmux dir if .config/tmux not exist
if [ ! -d ~/.config/tmux ]; then
	ln -sf $DIR/tmux/ ~/.config/
else
	echo "tmux config already exist. Please backup or remove it."
	exit 1
fi

# link fish dir if .config/fish not exist
if [ ! -d ~/.config/fish ]; then
	ln -sf $DIR/fish/ ~/.config/
else
	echo "fish config already exist. Please backup or remove it."
	exit 1
fi

if [ ! -d ~/.ssh ]; then
	mkdir ~/.ssh
fi
ln -sf $DIR/ssh/config ~/.ssh/config
ln -sf $DIR/ssh/id_rsa.pub ~/.ssh/id_rsa.pub

# add authorized_keys into .ssh/authorized_keys
if [ ! -f ~/.ssh/authorized_keys ]; then
	touch ~/.ssh/authorized_keys
fi
# if id_rsa.pub not in authorized_keys, add it
if ! grep -q "$(cat ~/.ssh/id_rsa.pub)" ~/.ssh/authorized_keys; then
	cat ~/.ssh/id_rsa.pub >>~/.ssh/authorized_keys
fi

ln -sf $DIR/gitconfig ~/.gitconfig
ln -sf $DIR/mambarc ~/.mambarc

if [ "$MODE" = "local-install" ] || [ "$MODE" = "online-install" ]; then
	PYTHONPATH="./:$PYTHONPATH" \
		PATH="$INSTALL_DIR/miniconda/bin:$INSTALL_DIR/nodejs/bin:$PATH" \
		HOMECLI_INSTALL_DIR=$INSTALL_DIR \
		python3 homecli/install.py
	mv $HOME/.local/share/nvim $INSTALL_DIR/nvim
	ln -sf $INSTALL_DIR/nvim $HOME/.local/share/nvim
elif [ "$MODE" = "unpack" ]; then
	mkdir -p ~/.local/share && ln -sf $INSTALL_DIR/nvim/ ~/.local/share/nvim
	. $INSTALL_DIR/miniconda/bin/activate
  # find python in uv
  PYTHON_BIN_FOLDER=$(dirname $(find $INSTALL_DIR/uv/python -name python ! -type d | awk 'NR==1'))
	CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1 PATH=$PYTHON_BIN_FOLDER:$PATH conda-pack

	# Re-link broken symlinks
	for file in $(find $HOME/.local/share/nvim/ -type l ! -exec test -e {} \; -print); do
		old=$(readlink -m $file)
		# Re-link to the new location with $HOME prefix
		# e.g.> /root/.homecli/xxx -> /home/hanbing/.homecli/xxx

		if [[ $old == *".local/share/nvim"* ]]; then
			prefix=$(echo $old | sed 's/\.local\/share\/nvim.*//')
			# replace prefix with $HOME
			new=$(echo $old | sed "s|^$prefix|$HOME/|")
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

	for file in $(find $HOME/.local/share/nvim -name "pyvenv.cfg"); do
		sed -i "s|$OLD_INSTALL_DIR|$INSTALL_DIR|g" $file
		sed -i "s|venv .*/.local/share/nvim|venv $HOME/.local/share/nvim|g" $file
	done

	for file in $(find $HOME/.local/share/nvim/mason/bin -type l); do
		origin_file=$(readlink -m $file)
		sed -i "s|$OLD_HOME_DIR|$HOME|g" $origin_file
	done

	for file in $(find $INSTALL_DIR/bin -type l); do
		origin_file=$(readlink -m $file)
		sed -i "s|$OLD_INSTALL_DIR|$INSTALL_DIR|g" $origin_file
	done
elif [ "$MODE" = "relink" ]; then
	ln -sf $INSTALL_DIR/nvim/ ~/.local/share/nvim
fi

# add fish path to .bashrc
if ! grep -q 'alias fish.*' ~/.bashrc; then
	echo "alias fish='$INSTALL_DIR/miniconda/bin/fish'" >>~/.bashrc
fi

# add HOMECLI_INSTALL_DIR to config-local.fish
echo "set -gx HOMECLI_INSTALL_DIR $INSTALL_DIR" >~/.config/fish/config-local.fish
