MODE=${1:-config}

# remove config files
rm -rf ~/.config/alacritty \
  ~/.config/nvim \
  ~/.config/tmux \
  ~/.config/fish \
  ~/.gitconfig \
  ~/.ssh/config

# remove packer
rm -rf ~/.local/share/nvim/site/pack/packer

# remove cache
rm -rf ~/.cache/homecli
