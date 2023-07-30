DIR=~/.cache/homecli

conda-pack -o $DIR/miniconda.tar.gz

tar -zcvf $DIR/homecli.tar.gz \
    $DIR/HOME $DIR/bin $DIR/miniconda.tar.gz $DIR/nodejs \
    ~/.local/share/nvim
