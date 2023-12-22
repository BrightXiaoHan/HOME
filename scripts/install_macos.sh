set -e
echo "Install Softwares for macOS"
export NONINTERACTIVE=1
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install mas git make llvm

# Install xcode command line tools
# git make clang will be installed by xcode-select --install
# mas install 497799835
# xcode-select --install

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
DIR="$DIR/../general"

# get current dir
mkdir -p ~/.config

# test if python3 is installed
if ! [ -x "$(command -v python3)" ]; then
	echo 'Error: python3 is not installed.' >&2
	exit 1
fi

# link alacritty dir if .config/alacritty not exist
if [ ! -d ~/.config/alacritty ]; then
	ln -sf $DIR/alacritty/ ~/.config/
else
	echo "alacritty config already exist. Please backup or remove it."
	exit 1
fi

# link nvim dir if .config/nvim not exist
if [ ! -d ~/.config/nvim ]; then
	ln -sf $DIR/custom/ $DIR/NvChad/lua/custom
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

brew install --quiet \
	git-lfs tmux fish neovim ripgrep fzf pyenv node aliyunpan trzsz-ssh \
	cmake poetry pipx starship zoxide openssh rich-cli \
	openssl readline sqlite3 xz zlib # pyenv

# install font
brew tap homebrew/cask-fonts
brew install --quiet --cask font-jetbrains-mono

brew install --quiet --cask \
	iterm2 wechat wpsoffice-cn \
	dingtalk todesk microsoft-edge adrive \
	appcleaner downie typora visual-studio-code \
	parallels tencent-meeting telegram microsoft-remote-desktop \
	obs bing-wallpaper qqmusic keycastr
# missing sogouinput, clashx
