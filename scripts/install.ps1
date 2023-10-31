# install scoop
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser # Optional: Needed to run a remote script the first time
# 判断是否为管理员
$isAdministrator = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if ($isAdministrator) {
    irm get.scoop.sh -outfile 'install.ps1'
    iex "& {$(irm get.scoop.sh)} -RunAsAdmin"
    Remove-Item install.ps1
} else {
    Invoke-RestMethod get.scoop.sh | Invoke-Expression
}

scoop install git

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

# Create symbolic links to the git config file
$gitConfig = Join-Path $env:USERPROFILE ".gitconfig"
New-Item -ItemType SymbolicLink -Path $gitConfig -Value $rootDir\general\gitconfig -Force

# Create symbolic links to the neovim config file
$nvimDir = Join-Path $env:USERPROFILE "AppData\Local\nvim"
New-Item -ItemType SymbolicLink -Path $nvimDir -Value $rootDir\general\NvChad -Force
New-Item -ItemType SymbolicLink -Path $nvimDir\lua\custom -Value $rootDir\general\custom -Force

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
scoop bucket add nerd-fonts
scoop install nerd-fonts/JetBrains-Mono
scoop install main/tssh
scoop bucket add extras

$ProgressPreference = "SilentlyContinue"
Install-Module -Name PSFzf

# Install Visual Studio Build Tools
winget install Microsoft.VisualStudio.2019.BuildTools --silent --override "--wait --quiet --add ProductLang En-us --add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended"
winget install -e --id Microsoft.VisualStudioCode
winget install -e --id Anaconda.Miniconda3
winget install -e --id Tencent.WeChat
winget install -e --id Microsoft.WindowsTerminal
winget install -e --id Kingsoft.WPSOffice.CN
winget install -e --id Microsoft.PowerToys
winget install -e --id Sogou.SogouInput
winget install -e --id Alibaba.DingTalk
winget install -e --id Valve.Steam
winget install -e --id Alibaba.aDrive
winget install -e --id tickstep.aliyunpan --silent
winget install -e --id Youqu.ToDesk
