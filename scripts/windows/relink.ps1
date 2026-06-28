param(
    [string]$RepoDir,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

if (-not $RepoDir) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $RepoDir = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
}

$configDir = Join-Path $RepoDir 'configs'
if (-not (Test-Path $configDir)) {
    throw "configs directory not found: $configDir"
}

function Ensure-ParentDir($Path) {
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
}

function Is-ReparsePoint($Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $item = Get-Item -LiteralPath $Path -Force
    return ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
}

function Link-Path($Source, $Target) {
    Ensure-ParentDir $Target

    if (Test-Path -LiteralPath $Target) {
        if ((Is-ReparsePoint $Target) -or $Force) {
            Remove-Item -LiteralPath $Target -Recurse -Force
        } else {
            Write-Warning "skip existing non-symlink: $Target"
            return
        }
    }

    New-Item -ItemType SymbolicLink -Path $Target -Value $Source -Force | Out-Null
    Write-Host "$Target -> $Source"
}

$profileDir = Split-Path -Parent $PROFILE
$sshDir = Join-Path $env:USERPROFILE '.ssh'
$nvimDir = Join-Path $env:USERPROFILE 'AppData\Local\nvim'

Link-Path (Join-Path $configDir 'powershell\user_profile.ps1') $PROFILE
Link-Path (Join-Path $configDir 'powershell\takuya.omp.json') (Join-Path $profileDir 'takuya.omp.json')
Link-Path (Join-Path $configDir 'ssh\config') (Join-Path $sshDir 'config')
Link-Path (Join-Path $configDir 'ssh\config.d') (Join-Path $sshDir 'config.d')
Link-Path (Join-Path $configDir 'ssh\id_rsa.pub') (Join-Path $sshDir 'id_rsa.pub')
Link-Path (Join-Path $configDir 'gitconfig') (Join-Path $env:USERPROFILE '.gitconfig')
Link-Path (Join-Path $configDir 'agents') (Join-Path $env:USERPROFILE '.agents')
Link-Path (Join-Path $configDir 'nvim') $nvimDir
