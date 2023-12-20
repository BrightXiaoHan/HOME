# set PowerShell to UTF-8
[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

$omp_config = Join-Path $PSScriptRoot ".\takuya.omp.json"
Invoke-Expression (&starship init powershell)
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# PSReadLine
Set-PSReadLineOption -BellStyle None
Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
Set-PSReadLineOption -PredictionSource History

# Fzf
Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'

# Utilities
function which ($command) {
  Get-Command -Name $command -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

# add scoop bin to Path
$env:Path += ";$HOME\scoop\shims"

# Poetry
$env:POETRY_VIRTUALENVS_IN_PROJECT = 'true'

if(Test-Path 'C:\Users\Administrator\.inshellisense\key-bindings-pwsh.ps1' -PathType Leaf){. C:\Users\Administrator\.inshellisense\key-bindings-pwsh.ps1}