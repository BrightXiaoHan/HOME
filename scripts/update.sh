set -e
DIR=${HOMECLI_INSTALL_DIR:-$HOME/.homecli}

cd $DIR/HOME

git pull
PYTHONPATH="./:$PYTHONPATH" python homecli/install.py -c update
mamba update --all
