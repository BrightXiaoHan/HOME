DIR=${HOMECLI_INSTALL_DIR:-$HOME/.homecli}
OUTFILE=${1:-homecli.tar.gz}

source $DIR/miniconda/bin/activate
$DIR/miniconda/bin/conda-pack -o $DIR/miniconda.tar.gz

CURDIR=$(pwd)
echo $CURDIR

OUTFILE=${1:-homecli.tar.gz}
cd $DIR
tar -cvf $CURDIR/$OUTFILE \
	HOME bin miniconda.tar.gz pyenv pipx nvim
rm miniconda.tar.gz
cd -
