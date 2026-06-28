#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." >/dev/null 2>&1 && pwd)"
FORCE=false

usage() {
	cat <<'EOF'
Usage: relink.sh [--repo-dir <path>] [--force]

Recreate macOS host-level symlinks to the HOME configs directory.
Existing regular files/directories are skipped unless --force is used.
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
	--repo-dir)
		REPO_DIR=$2
		shift 2
		;;
	--force)
		FORCE=true
		shift
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		echo "Unknown option: $1" >&2
		usage >&2
		exit 1
		;;
	esac
done

CONFIG_DIR="$REPO_DIR/configs"
if [ ! -d "$CONFIG_DIR" ]; then
	echo "configs directory not found: $CONFIG_DIR" >&2
	exit 1
fi

link_path() {
	local source=$1 target=$2
	mkdir -p "$(dirname "$target")"

	if [ -L "$target" ]; then
		rm -f "$target"
	elif [ -e "$target" ]; then
		if [ "$FORCE" = true ]; then
			rm -rf "$target"
		else
			echo "skip existing non-symlink: $target" >&2
			return 0
		fi
	fi

	ln -s "$source" "$target"
	echo "$target -> $source"
}

link_path "$CONFIG_DIR/fish" "$HOME/.config/fish"
link_path "$CONFIG_DIR/nvim" "$HOME/.config/nvim"
link_path "$CONFIG_DIR/tmux" "$HOME/.config/tmux"
link_path "$CONFIG_DIR/zsh" "$HOME/.config/zsh"
link_path "$CONFIG_DIR/zsh/.zshenv" "$HOME/.zshenv"
link_path "$CONFIG_DIR/gitconfig" "$HOME/.gitconfig"
link_path "$CONFIG_DIR/mambarc" "$HOME/.mambarc"
link_path "$CONFIG_DIR/ssh/config" "$HOME/.ssh/config"
link_path "$CONFIG_DIR/ssh/config.d" "$HOME/.ssh/config.d"
link_path "$CONFIG_DIR/ssh/id_rsa.pub" "$HOME/.ssh/id_rsa.pub"

if [ -f "$CONFIG_DIR/ssh/id_rsa.pub" ]; then
	mkdir -p "$HOME/.ssh"
	touch "$HOME/.ssh/authorized_keys"
	if ! grep -qxF "$(cat "$CONFIG_DIR/ssh/id_rsa.pub")" "$HOME/.ssh/authorized_keys"; then
		cat "$CONFIG_DIR/ssh/id_rsa.pub" >>"$HOME/.ssh/authorized_keys"
	fi
fi
