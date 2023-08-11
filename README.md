# HOME
My Personal Home Directory.

## Quick Start
### linux
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/BrightXiaoHan/HOME/main/scripts/install.sh)"
```
uninstall
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/BrightXiaoHan/HOME/main/scripts/uninstall.sh)"
```
pack
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/BrightXiaoHan/HOME/main/scripts/pack.sh)"
```
### macos
Install Homebrew
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
Install Packages
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/BrightXiaoHan/HOME/main/scripts/install_macos.sh)"
```
### windows
Upgrade Powershell
```
iex "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI -Quiet"
```
Install Packages
```
iex (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/BrightXiaoHan/HOME/main/scripts/install_macos.sh").Content
```

## Dev Container
Build image
```
docker build -t DevEnv .
```
Run Container
```
docker run -v /path/to/workspace:/workplsace -itd  DevEnv
```
