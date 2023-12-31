set -e
# MODE: local-install, online-install or unpack. Default: online-install
MODE=${1:-online-install}
INSTALL_DIR=${HOMECLI_INSTALL_DIR:-$HOME/.homecli}

if [ "$MODE" = "local-install" ]; then
	CWD="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
	DIR="$INSTALL_DIR/HOME/general"
	mkdir -p $INSTALL_DIR/HOME
	cp -r $CWD/.. $INSTALL_DIR/HOME
	cd $INSTALL_DIR/HOME

elif [ "$MODE" = "unpack" ]; then
	TARFILE="$2"
	if [ -z "$TARFILE" ]; then
		echo "Usage: install.sh unpack <tarfile>"
		exit 1
	fi
  OLD_INSTALL_DIR=${3:-/root/.homecli}
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
	echo "Usage: install.sh <mode> [tarfile]"
	echo "mode: local-install, online-install, unpack or relink (local-install is default)"
	exit 1
fi

# get current dir
mkdir -p ~/.config

# test if python3 is installed
if ! [ -x "$(command -v python3)" ]; then
	echo 'Error: python3 is not installed.' >&2
	exit 1
fi

# link alacritty dir if .config/alacritty not exist
if [ ! -d ~/.config/alacritty ]; then
	ln -s $DIR/alacritty/ ~/.config/
else
	echo "alacritty config already exist. Please backup or remove it."
	exit 1
fi

# link nvim dir if .config/nvim not exist
if [ ! -d ~/.config/nvim ]; then
  rm $DIR/NvChad/lua/custom || true
	ln -s $DIR/custom/ $DIR/NvChad/lua/custom
	ln -s $DIR/NvChad/ ~/.config/nvim
else
	echo "nvim config already exist. Please backup or remove it."
	exit 1
fi

# link tmux dir if .config/tmux not exist
if [ ! -d ~/.config/tmux ]; then
	ln -s $DIR/tmux/ ~/.config/
else
	echo "tmux config already exist. Please backup or remove it."
	exit 1
fi

# link fish dir if .config/fish not exist
if [ ! -d ~/.config/fish ]; then
	ln -s $DIR/fish/ ~/.config/
else
	echo "fish config already exist. Please backup or remove it."
	exit 1
fi

if [ ! -d ~/.ssh ]; then
	mkdir ~/.ssh
fi
ln -s $DIR/ssh/config ~/.ssh/config
ln -s $DIR/ssh/id_rsa.pub ~/.ssh/id_rsa.pub

# add authorized_keys into .ssh/authorized_keys
if [ ! -f ~/.ssh/authorized_keys ]; then
	touch ~/.ssh/authorized_keys
fi
# if id_rsa.pub not in authorized_keys, add it
if ! grep -q "$(cat ~/.ssh/id_rsa.pub)" ~/.ssh/authorized_keys; then
	cat ~/.ssh/id_rsa.pub >>~/.ssh/authorized_keys
fi

ln -s $DIR/gitconfig ~/.gitconfig
ln -s $DIR/mambarc ~/.mambarc

if [ "$MODE" = "local-install" ] || [ "$MODE" = "online-install" ]; then
	PYTHONPATH="./:$PYTHONPATH" \
		PATH="$INSTALL_DIR/miniconda/bin:$INSTALL_DIR/nodejs/bin:$PATH" \
		python3 homecli/install.py
	curl https://pyenv.run | PYENV_ROOT="$INSTALL_DIR/pyenv" bash
	mv $HOME/.local/share/nvim $INSTALL_DIR/nvim
	ln -s $INSTALL_DIR/nvim $HOME/.local/share/nvim
elif [ "$MODE" = "unpack" ]; then
	mkdir -p ~/.local/share && ln -s $INSTALL_DIR/nvim/ ~/.local/share/nvim
	source $INSTALL_DIR/miniconda/bin/activate
	CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1 conda unpack

	# Re-link broken symlinks
	for file in $(find $HOME/.local/share/nvim/ -type l ! -exec test -e {} \; -print); do
		old=$(readlink $file)
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
		old=$(readlink $file)
    if [[ $old == $OLD_INSTALL_DIR* ]]; then
			new=$(echo $old | sed "s|$OLD_INSTALL_DIR|$INSTALL_DIR|")
			rm $file
			ln -sf $new $file
		fi

  for file in $(find $INSTALL_DIR -name "pyvenv.cfg"); do
    sed -i "s|$OLD_INSTALL_DIR|$INSTALL_DIR|g" $file
  done

  for file in $(find $HOME/.local/share/nvim -name "pyvenv.cfg"); do
    sed -i "s|$OLD_INSTALL_DIR|$INSTALL_DIR|g" $file
    sed -i "s|venv .*/.local/share/nvim|venv $HOME/.local/share/nvim|g" $file
  done

  for file in $(find $HOME/.local/share/nvim/mason/bin -type l); do
    origin_file=$(readlink $file)
    sed -i "s|#!.*/.local/share/nvim/mason/packages|#!$HOME/.local/share/nvim/mason/packages|g" $origin_file
  done
done

elif [ "$MODE" = "relink" ]; then
	ln -s $INSTALL_DIR/nvim/ ~/.local/share/nvim
fi

# add fish path to .bashrc
if ! grep -q 'alias fish.*' ~/.bashrc; then
	echo "alias fish='$INSTALL_DIR/miniconda/bin/fish'" >>~/.bashrc
fi

# add HOMECLI_INSTALL_DIR to config-local.fish
echo "set -gx HOMECLI_INSTALL_DIR $INSTALL_DIR" >~/.config/fish/config-local.fish
