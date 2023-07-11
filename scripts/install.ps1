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

# Install packer
git clone https://github.com/wbthomason/packer.nvim "$env:LOCALAPPDATA\nvim-data\site\pack\packer\start\packer.nvim"

# install treesitter requirements
scoop install gcc