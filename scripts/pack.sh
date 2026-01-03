#!/bin/bash
Usage() {
	echo "Usage: $0 --outfile <outfile> [--install-dir <install-dir>] [--help]"
	echo "args can be one or more of the following :"
	echo "    --outfile | -o  : Output tarfile. Default: homecli.run"
	echo "    --install-dir   : Installation directory. Default: $HOME/.homecli"
	echo "    --help | -h     : Show this help message"
	exit 1
}
set -e

# Download makeself if not already present
download_makeself() {
	local makeself_dir="$1"
	if [ -f "$makeself_dir/makeself.sh" ]; then
		echo "makeself already exists, skipping download"
		return 0
	fi

	echo "Downloading makeself from GitHub..."
	mkdir -p "$makeself_dir"

	# Get the latest release run file URL
	local release_info=$(curl -s https://api.github.com/repos/megastep/makeself/releases/latest)
	local run_url=$(echo "$release_info" | grep "browser_download_url.*\.run" | cut -d '"' -f 4)

	if [ -z "$run_url" ]; then
		echo "Failed to get latest makeself release URL"
		return 1
	fi

	# Download and extract the .run file
	curl -L "$run_url" -o "$makeself_dir/makeself.run"
	chmod +x "$makeself_dir/makeself.run"
	cd "$makeself_dir"
	./makeself.run --target . --noexec
	rm makeself.run
	cd - > /dev/null
	echo "makeself downloaded successfully"
}

while true; do
	case "$1" in
	--outfile | -o)
		OUTFILE=$2
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

# INSTALL_DIR: Installation directory. Default: $HOME/.homecli
if [ -z "$INSTALL_DIR" ]; then
	INSTALL_DIR=${HOMECLI_INSTALL_DIR:-$HOME/.homecli}
fi

if [ -z "$OUTFILE" ]; then
	OUTFILE=${1:-homecli.run}
fi

# shift if $1 is set
if [ -n "$1" ]; then
	shift
fi

rm -f $INSTALL_DIR/miniconda.tar.gz
$INSTALL_DIR/uv/tool/conda-pack/bin/conda-pack -p $INSTALL_DIR/miniconda -o $INSTALL_DIR/miniconda.tar.gz

CURDIR=$(pwd)
echo $CURDIR

cd $INSTALL_DIR
rm -rf $INSTALL_DIR/packed
mkdir $INSTALL_DIR/packed
tar --exclude="__pycache__" --dereference -cvf $INSTALL_DIR/packed/homecli.tar.gz \
	HOME bin miniconda.tar.gz uv nvim
rm miniconda.tar.gz
cp $INSTALL_DIR/HOME/scripts/install.sh \
	$INSTALL_DIR/HOME/scripts/uninstall.sh \
	$INSTALL_DIR/HOME/scripts/_unpack.sh \
	$INSTALL_DIR/packed

# if OUTFILE is a relative path, make it absolute
if [[ ! "$OUTFILE" = /* ]]; then
	OUTFILE=$CURDIR/$OUTFILE
fi

# Download makeself if needed
MAKESELF_DIR="$INSTALL_DIR/HOME/scripts/makeself"
download_makeself "$MAKESELF_DIR"

./HOME/scripts/makeself/makeself.sh ./packed $OUTFILE "HOME Installer" ./_unpack.sh
cd -
