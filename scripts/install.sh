# Get MODE default is online-install
MODE=${1:-online-install}

if [ "$MODE" = "local-install" ]; then
  DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
  DIR="$DIR/../general"
elif [ "$MODE" = "unpack" ]; then
  TARFILE="$2"
  if [ -z "$TARFILE" ]; then
    echo "Usage: install.sh unpack <tarfile>"
    exit 1
  fi
  mkdir -p ~/.cache/homecli
  tar -xvf "$TARFILE" -C ~/.cache/homecli
  DIR="$HOME/.cache/homecli/HOME/general"
elif [ "$MODE" = "online-install" ]; then
  mkdir -p ~/.cache/homecli
  git clone https://github.com/BrightXiaoHan/HOME ~/.cache/homecli/HOME
  DIR="$HOME/.cache/homecli/HOME/general"
fi

# get current dir
mkdir -p ~/.config

# test if python3 is installed
if ! [ -x "$(command -v python3)" ]; then
  echo 'Error: python3 is not installed.' >&2
  exit 1
fi

# test if pip3 is installed
if ! [ -x "$(command -v pip3)" ]; then
  echo 'Error: pip3 is not installed.' >&2
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
ln -s $DIR/gitconfig ~/.gitconfig

if [ "MODE" = "local-install" ]; then
  PYTHONPATH="./:$PYTHONPATH" \
  PATH="$HOME/.cache/homecli/miniconda/bin:$HOME/.cache/homecli/nodejs/bin:$PATH" \
    python3 homecli/install.py
fi
