OUTPUT={$1:-homecli.tar.gz}
DIR=~/.cache/homecli

source $DIR/miniconda/bin/activate
$DIR/miniconda/bin/conda-pack -o $DIR/miniconda.tar.gz > /dev/null

CURDIR=$(pwd)
echo $CURDIR

cd $DIR
tar -cvf $CURDIR/$OUTPUT \
    HOME bin miniconda.tar.gz nodejs > /dev/null
rm miniconda.tar.gz
cd -

cd ~/.local/share/
tar -rvf $CURDIR/$OUTPUT nvim/ > /dev/null
cd -
