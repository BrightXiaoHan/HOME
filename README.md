# HOME

My Personal Home Directory.

## Quick Start

### linux

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/BrightXiaoHan/HOME/main/scripts/install.sh)"
```

uninstall

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/BrightXiaoHan/HOME/main/scripts/uninstall.sh)"
```

pack

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/BrightXiaoHan/HOME/main/scripts/pack.sh)"
```

unpack

* Download prepacked `home-cli.tar` file and `install.sh`
* Run `install.sh`

```bash
bash install.sh unpack home-cli.tar
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
iex (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/BrightXiaoHan/HOME/main/scripts/install_macos.sh").Content
```

## Dev Container

Build image

```bash
docker build -t DevEnv .
```

Run Container

```bash
docker run -v /path/to/workspace:/workspace -itd  DevEnv
```
