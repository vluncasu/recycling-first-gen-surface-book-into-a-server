# Copyright (c) project contributors; MIT. Run from local, trusted extracted folder.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$readyIso = 'SurfaceBook1-Debian13-EDGE-AUTOINSTALL.iso'
Write-Host "Surface Book 1 | Windows installer builder (WSL-based)" -ForegroundColor Cyan
Write-Host "This builds a PRIVATE USB image. No user drive is formatted by this script."
Write-Warning 'Selecting AUTO-INSTALL on the Surface ERASES the model-checked internal SSD.'
if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
    throw 'WSL is unavailable. Install WSL on a supported Windows version, then rerun.'
}
$distrosText = (& wsl.exe --list --quiet 2>&1 | Out-String).Replace([char]0, '')
$distros = $distrosText -split '[\r\n]+' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
$distro = $distros | Where-Object { $_ -match '^(Ubuntu|Debian)' } | Select-Object -First 1
if (-not $distro) {
    Write-Host 'WSL Linux distribution is not ready.' -ForegroundColor Yellow
    Write-Host 'Open PowerShell as Administrator and run: wsl --install -d Ubuntu'
    Write-Host 'Restart Windows if prompted, launch Ubuntu once, and create its Linux username/password.'
    throw 'WSL setup is a one-time prerequisite; rerun START_WINDOWS.cmd afterward.'
}
Write-Host "Linux environment: $distro"
$keyDir = Join-Path $env:USERPROFILE '.ssh'
$key = Join-Path $keyDir 'id_ed25519'
$pub = $key + '.pub'
if (-not (Test-Path $pub)) {
    if (-not (Get-Command ssh-keygen.exe -ErrorAction SilentlyContinue)) {
        throw 'Windows OpenSSH Client is needed to make an SSH key.'
    }
    New-Item -ItemType Directory -Force -Path $keyDir | Out-Null
    Write-Host 'Create an SSH key for Windows. Strongly recommended: protect with a passphrase.'
    & ssh-keygen.exe -t ed25519 -f $key -C 'surface-edge-windows'
    if ($LASTEXITCODE -ne 0) { throw 'SSH key generation failed.' }
}
function Convert-ToWsl([string]$p) {
    $v = (& wsl.exe -d $distro -- wslpath -u $p | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $v.StartsWith('/')) { throw "Could not map Windows path into WSL: $p" }
    return $v
}
$output = Join-Path $repo 'output'
New-Item -ItemType Directory -Force -Path $output | Out-Null
$wslRepo = Convert-ToWsl $repo
$wslOutput = Convert-ToWsl $output
$wslPub = Convert-ToWsl $pub
$linuxScript = "$wslRepo/installer/Build_Installer_Linux.sh"
Write-Host 'Next: the Linux builder asks for hostname, Wi-Fi SSID/password and a Linux account password.'
Write-Host 'Credentials stay local. Do not publish the generated ISO or the output folder.'
& wsl.exe -d $distro -- env "SURFACE_PUBLIC_KEY_PATH=$wslPub" bash $linuxScript $wslOutput
if ($LASTEXITCODE -ne 0) { throw 'The Linux build failed. Do not flash an older image.' }
$iso = Join-Path $output $readyIso
if (-not (Test-Path $iso)) { throw "Build returned success but expected ISO is missing: $iso" }
Write-Host "SUCCESS: $iso" -ForegroundColor Green
Write-Host 'Open balenaEtcher: Flash from file -> select this ISO -> select USB -> Flash.'
Write-Host 'Or use Rufus with DD Image mode to preserve the SURFACELOG partition.'
Invoke-Item $output
