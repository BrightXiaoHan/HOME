DIR="~/.cache/homecli"

conda-pack -o $DIR/miniconda.tar.gz

tar -zcvf $DIR/homecli.tar.gz $DIR/homecli $DIR/nvim --exclude=$DIR/homecli/miniconda
