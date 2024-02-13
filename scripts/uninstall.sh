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

INSTALL_DIR=${INSTALL_DIR:-$HOME/.homecli}
REMOVE_CACHE=${REMOVE_CACHE:-true}

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

# remove alias fish=xxx
sed -i '/alias fish=/d' ~/.bashrc
