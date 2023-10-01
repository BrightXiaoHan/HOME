INSTALL_DIR=${HOMECLI_INSTALL_DIR:-$HOME/.homecli}

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
rm -rf $INSTALL_DIR

# remove export PATH=$INSTALL_DIR/bin:$PATH' from .bashrc
sed -i '/export PATH=.*homecli\/miniconda\/bin:$PATH/d' ~/.bashrc