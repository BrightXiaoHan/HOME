OUTFILE=${1:-homecli.tar.gz}
DIR=~/.cache/homecli

# source $DIR/miniconda/bin/activate
$DIR/miniconda/bin/conda-pack -o $DIR/miniconda.tar.gz > /dev/null

CURDIR=$(pwd)
echo $CURDIR

OUTFILE=${1:-homecli.tar.gz}
cd $DIR
tar -cvf $CURDIR/$OUTFILE \
    HOME bin miniconda.tar.gz > /dev/null
rm miniconda.tar.gz
cd -

cd ~/.local/share/
tar -rvf $CURDIR/$OUTFILE nvim/ > /dev/null
cd -
