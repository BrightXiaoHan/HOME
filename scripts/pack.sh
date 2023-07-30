DIR=~/.cache/homecli

conda-pack -o $DIR/miniconda.tar.gz

cd $DIR
tar -cvf $DIR/homecli.tar \
    HOME bin miniconda.tar.gz nodejs
cd -

cd ~/.local/share/
tar -rvf $DIR/homecli.tar nvim/
cd -
