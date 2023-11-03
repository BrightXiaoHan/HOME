set -e

DIR=${HOMECLI_INSTALL_DIR:-$HOME/.homecli}
OUTFILE=${1:-homecli.tar.gz}

# shift if $1 is set
if [ -n "$1" ]; then
	shift
fi
source $DIR/miniconda/bin/activate
$DIR/miniconda/bin/conda-pack -o $DIR/miniconda.tar.gz

CURDIR=$(pwd)
echo $CURDIR

cd $DIR
tar -cvf $CURDIR/$OUTFILE \
	HOME bin miniconda.tar.gz pyenv pipx nvim
rm miniconda.tar.gz
cd -
