#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
LINKS_HELPER=""
for candidate in "$SCRIPT_DIR/../common/links.sh" "$SCRIPT_DIR/common/links.sh" "$SCRIPT_DIR/lib/links.sh"; do
	if [ -r "$candidate" ]; then
		LINKS_HELPER="$candidate"
		break
	fi
done

if [ -n "$LINKS_HELPER" ]; then
	. "$LINKS_HELPER"
else
	# Fallback for curl | bash installs where only install.sh is available.
	homecli_link_configs() {
		local source_dir=$1 install_dir=$2 config_home=$3 home_dir=${4:-$HOME}
		mkdir -p "$config_home" "$config_home/git" "$install_dir/etc"
		ln -sfn "$source_dir/nvim" "$config_home/nvim"
		ln -sfn "$source_dir/tmux" "$config_home/tmux"
		ln -sfn "$source_dir/fish" "$config_home/fish"
		if [ -f "$source_dir/starship.toml" ]; then
			ln -sfn "$source_dir/starship.toml" "$config_home/starship.toml"
		fi
		# Remove stale zsh links from older HOME releases. zsh config is no longer managed.
		[ -L "$config_home/zsh" ] && rm -f "$config_home/zsh"
		[ -L "$home_dir/.zshenv" ] && rm -f "$home_dir/.zshenv"
		ln -sfn "$source_dir/gitconfig" "$config_home/git/config"
		ln -sfn "$source_dir/ssh" "$install_dir/etc/ssh"
		ln -sfn "$source_dir/mambarc" "$install_dir/etc/mambarc"
		if [ -d "$source_dir/agents" ]; then
			if [ ! -e "$home_dir/.agents" ] || [ -L "$home_dir/.agents" ]; then
				ln -sfn "$source_dir/agents" "$home_dir/.agents"
			else
				echo ".agents already exists. Skip it."
			fi
		fi
	}

	homecli_add_authorized_key() {
		local pubkey_file=$1 ssh_dir=${2:-$HOME/.ssh} authorized_keys
		authorized_keys="$ssh_dir/authorized_keys"
		[ -f "$pubkey_file" ] || return 0
		mkdir -p "$ssh_dir"
		[ -f "$authorized_keys" ] || touch "$authorized_keys"
		if ! grep -qxF "$(cat "$pubkey_file")" "$authorized_keys"; then
			cat "$pubkey_file" >>"$authorized_keys"
		fi
	}
fi

Usage() {
	echo "Usage: $0 --mode <mode> --install-dir <install-dir> [--tarfile <tarfile>] [--old-install-dir <old-install-dir>] [--help]"
	echo "args can be one or more of the following :"
	echo "    --mode | -m     : Installation mode. local-install, online-install, unpack or relink (local-install is default)"
	echo "    --tarfile | -t  : Tarfile to unpack. Only used when mode is unpack"
	echo "    --install-dir   : Installation directory. Default: $HOME/.homecli"
	echo "	  --old-install-dir: Old installation directory. Only used when mode is unpack. Default: /home/runner/.homecli"
	echo "	  --old-home-dir   : Old home directory. Only used when mode is unpack. Default: /home/runner"
	echo "    --help | -h     : Show this help message"
	exit 1
}

while true; do
	case "$1" in
	--mode | -m)
		MODE=$2
		shift 2
		;;
	--tarfile | -t)
		TARFILE=$2
		shift 2
		;;
	--install-dir)
		INSTALL_DIR=$2
		shift 2
		;;
	--old-install-dir)
		OLD_INSTALL_DIR=$2
		shift 2
		;;
	--old-home-dir)
		OLD_HOME_DIR=$2
		shift 2
		;;
	--help | -h)
		Usage
		;;
	-*)
		echo "Unknown option: $1"
		Usage
		;;
	*)
		break
		;;
	esac
done
# MODE: local-install, online-install or unpack. Default: online-install
if [ -z "$MODE" ]; then
  MODE=online-install
fi

# INSTALL_DIR: Installation directory. Default: $HOME/.homecli
if [ -z "$INSTALL_DIR" ]; then
  INSTALL_DIR=${HOMECLI_INSTALL_DIR:-$HOME/.homecli}
fi

# XDG-style roots inside install dir so configs remain self-contained
CONFIG_HOME=${HOMECLI_XDG_CONFIG_HOME:-$INSTALL_DIR/config}
DATA_HOME=${HOMECLI_XDG_DATA_HOME:-$INSTALL_DIR/data}
STATE_HOME=${HOMECLI_XDG_STATE_HOME:-$INSTALL_DIR/state}
CACHE_HOME=${HOMECLI_XDG_CACHE_HOME:-$INSTALL_DIR/cache}
NVIM_DATA_DIR=$DATA_HOME/nvim

mkdir -p "$CONFIG_HOME" "$DATA_HOME" "$STATE_HOME" "$CACHE_HOME"
mkdir -p "$INSTALL_DIR/bin"

ensure_nvim_link() {
	# If a legacy nvim directory exists at the install root, migrate it to XDG data.
	if [ -d "$INSTALL_DIR/nvim" ] && [ ! -L "$INSTALL_DIR/nvim" ]; then
		if [ ! -d "$NVIM_DATA_DIR" ] || [ -z "$(ls -A "$NVIM_DATA_DIR" 2>/dev/null)" ]; then
			rm -rf "$NVIM_DATA_DIR"
			mv "$INSTALL_DIR/nvim" "$NVIM_DATA_DIR"
		else
			rm -rf "$INSTALL_DIR/nvim"
		fi
	fi

	mkdir -p "$NVIM_DATA_DIR/site/pack/core/opt" "$NVIM_DATA_DIR/mason/bin"
	ln -sfn "$NVIM_DATA_DIR" "$INSTALL_DIR/nvim"
}

if [ "$MODE" = "local-install" ]; then
	REPO_ROOT="$(cd "$SCRIPT_DIR/../.." >/dev/null 2>&1 && pwd)"
	DIR="$INSTALL_DIR/HOME/configs"
	mkdir -p "$INSTALL_DIR/HOME"
	cp -r "$REPO_ROOT/." "$INSTALL_DIR/HOME"
	cd "$INSTALL_DIR/HOME"

elif [ "$MODE" = "unpack" ]; then
	if [ -z "$TARFILE" ]; then
		echo "Error: tarfile is required for unpack mode."
    Usage
	fi

	if [ ! -f "$TARFILE" ]; then
		echo "Error: tarfile not found: $TARFILE"
		Usage
	fi
	# Github action runner default home dir is /home/runner
	OLD_INSTALL_DIR=${OLD_INSTALL_DIR:-/home/runner/.homecli}
	OLD_HOME_DIR=${OLD_HOME_DIR:-/home/runner}
	mkdir -p $INSTALL_DIR
	tar --no-same-owner -xvf "$TARFILE" -C "$INSTALL_DIR"
	mkdir -p $INSTALL_DIR/miniconda
	tar --no-same-owner -xvf $INSTALL_DIR/miniconda.tar.gz -C $INSTALL_DIR/miniconda
	DIR="$INSTALL_DIR/HOME/configs"
elif [ "$MODE" = "online-install" ]; then
	DIR="$INSTALL_DIR/HOME/configs"
	mkdir -p $INSTALL_DIR
	git clone --recurse-submodules https://github.com/BrightXiaoHan/HOME $INSTALL_DIR/HOME
	cd $INSTALL_DIR/HOME
elif [ "$MODE" = "relink" ]; then
	DIR="$INSTALL_DIR/HOME/configs"
else
  echo "Error: Unknown mode: $MODE"
  Usage
fi

# if configs/nvim not exist, clone it
if [ ! -d $DIR/nvim ]; then
  git clone https://github.com/BrightXiaoHan/nvchad-starter.git $DIR/nvim
fi

# Setup password store
gpg --list-keys 81066AFD8D55B3D7FB5E558ED205F1C5AB2DC9D1 > /dev/null 2>&1
GPG_KEY_EXISTS=$?

if [ "$GPG_KEY_EXISTS" -eq 0 ] && [ ! -d "$INSTALL_DIR/password-store" ]; then
  echo "Setting up password store..."
  git clone https://github.com/BrightXiaoHan/password-store.git "$INSTALL_DIR/password-store"
  pass init 81066AFD8D55B3D7FB5E558ED205F1C5AB2DC9D1 > /dev/null 2>&1
  echo "Password store initialized."
fi

rm -f "$DIR/nvim/lua/custom" || true

homecli_link_configs "$DIR" "$INSTALL_DIR" "$CONFIG_HOME" "$HOME"
homecli_add_authorized_key "$DIR/ssh/id_rsa.pub" "$HOME/.ssh"

if [ "$MODE" = "local-install" ] || [ "$MODE" = "online-install" ]; then
	PATH="$INSTALL_DIR/miniconda/bin:$INSTALL_DIR/nodejs/bin:$PATH" \
		HOMECLI_INSTALL_DIR=$INSTALL_DIR \
		XDG_CONFIG_HOME=$CONFIG_HOME \
		XDG_DATA_HOME=$DATA_HOME \
		XDG_STATE_HOME=$STATE_HOME \
		XDG_CACHE_HOME=$CACHE_HOME \
		bash scripts/linux/components.sh all || exit 1
	ensure_nvim_link
elif [ "$MODE" = "unpack" ]; then
	mkdir -p "$DATA_HOME"
	# Move packaged nvim data into XDG data dir and link back
	if [ -d "$INSTALL_DIR/nvim" ] && [ ! -L "$INSTALL_DIR/nvim" ]; then
		rm -rf "$DATA_HOME/nvim"
		mv "$INSTALL_DIR/nvim" "$DATA_HOME/nvim"
	fi
	ensure_nvim_link
	. $INSTALL_DIR/miniconda/bin/activate
  # find python in uv
  PYTHON_BIN_FOLDER=$(dirname $(find $INSTALL_DIR/uv/python -name python ! -type d | awk 'NR==1'))
	CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1 PATH=$PYTHON_BIN_FOLDER:$PATH conda-unpack

	# Re-link broken symlinks
	for file in $(find "$NVIM_DATA_DIR" -type l ! -exec test -e {} \; -print); do
		old=$(readlink -m $file)
		if [[ -n "$OLD_HOME_DIR" && $old == $OLD_HOME_DIR* ]]; then
			new=${old/#$OLD_HOME_DIR/$HOME}
			rm $file
			ln -sf $new $file
		fi
	done

	for file in $(find $INSTALL_DIR -type l ! -exec test -e {} \; -print); do
		old=$(readlink -m $file)
		if [[ $old == $OLD_INSTALL_DIR* ]]; then
			new=$(echo $old | sed "s|$OLD_INSTALL_DIR|$INSTALL_DIR|")
			rm $file
			ln -sf $new $file
		fi
	done

	for file in $(find $INSTALL_DIR -name "pyvenv.cfg"); do
		sed -i "s|$OLD_INSTALL_DIR|$INSTALL_DIR|g" $file
	done

	for file in $(find "$NVIM_DATA_DIR" -name "pyvenv.cfg"); do
		sed -i "s|$OLD_INSTALL_DIR|$INSTALL_DIR|g" $file
		sed -i "s|venv .*/nvim|venv $NVIM_DATA_DIR|g" $file
	done

	# Fix absolute paths embedded in UV tool scripts (e.g., conda-pack shebangs)
	for file in $(find "$INSTALL_DIR/bin" "$INSTALL_DIR/uv/tool" -type f 2>/dev/null); do
		if grep -q "$OLD_INSTALL_DIR" "$file" 2>/dev/null; then
			sed -i "s|$OLD_INSTALL_DIR|$INSTALL_DIR|g" "$file"
		fi
	done

	for file in $(find "$NVIM_DATA_DIR/mason/bin" -type l 2>/dev/null); do
		origin_file=$(readlink -m $file)
		sed -i "s|$OLD_HOME_DIR|$HOME|g" $origin_file
	done

	for file in $(find $INSTALL_DIR/bin -type l); do
		origin_file=$(readlink -m $file)
		sed -i "s|$OLD_INSTALL_DIR|$INSTALL_DIR|g" $origin_file
	done
elif [ "$MODE" = "relink" ]; then
	ensure_nvim_link
fi

# create sourceable environment for isolated HOMECLI shell wrappers
cat >"$INSTALL_DIR/bin/homecli-env" <<EOF
#!/usr/bin/env bash
export HOME="$HOME"
export HOMECLI_INSTALL_DIR="$INSTALL_DIR"
export XDG_CONFIG_HOME="$CONFIG_HOME"
export XDG_DATA_HOME="$DATA_HOME"
export XDG_STATE_HOME="$STATE_HOME"
export XDG_CACHE_HOME="$CACHE_HOME"
export TERM="\${HOMECLI_TERM:-xterm-256color}"
export LANG="\${LANG:-en_US.UTF-8}"
export TERMINFO_DIRS="$INSTALL_DIR/miniconda/share/terminfo:$INSTALL_DIR/miniconda/lib/terminfo:/usr/share/terminfo"
export MAMBA_ROOT_PREFIX="$INSTALL_DIR/miniconda"
export MAMBA_EXE="$INSTALL_DIR/bin/mamba"
export UV_TOOL_DIR="$INSTALL_DIR/uv/tool"
export UV_TOOL_BIN_DIR="$INSTALL_DIR/uv/tool/bin"
export UV_PYTHON_INSTALL_DIR="$INSTALL_DIR/uv/python"
export UV_PYTHON_PREFERENCE="only-system"
export GIT_CONFIG_GLOBAL="$CONFIG_HOME/git/config"
export CONDARC="$INSTALL_DIR/etc/mambarc"
export HOMECLI_SSH_DIR="$INSTALL_DIR/etc/ssh"
export PASSWORD_STORE_DIR="$INSTALL_DIR/password-store"
export PNPM_HOME="$INSTALL_DIR/pnpm"
if [ -f "$CONFIG_HOME/starship.toml" ]; then
	export STARSHIP_CONFIG="\${STARSHIP_CONFIG:-$CONFIG_HOME/starship.toml}"
fi
if [ -f "$INSTALL_DIR/etc/ssh/config" ]; then
	export GIT_SSH_COMMAND="\${GIT_SSH_COMMAND:-ssh -F $INSTALL_DIR/etc/ssh/config -i $INSTALL_DIR/etc/ssh/id_rsa_git}"
fi
export CC="$INSTALL_DIR/miniconda/bin/gcc"
export CXX="$INSTALL_DIR/miniconda/bin/g++"
export CPPFLAGS="-I$INSTALL_DIR/miniconda/include \${CPPFLAGS:-}"
export LDFLAGS="-L$INSTALL_DIR/miniconda/lib \${LDFLAGS:-}"
export CONFIGURE_OPTS="-with-openssl=$INSTALL_DIR/miniconda \${CONFIGURE_OPTS:-}"
export CRYPTOGRAPHY_OPENSSL_NO_LEGACY="\${CRYPTOGRAPHY_OPENSSL_NO_LEGACY:-1}"
export POETRY_VIRTUALENVS_IN_PROJECT="\${POETRY_VIRTUALENVS_IN_PROJECT:-true}"
__homecli_system_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export PATH="node_modules/.bin:$INSTALL_DIR/bin:$INSTALL_DIR/miniconda/bin:$INSTALL_DIR/uv/tool/bin:$INSTALL_DIR/pnpm:\$HOME/.local/bin:\${PATH:-}:\$__homecli_system_path"
unset __homecli_system_path
EOF
chmod +x "$INSTALL_DIR/bin/homecli-env"

# create wrapper to enter isolated fish session with XDG dirs
cat >"$INSTALL_DIR/bin/homecli-fish" <<EOF
#!/usr/bin/env bash
. "$INSTALL_DIR/bin/homecli-env"
exec "$INSTALL_DIR/miniconda/bin/fish" "\$@"
EOF
chmod +x "$INSTALL_DIR/bin/homecli-fish"

# create wrapper to enter isolated bash session for agents/scripts
cat >"$INSTALL_DIR/bin/homecli-bash" <<EOF
#!/usr/bin/env bash
. "$INSTALL_DIR/bin/homecli-env"
exec bash --noprofile --norc "\$@"
EOF
chmod +x "$INSTALL_DIR/bin/homecli-bash"
chown "$(id -u):$(id -g)" \
	"$INSTALL_DIR/bin/homecli-env" \
	"$INSTALL_DIR/bin/homecli-fish" \
	"$INSTALL_DIR/bin/homecli-bash" 2>/dev/null || true
rm -f "$INSTALL_DIR/bin/homecli-zsh"

if [ -x "$INSTALL_DIR/HOME/scripts/linux/homecli" ]; then
	ln -sfn "$INSTALL_DIR/HOME/scripts/linux/homecli" "$INSTALL_DIR/bin/homecli"
fi

# add shell wrapper aliases to .bashrc with a stable Linux TERM/locale inside env -i
sed -i '/alias fish=.*homecli-fish/d' ~/.bashrc 2>/dev/null || true
sed -i '/alias zsh=.*homecli-zsh/d' ~/.bashrc 2>/dev/null || true
sed -i '/alias homecli-bash=.*homecli-bash/d' ~/.bashrc 2>/dev/null || true
echo "alias fish='env -i HOMECLI_TERM=\"\${HOMECLI_TERM:-xterm-256color}\" LANG=\"\${LANG:-en_US.UTF-8}\" $INSTALL_DIR/bin/homecli-fish'" >>~/.bashrc
echo "alias homecli-bash='env -i HOMECLI_TERM=\"\${HOMECLI_TERM:-xterm-256color}\" LANG=\"\${LANG:-en_US.UTF-8}\" $INSTALL_DIR/bin/homecli-bash'" >>~/.bashrc
