# remove config files
rm -rf ~/.config/alacritty \
  ~/.config/nvim \
  ~/.config/tmux \
  ~/.config/fish \
  ~/.gitconfig \
  ~/.ssh/config \
  ~/.ssh/id_rsa.pub

# remove nvim plugins
rm -rf ~/.local/share/nvim

# remove cache
rm -rf ~/.cache/homecli

# remove export PATH=$HOME/.cache/homecli/miniconda/bin:$PATH' from .bashrc
sed -i '/export PATH=$HOME\/.cache\/homecli\/miniconda\/bin:$PATH/d' ~/.bashrc
