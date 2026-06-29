#!/bin/bash
Usage() {
	echo "Usage: $0 [--remove-cache <true|false>] [--install-dir <install-dir>] [--help]"
	echo "args can be one or more of the following :"
	echo "    --remove-cache | -r  : Remove cache. Default: true"
	echo "    --install-dir        : Installation directory. Default: $HOME/.homecli"
	echo "    --help | -h          : Show this help message"
	exit 1
}

while true; do
	case "$1" in
	--remove-cache | -r)
		REMOVE_CACHE=$2
		shift 2
		;;
	--install-dir)
		INSTALL_DIR=$2
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

INSTALL_DIR=${INSTALL_DIR:-${HOMECLI_INSTALL_DIR:-$HOME/.homecli}}
REMOVE_CACHE=${REMOVE_CACHE:-true}

abs_path() {
	local path=$1
	local part
	local -a parts stack

	if [ "${path#/}" = "$path" ]; then
		path="$PWD/$path"
	fi

	IFS=/ read -r -a parts <<<"$path"
	for part in "${parts[@]}"; do
		case "$part" in
		"" | ".")
			;;
		"..")
			if [ "${#stack[@]}" -gt 0 ]; then
				unset 'stack[${#stack[@]}-1]'
			fi
			;;
		*)
			stack+=("$part")
			;;
		esac
	done

	if [ "${#stack[@]}" -eq 0 ]; then
		printf '/\n'
	else
		printf '/%s' "${stack[@]}"
		printf '\n'
	fi
}

ABS_INSTALL_DIR=$(abs_path "$INSTALL_DIR")
DEFAULT_INSTALL_DIR=$(abs_path "${HOMECLI_INSTALL_DIR:-$HOME/.homecli}")

# remove cache
if [ "$REMOVE_CACHE" = "true" ]; then
	rm -rf "$INSTALL_DIR"
elif [ "$REMOVE_CACHE" = "false" ]; then
	echo "remove cache skipped"
else
	echo "invalid argument: $REMOVE_CACHE (should be true or false)"
	echo "usage: $0 [true|false]"
	exit 1
fi

# clean up legacy symlinks from earlier installs to avoid broken configs
remove_legacy_symlink() {
	local path=$1
	if [ ! -L "$path" ]; then
		return
	fi

	local target
	target=$(readlink "$path" || true)
	if [ -z "$target" ]; then
		return
	fi

	if [ "${target#/}" = "$target" ]; then
		target=$(abs_path "$(dirname "$path")/$target")
	fi

	case "$target" in
		"$ABS_INSTALL_DIR"/* | "$DEFAULT_INSTALL_DIR"/*)
			rm -f "$path"
			;;
	esac
}

LEGACY_PATHS=(
	"$HOME/.config/nvim"
	"$HOME/.config/tmux"
	"$HOME/.config/fish"
	"$HOME/.config/zsh"
	"$HOME/.zshenv"
	"$HOME/.gitconfig"
	"$HOME/.mambarc"
	"$HOME/.agents"
	"$HOME/.local/share/nvim"
)

for legacy_path in "${LEGACY_PATHS[@]}"; do
	remove_legacy_symlink "$legacy_path"
done

# remove alias created by installer
sed -i '/homecli-fish/d' ~/.bashrc 2>/dev/null || true
sed -i '/homecli-bash/d' ~/.bashrc 2>/dev/null || true
sed -i '/homecli-zsh/d' ~/.bashrc 2>/dev/null || true
