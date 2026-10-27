# Optional post-install management, NOT needed to create the USB.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not (Get-Command scp.exe -ErrorAction SilentlyContinue) -or -not (Get-Command ssh.exe -ErrorAction SilentlyContinue)) {
    throw 'Install Windows OpenSSH Client first.'
}
$user = Read-Host 'Debian SSH username (example: surfaceadmin)'
$hostName = Read-Host 'Debian hostname / IP (example: surfacebook-node.local)'
if ($user -notmatch '^[a-z_][a-z0-9_-]{0,30}$' -or $hostName -notmatch '^[a-zA-Z0-9.-]+$') { throw 'Invalid username or hostname.' }
$script = Join-Path $PSScriptRoot '..\scripts\postconfigure-remote.sh'
$dest = ".surface-postconfig-$PID.sh"
Write-Host 'The server will ask for SSH/sudo credentials when necessary.'
& scp.exe $script "${user}@${hostName}:$dest"
if ($LASTEXITCODE -ne 0) { throw 'SCP failed.' }
& ssh.exe -tt "${user}@${hostName}" "sudo bash '$dest'; rc=`$?; rm -f '$dest'; exit `$rc"
if ($LASTEXITCODE -ne 0) { throw 'Remote post-configuration failed. Check SSH and remote logs.' }
Write-Host 'Remote post-configuration completed. Verify service status before production use.'
