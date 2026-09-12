# Take the load line back out of your PowerShell profile.
# Your saved names stay, because bash or zsh may still be using them.
#
# Run it once from each PowerShell you installed into.
param(
    # Which profile to clean. Leave it out to use your normal profile.
    [string[]]$ProfilePath
)
$ErrorActionPreference = 'Stop'

$mark = '# >>> spl-alias-wrappers >>>'
$end  = '# <<< spl-alias-wrappers <<<'
$configRoot = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }
$config = Join-Path (Join-Path $configRoot 'spl-alias-wrappers') 'config'
if (-not $ProfilePath) { $ProfilePath = @($PROFILE.CurrentUserAllHosts) }

$removed = $false
foreach ($p in $ProfilePath) {
    if (-not (Test-Path -LiteralPath $p)) { continue }
    $lines = [IO.File]::ReadAllLines($p)
    if ($lines -notcontains $mark) { continue }

    $backup = "$p.bak.$(Get-Date -Format yyyyMMdd-HHmmss)"
    Copy-Item -LiteralPath $p -Destination $backup
    Write-Host "Backed up $p to $backup"

    # Drop every line from the start marker through the end marker.
    $keep = New-Object System.Collections.Generic.List[string]
    $inside = $false
    foreach ($line in $lines) {
        if ($line -eq $mark) { $inside = $true; continue }
        if ($line -eq $end)  { $inside = $false; continue }
        if (-not $inside) { $keep.Add($line) }
    }
    [IO.File]::WriteAllLines($p, $keep, (New-Object System.Text.UTF8Encoding $true))
    Write-Host "Removed the load line from $p"
    $removed = $true
}

if ($removed) {
    Write-Host ''
    Write-Host 'Open a new PowerShell window, and the shortcuts are gone.'
} else {
    Write-Host 'Not installed in this PowerShell profile. Nothing to do.'
}

if (Test-Path -LiteralPath $config) {
    Write-Host "Your saved names are still in $config."
    Write-Host 'Delete that file once you are done with both PowerShell and bash.'
}
