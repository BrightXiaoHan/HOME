$ErrorActionPreference = 'Stop'

# install scoop
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser # Optional: Needed to run a remote script the first time

# Judge whether the current user is an administrator 
$isAdministrator = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if ($isAdministrator) {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
    irm get.scoop.sh -outfile 'install.ps1'
    iex "& {$(irm get.scoop.sh)} -RunAsAdmin"
    Remove-Item install.ps1
} else {
    Invoke-RestMethod get.scoop.sh | Invoke-Expression
}

scoop install git

# install pyenv
Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1" -OutFile "./install-pyenv-win.ps1"; &"./install-pyenv-win.ps1"

# Clone the repository
git clone --recurse-submodules https://github.com/BrightXiaoHan/HOME.git

# Create symbolic links to the user profile and the OMP configuration file
$rootDir = (Get-Item -Path ".\HOME").FullName
$profileDir = Split-Path -Parent $PROFILE
New-Item -ItemType SymbolicLink -Path $PROFILE -Value $rootDir\general\powershell\user_profile.ps1 -Force
$omp_config = Join-Path $rootDir "powershell\takuya.omp.json"
New-Item -ItemType SymbolicLink -Path $profileDir\takuya.omp.json -Value $omp_config -Force

# Create symbolic links to the ssh config file
$sshDir = Join-Path $env:USERPROFILE ".ssh"
New-Item -ItemType SymbolicLink -Path $sshDir\config -Value $rootDir\general\ssh\config -Force
New-Item -ItemType SymbolicLink -Path $sshDir\id_rsa.pub -Value $rootDir\general\ssh\id_rsa.pub -Force

# Create symbolic links to the git config file
$gitConfig = Join-Path $env:USERPROFILE ".gitconfig"
New-Item -ItemType SymbolicLink -Path $gitConfig -Value $rootDir\general\gitconfig -Force

# Create symbolic links to the neovim config file
$nvimDir = Join-Path $env:USERPROFILE "AppData\Local\nvim"
New-Item -ItemType SymbolicLink -Path $nvimDir -Value $rootDir\general\NvChad -Force

scoop bucket add main
scoop install main/winget
scoop install main/git-lfs
scoop install main/neovim
scoop install main/openssh
scoop install main/fzf
scoop install main/nodejs-lts
scoop install main/ripgrep
scoop install main/starship
scoop install main/zoxide
scoop install main/clangd
scoop install main/wget
scoop install main/mosh-client
scoop install main/poetry
scoop install main/zig
scoop bucket add nerd-fonts
scoop install nerd-fonts/JetBrainsMono-NF
scoop install main/tssh
scoop install main/gh
scoop install main/sed
scoop bucket add extras

Install-Module -Name PSFzf

# Install Visual Studio Build Tools
# winget install -e --id Microsoft.VisualStudio.2019.BuildTools --accept-source-agreements --accept-package-agreements --silent --override "--wait --quiet --add ProductLang En-us --add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended"
# winget install -e --id Microsoft.VisualStudioCode --accept-source-agreements --accept-package-agreements --silent
winget install -e --id Tencent.WeChat --accept-source-agreements --accept-package-agreements --silent
winget install -e --id Microsoft.WindowsTerminal --accept-source-agreements --accept-package-agreements --silent
winget install -e --id Kingsoft.WPSOffice.CN --accept-source-agreements --accept-package-agreements --silent
winget install -e --id Microsoft.PowerToys --accept-source-agreements --accept-package-agreements --silent
winget install -e --id Sogou.SogouInput --accept-source-agreements --accept-package-agreements --silent
winget install -e --id Alibaba.DingTalk --accept-source-agreements --accept-package-agreements --silent
winget install -e --id Valve.Steam --accept-source-agreements --accept-package-agreements --silent
winget install -e --id Alibaba.aDrive --accept-source-agreements --accept-package-agreements --silent
winget install -e --id tickstep.aliyunpan --accept-source-agreements --accept-package-agreements --silent
winget install -e --id Youqu.ToDesk --accept-source-agreements --accept-package-agreements --silent
