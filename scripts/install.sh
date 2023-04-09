# test if python3 is installed
if ! [ -x "$(command -v python3)" ]; then
  echo 'Error: python3 is not installed.' >&2
  exit 1
fi

# test if pip3 is installed
if ! [ -x "$(command -v pip3)" ]; then
  echo 'Error: pip3 is not installed.' >&2
  exit 1
fi

# install poetry
curl -sSL https://install.python-poetry.org | python3 -

# build and install homecli
poetry build
pip install -i https://pypi.douban.com/simple dist/*.whl

homecli install
