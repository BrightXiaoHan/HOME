DIR=~/.cache/homecli/HOME

cd $DIR

git pull
PYTHONPATH="./:$PYTHONPATH" python homecli/install.py -c update
