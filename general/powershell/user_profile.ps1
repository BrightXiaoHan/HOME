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

function Get-VSCodeCommitId {
  # Try `code --version` first
  try {
    $codeOutput = & code --version 2>$null
  } catch {
    $codeOutput = $null
  }

  if ($codeOutput) {
    $lines = $codeOutput -split "`r?`n"
    if ($lines.Length -ge 2 -and $lines[1]) {
      return $lines[1].Trim()
    }
  }

  # Fallback to product.json in common Windows locations
  $paths = @(
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code\resources\app\product.json",
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code Insiders\resources\app\product.json",
    "$env:ProgramFiles\Microsoft VS Code\resources\app\product.json",
    "$env:ProgramFiles\Microsoft VS Code Insiders\resources\app\product.json",
    "${env:ProgramFiles(x86)}\Microsoft VS Code\resources\app\product.json",
    "${env:ProgramFiles(x86)}\Microsoft VS Code Insiders\resources\app\product.json"
  )

  foreach ($p in $paths) {
    if (Test-Path $p -PathType Leaf) {
      try {
        $json = Get-Content -Raw $p | ConvertFrom-Json
        if ($json.commit) {
          return $json.commit
        }
      } catch {
        # keep searching
      }
    }
  }

  return $null
}

function vscode-server-upload {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Host,

    [string]$CommitId
  )

  if (-not $CommitId) {
    $CommitId = Get-VSCodeCommitId
  }

  if (-not $CommitId) {
    Write-Error "Unable to determine VS Code commit id. Provide it as the second argument."
    return
  }

  if (-not (Get-Command scp -ErrorAction SilentlyContinue)) {
    Write-Error "scp not found. Install OpenSSH client or ensure it is in PATH."
    return
  }

  if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
    Write-Error "ssh not found. Install OpenSSH client or ensure it is in PATH."
    return
  }

  $url = "https://update.code.visualstudio.com/commit:$CommitId/server-linux-x64/stable"
  $tmpdir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())) -Force
  $tarball = Join-Path $tmpdir.FullName "vscode-server-linux-x64.tar.gz"

  Write-Host "Downloading VS Code server: $url"
  Invoke-WebRequest -Uri $url -OutFile $tarball -UseBasicParsing

  Write-Host "Uploading to $Host"
  & scp $tarball "$Host:~/vscode-server-linux-x64.tar.gz"

  Write-Host "Installing on $Host"
  $remoteCmd = "set -e; commit_id=$CommitId; mkdir -p ~/.vscode-server/bin/`$commit_id; tar zxvf ~/vscode-server-linux-x64.tar.gz -C ~/.vscode-server/bin/`$commit_id --strip 1; touch ~/.vscode-server/bin/`$commit_id/0; rm -f ~/vscode-server-linux-x64.tar.gz"
  & ssh $Host $remoteCmd

  Remove-Item -Recurse -Force $tmpdir
}

# add scoop bin to Path
$env:Path += ";$HOME\scoop\shims"

# Poetry
$env:POETRY_VIRTUALENVS_IN_PROJECT = 'true'

if(Test-Path 'C:\Users\Administrator\.inshellisense\key-bindings-pwsh.ps1' -PathType Leaf){. C:\Users\Administrator\.inshellisense\key-bindings-pwsh.ps1}
