DIR=~/.cache/homecli

conda-pack -o $DIR/miniconda.tar.gz

tar -zcvf $DIR/homecli.tar.gz ~/.cache/homecli ~/.cache/nvim --exclude=$DIR/miniconda
