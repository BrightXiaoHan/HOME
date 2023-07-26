# Create symbolic links to the user profile and the OMP configuration file
$rootDir = Split-Path -Parent $PSScriptRoot
$profileDir = Split-Path -Parent $PROFILE
New-Item -ItemType SymbolicLink -Path $PROFILE -Value $rootDir\general\powershell\user_profile.ps1 -Force
$omp_config = Join-Path $rootDir "powershell\takuya.omp.json"
New-Item -ItemType SymbolicLink -Path $profileDir\takuya.omp.json -Value $omp_config -Force

# Create symbolic links to the ssh config file
$sshDir = Join-Path $env:USERPROFILE ".ssh"
New-Item -ItemType SymbolicLink -Path $sshDir\config -Value $rootDir\general\ssh\config -Force

# Create symbolic links to the git config file
$gitConfig = Join-Path $env:USERPROFILE ".gitconfig"
New-Item -ItemType SymbolicLink -Path $gitConfig -Value $rootDir\general\gitconfig -Force

# Create symbolic links to the neovim config file
$nvimDir = Join-Path $env:USERPROFILE "AppData\Local\nvim"
New-Item -ItemType SymbolicLink -Path $nvimDir -Value $rootDir\general\nvim -Force

# install scoop
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser # Optional: Needed to run a remote script the first time
Invoke-RestMethod get.scoop.sh | Invoke-Expression

scoop bucket add main
scoop install main/winget
scoop install main/git-lfs
scoop install main/neovim
scoop install main/openssh
scoop install main/fzf
scoop install main/nodejs-lts
scoop install main/ripgrep
scoop bucket add nerd-fonts
scoop install nerd-fonts/JetBrains-Mono

$ProgressPreference = "SilentlyContinue"
Install-Module -Name PSFzf

# Install packer
git clone https://github.com/wbthomason/packer.nvim "$env:LOCALAPPDATA\nvim-data\site\pack\packer\start\packer.nvim"

# Install Visual Studio Build Tools
winget install -e --id Microsoft.VisualStudio.2019.BuildTools 
winget install -e --id Microsoft.VisualStudioCode
winget install -e --id Anaconda.Anaconda3
winget install -e --id Tencent.WeChat
winget install -e --id Microsoft.WindowsTerminal
winget install -e --id Kingsoft.WPSOffice.CN
winget install -e --id Postman.Postman
winget install -e --id Notion.Notion
winget install -e --id Microsoft.PowerToys
winget install -e --id Sogou.SogouInput
winget install -e --id Alibaba.DingTalk
winget install -e --id Valve.Steam
