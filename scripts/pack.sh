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
source $INSTALL_DIR/miniconda/bin/activate
rm -f $INSTALL_DIR/miniconda.tar.gz
$INSTALL_DIR/miniconda/bin/conda-pack -o $INSTALL_DIR/miniconda.tar.gz

CURDIR=$(pwd)
echo $CURDIR

cd $INSTALL_DIR
rm -rf $INSTALL_DIR/packed
mkdir $INSTALL_DIR/packed
tar --exclude="__pycache__" -cvf $INSTALL_DIR/packed/homecli.tar.gz \
	HOME bin miniconda.tar.gz pyenv pipx nvim
rm miniconda.tar.gz
cp $INSTALL_DIR/HOME/scripts/install.sh \
	$INSTALL_DIR/HOME/scripts/uninstall.sh \
	$INSTALL_DIR/HOME/scripts/_unpack.sh \
	$INSTALL_DIR/packed
./HOME/scripts/makeself/makeself.sh ./packed $CURDIR/$OUTFILE "HOME Installer" ./_unpack.sh
cd -
