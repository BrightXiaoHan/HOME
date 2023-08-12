DIR=~/.cache/homecli

source $DIR/miniconda/bin/activate
$DIR/miniconda/bin/conda-pack -o $DIR/miniconda.tar.gz > /dev/null

PWD=$(pwd)
echo $PWD

cd $DIR
tar -cvf $PWD/homecli.tar \
    HOME bin miniconda.tar.gz nodejs > /dev/null
rm miniconda.tar.gz
cd -

cd ~/.local/share/
tar -rvf $PWD/homecli.tar nvim/ > /dev/null
cd -
