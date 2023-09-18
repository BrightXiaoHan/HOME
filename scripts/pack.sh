OUTFILE=${1:-homecli.tar.gz}
DIR=~/.cache/homecli

source $DIR/miniconda/bin/activate
$DIR/miniconda/bin/conda-pack -o $DIR/miniconda.tar.gz

CURDIR=$(pwd)
echo $CURDIR

OUTFILE=${1:-homecli.tar.gz}
cd $DIR
tar -cvf $CURDIR/$OUTFILE \
    HOME bin miniconda.tar.gz pyenv
rm miniconda.tar.gz
cd -

cd ~/.local/share/
tar -rvf $CURDIR/$OUTFILE nvim/
cd -
