# HOME

My Personal Home Directory.

## Quick Start

### linux

install

```bash
HOMECLI_INSTALL_DIR=$HOME/.homecli /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/BrightXiaoHan/HOME/main/scripts/install.sh)"
```

update

```bash
HOMECLI_INSTALL_DIR=$HOME/.homecli /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/BrightXiaoHan/HOME/main/scripts/update.sh)"
```

uninstall

```bash
HOMECLI_INSTALL_DIR=$HOME/.homecli /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/BrightXiaoHan/HOME/main/scripts/uninstall.sh)"
```

pack

```bash
HOMECLI_INSTALL_DIR=$HOME/.homecli /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/BrightXiaoHan/HOME/main/scripts/pack.sh)"
```

install from pre-built package

- Download prepacked run file in releases, `home-cli-x86_64.run` for example

```bash
bash home-cli-x86_64.run -- -m install --install-dir $HOME/.homecli
```

uninstall but don't delete installation cache, you can relink it if needed.

```bash
HOMECLI_INSTALL_DIR=$HOME/.homecli bash scripts/uninstall.sh --remove-cache false
```

relink

```bash
HOMECLI_INSTALL_DIR=$HOME/.homecli bash scripts/install.sh relink
```

### macos

Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Install Packages

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/BrightXiaoHan/HOME/main/scripts/install_macos.sh)"
```

### windows

Upgrade Powershell

```bash
iex "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI -Quiet"
```

Install Packages

```bash
iex (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/BrightXiaoHan/HOME/main/scripts/install.ps1").Content
```

## Dev Container

It's highly recommended to use podman to build and run the container.
You can mount your home directory to the container and do the development work in the container without any permission issue.

Build image

```shell
podman build -t home .
```

Build with custom args

```shell
podman build -t home --build-arg "VERSION=20.04" --network=host --build-arg "HTTPS_PROXY=http://127.0.0.1:7890" .
```

Run Container

```shell
podman run -v $HOME:/workspace --name home -itd home
```
