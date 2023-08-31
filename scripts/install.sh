# MODE: local-install, online-install or unpack. Default: online-install
MODE=${1:-online-install}

if [ "$MODE" = "local-install" ]; then
  CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
  DIR="$HOME/.cache/homecli/HOME/general"
  mkdir -p ~/.cache/homecli/HOME
  cp -r $CWD/.. ~/.cache/homecli/HOME
  cd ~/.cache/homecli/HOME

elif [ "$MODE" = "unpack" ]; then
  TARFILE="$2"
  DESTINATION=$HOME/.cache
  if [ -z "$DESTINATION" || -z "$TARFILE" ]; then
    echo "Usage: install.sh unpack <tarfile>"
    exit 1
  fi
  mkdir -p $DESTINATION/homecli
  tar -xvf "$TARFILE" -C "$DESTINATION/homecli"
  mkdir -p $DESTINATION/homecli/miniconda
  tar -xvf $DESTINATION/homecli/miniconda.tar.gz -C $DESTINATION/homecli/miniconda
  DIR="$DESTINATION/homecli/HOME/general"
elif [ "$MODE" = "online-install" ]; then
  DIR="$HOME/.cache/homecli/HOME/general"
  mkdir -p ~/.cache/homecli
  git clone https://github.com/BrightXiaoHan/HOME ~/.cache/homecli/HOME
  cd ~/.cache/homecli/HOME
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
  ln -s $DIR/nvim/ ~/.config/

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
  cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
fi

ln -s $DIR/gitconfig ~/.gitconfig

if [ "$MODE" = "local-install" ] || [ "$MODE" = "online-install" ]; then
  PYTHONPATH="./:$PYTHONPATH" \
    PATH="$HOME/.cache/homecli/miniconda/bin:$HOME/.cache/homecli/nodejs/bin:$PATH" \
    python3 homecli/install.py
  curl https://pyenv.run | bash
elif [ "$MODE" = "unpack" ]; then
  mkdir -p ~/.local/share && ln -s $DESTINATION/homecli/nvim/ ~/.local/share/nvim
  source $DESTINATION/homecli/miniconda/bin/activate
  conda unpack

  # Re-link broken symlinks
  for file in $(find $HOME -type l ! -exec test -e {} \; -print); do
    old=$(readlink $file)
    # Re-link to the new location with $HOME prefix
    # e.g.> /root/.cache/homecli/xxx -> $HOME/.cache/homecli/xxx
    
    # extract str after .cache/homecli
    if [[ $old == *".local/share/nvim"* ]]; then
      prefix=$(echo $old | sed 's/\.local\/share\/nvim.*//')
      # replace prefix with $HOME
      new=$(echo $old | sed "s|^$prefix|$HOME/|")
      rm $file
      ln -s $new $file
    fi
  done
fi

# add fish path to .bashrc
if ! grep -q 'export PATH=$HOME/.cache/homecli/miniconda/bin:$PATH' ~/.bashrc; then
  echo 'export PATH=$HOME/.cache/homecli/miniconda/bin:$PATH' >> ~/.bashrc
fi
