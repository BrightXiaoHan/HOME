Usage() {
	echo "Usage: $0 --mode <install|uninstall> [--remove-cache <true|false>] [--install-dir <install-dir>] [--help]"
	echo "args can be one or more of the following :"
    echo "    --mode | -m          : Mode of operation. Default: install"
    echo "    --remove-cache | -r  : Remove cache. Default: true"
    echo "    --install-dir        : Installation directory. Default: $HOME/.homecli"
    echo "    --help | -h          : Show this help message"
    exit 1
}

while true; do
    case "$1" in
    --mode | -m)
        MODE=$2
        if [ "$MODE" != "install" ] && [ "$MODE" != "uninstall" ]; then
            echo "invalid argument: $MODE (should be install or uninstall)"
            Usage
        fi
        shift 2
        ;;
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

MODE=${MODE:-install}
INSTALL_DIR=${INSTALL_DIR:-$HOME/.homecli}
REMOVE_CACHE=${REMOVE_CACHE:-true}


if [ "$MODE" = "install" ]; then
    ./install.sh --mode unpack --install-dir $INSTALL_DIR --tarfile homecli.tar.gz --old-install-dir /home/runner/.homecli
elif [ "$MODE" = "uninstall" ]; then
    ./uninstall.sh --remove-cache $REMOVE_CACHE --install-dir $INSTALL_DIR
fi