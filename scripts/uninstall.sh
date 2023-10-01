INSTALL_DIR=${HOMECLI_INSTALL_DIR:-$HOME/.homecli}
REMOVE_CACHE=${1:-true}

# remove config files
rm -rf ~/.config/alacritty \
  ~/.config/nvim \
  ~/.config/tmux \
  ~/.config/fish \
  ~/.gitconfig \
  ~/.ssh/config \
  ~/.ssh/id_rsa.pub \
  ~/.mambarc

# remove nvim plugins
rm -rf ~/.local/share/nvim

# remove cache
if [ "$REMOVE_CACHE" = "true" ]; then
  rm -rf $INSTALL_DIR
elif [ "$REMOVE_CACHE" = "false" ]; then
  echo "remove cache skipped"
else
  echo "invalid argument: $REMOVE_CACHE (should be true or false)"
  echo "usage: $0 [true|false]"
  exit 1
fi

# remove export PATH=$INSTALL_DIR/bin:$PATH' from .bashrc
sed -i '/export PATH=.*homecli\/miniconda\/bin:$PATH/d' ~/.bashrc