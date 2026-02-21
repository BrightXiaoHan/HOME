#!/bin/bash
echo "Install Softwares for macOS"
export NONINTERACTIVE=1
export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
DIR="$DIR/../general"

# ============================================
# Setup pass password store
# ============================================
setup_password_store() {
	echo ""
	echo "========================================"
	echo "Setting up pass password store..."
	echo "========================================"

	# Check if GPG key exists, if not prompt user to import
	GPG_KEY_ID="5F8F12601E991C982850BFC53965492C32AB9685"
	if ! gpg --list-keys "$GPG_KEY_ID" >/dev/null 2>&1; then
		echo "GPG key not found. Checking iCloud backup..."

		ICLOUD_BACKUP="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Backups/GPG/gpg-private-key.asc"

		if [ -f "$ICLOUD_BACKUP" ]; then
			echo "Found GPG backup in iCloud. Importing..."
			gpg --import "$ICLOUD_BACKUP"

			# Set ultimate trust
			echo -e "5\ny\n" | gpg --command-fd 0 --edit-key "$GPG_KEY_ID" trust >/dev/null 2>&1
			echo "GPG key imported and trusted."
		else
			echo "⚠️  GPG private key not found in iCloud backup."
			echo "Please manually import your GPG key:"
			echo "   gpg --import /path/to/your/gpg-private-key.asc"
			echo "Then set trust level:"
			echo "   gpg --edit-key $GPG_KEY_ID"
			echo "   (select 'trust' -> '5' -> 'save')"
		fi
	else
		echo "GPG key already exists."
	fi

	# Clone password store if not exists
	if [ ! -d "$HOME/.password-store" ]; then
		echo "Cloning password store from GitHub..."
		git clone https://github.com/BrightXiaoHan/password-store.git "$HOME/.password-store"

		# Initialize pass with the GPG key
		if gpg --list-keys "$GPG_KEY_ID" >/dev/null 2>&1; then
			pass init "$GPG_KEY_ID"
			echo "✅ Password store initialized successfully!"
		else
			echo "⚠️  Password store cloned but GPG key not available."
			echo "   Run 'pass init $GPG_KEY_ID' after importing your GPG key."
		fi
	else
		echo "Password store already exists at ~/.password-store"
	fi

	echo ""
	echo "========================================"
	echo "Pass setup complete!"
	echo "========================================"
	echo "Usage:"
	echo "   pass                    # List all passwords"
	echo "   pass <name>             # Show password"
	echo "   pass -c <name>          # Copy to clipboard"
	echo "   pass insert <name>      # Add new password"
	echo ""
}

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install mas git make llvm gnupg pass

# Install xcode command line tools
# git make clang will be installed by xcode-select --install
# mas install 497799835
# xcode-select --install

git clone https://github.com/BrightXiaoHan/nvchad-starter.git $DIR/nvim
setup_password_store

# get current dir
mkdir -p ~/.config

# test if python3 is installed
if ! [ -x "$(command -v python3)" ]; then
	echo 'Error: python3 is not installed.' >&2
	exit 1
fi

# link nvim dir if .config/nvim not exist
if [ ! -d ~/.config/nvim ]; then
	ln -sf $DIR/nvim/ ~/.config/nvim
else
	echo "nvim config already exist. Skip it."
fi

# link tmux dir if .config/tmux not exist
if [ ! -d ~/.config/tmux ]; then
	ln -sf $DIR/tmux/ ~/.config/
else
	echo "tmux config already exist. Skip it."
fi

# link fish dir if .config/fish not exist
if [ ! -d ~/.config/fish ]; then
	ln -sf $DIR/fish/ ~/.config/
else
	echo "fish config already exist. Skip it."
fi

if [ ! -d ~/.ssh ]; then
	mkdir ~/.ssh
fi
ln -sf $DIR/ssh/* ~/.ssh/
ln -sf $DIR/ssh/config.d ~/.ssh/

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
	git-lfs tmux fish neovim ripgrep fzf node trzsz-ssh \
	starship zoxide openssh \
	openssl readline sqlite3 xz zlib gh gnu-sed uv \
	opencode

brew install --quiet --cask \
	iterm2 wechat wpsoffice-cn \
	google-chrome \
	appcleaner downie visual-studio-code \
	tencent-meeting telegram  \
	wetype claude-code codex 1password-cli

# install python tools
uv tool install modelscope 
uv tool install huggingface_hub
uv tool install kimi-cli