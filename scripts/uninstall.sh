MODE=${1:-config}

rm -rf ~/.config/alacritty \
  ~/.config/nvim \
  ~/.config/tmux \
  ~/.config/fish \
  ~/.gitconfig \
  ~/.ssh/config

if [ "$MODE" = "all" ]; then
  rm -rf ~/.cache/homecli
fi
