# Install the five shortcuts for PowerShell, and ask whether you want other names.
#
#   ./install.ps1              asks a few questions, Enter keeps what is shown
#   ./install.ps1 -NoPrompt    no questions, keeps saved choices or the defaults
#
# Safe to run again. Run it again any time to change a name. Run it once from
# each PowerShell you use: Windows PowerShell 5.1 and PowerShell 7 each read
# their own profile.
#
# If Windows says running scripts is disabled, start it like this:
#   powershell -ExecutionPolicy Bypass -File install.ps1
#
# Using bash or zsh? Run install.sh instead. Both read the same saved names.
param(
    [switch]$NoPrompt,
    # Where to add the load line. Leave it out to use your normal profile.
    [string[]]$ProfilePath
)
$ErrorActionPreference = 'Stop'

$repo    = $PSScriptRoot
$source  = Join-Path $repo 'aliases.ps1'
$configRoot = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }
$confDir = Join-Path $configRoot 'spl-alias-wrappers'
$config  = Join-Path $confDir 'config'
$mark    = '# >>> spl-alias-wrappers >>>'
$end     = '# <<< spl-alias-wrappers <<<'
$onWindows = ($PSVersionTable.PSEdition -eq 'Desktop') -or $IsWindows

if (-not (Test-Path -LiteralPath $source)) { throw "install: cannot find $source" }

$keys = @('lsa', 'c', 'lsd', 'cc', 'cx')
$what = @{
    lsa = 'list every file, hidden ones too'
    c   = 'clear the screen'
    lsd = 'find folders by name'
    cc  = 'start Claude Code'
    cx  = 'start OpenAI Codex'
}

# ── Start from the last run's choices, or the defaults ─────────────────────
$names = [ordered]@{ lsa = 'lsa'; c = 'c'; lsd = 'lsd'; cc = 'cc'; cx = 'cx' }
$yolo = $false
if (Test-Path -LiteralPath $config) {
    foreach ($line in Get-Content -LiteralPath $config) {
        if ($line -cnotmatch '^([a-z]+)=(.*)$') { continue }
        if ($names.Contains($Matches[1])) { $names[$Matches[1]] = $Matches[2] }
        elseif ($Matches[1] -eq 'yolo' -and $Matches[2] -eq '1') { $yolo = $true }
    }
}

# ── Small helpers ───────────────────────────────────────────────────────────
# Ask <prompt>: one line of input. At end of input it stops asking and every
# later question keeps what is shown, so piping in answers never hangs.
$script:asking = -not $NoPrompt
function Ask([string]$Prompt) {
    if (-not $script:asking) { return $null }
    Write-Host -NoNewline $Prompt
    if ([Console]::IsInputRedirected) { $reply = [Console]::In.ReadLine() } else { $reply = Read-Host }
    if ($null -eq $reply) { $script:asking = $false; Write-Host ''; return $null }
    return $reply.TrimEnd("`r")
}
function YesNo([string]$Prompt) {
    $reply = Ask "$Prompt [y/N] "
    return ($reply -match '^[Yy]')
}

function IsValid([string]$Name) { return ($Name -cmatch '^[A-Za-z][A-Za-z0-9_-]*$') }

# IsTaken <name> <key>: true when another shortcut already has this name.
# PowerShell ignores case in command names, so this does too.
function IsTaken([string]$Name, [string]$Self) {
    foreach ($k in $keys) {
        if ($k -ne $Self -and $names[$k] -eq $Name) { return $true }
    }
    return $false
}

# ClashWith <name>: say what on this machine already answers to this name.
# Functions are left out, so the shortcuts from an earlier install do not count.
function ClashWith([string]$Name) {
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue |
           Where-Object { $_.CommandType -ne 'Function' } |
           Select-Object -First 1
    if (-not $cmd) { return '' }
    if ($cmd.CommandType -eq 'Alias')  { return "the PowerShell alias for $($cmd.Definition)" }
    if ($cmd.CommandType -eq 'Cmdlet') { return "the PowerShell command $($cmd.Name)" }
    return "the program $($cmd.Source)"
}

function Show {
    foreach ($k in $keys) {
        $shown = if ($names[$k]) { $names[$k] } else { '(off)' }
        Write-Host ('  {0,-10} {1}' -f $shown, $what[$k])
    }
}

# ── Questions ───────────────────────────────────────────────────────────────
Write-Host ''
Write-Host 'spl-alias-wrappers'
Write-Host ''
Write-Host 'These shortcuts will be set up:'
Show
Write-Host ''

if (YesNo 'Change a name, or leave one out?') {
    Write-Host ''
    Write-Host 'Press Enter to keep the name shown. Type - to leave that shortcut out.'
    foreach ($k in $keys) {
        while ($true) {
            $shown = if ($names[$k]) { $names[$k] } else { '-' }
            $reply = Ask "  $($what[$k]) [$shown]: "
            if ([string]::IsNullOrEmpty($reply)) { $new = $names[$k] }
            elseif ($reply -eq '-') { $new = '' }
            else { $new = $reply }
            if (-not $new) { $names[$k] = ''; break }

            if (-not (IsValid $new)) {
                Write-Host "    '$new' will not work. Start with a letter, then letters, numbers, - or _."
                if ($script:asking) { continue }
                $names[$k] = ''; break
            }
            if (IsTaken $new $k) {
                Write-Host "    '$new' is already the name for another shortcut."
                if ($script:asking) { continue }
                $names[$k] = ''; break
            }
            $used = ClashWith $new
            if ($used) {
                if (-not (YesNo "    '$new' is already $used. Your shortcut would hide it. Use it anyway?")) {
                    if ($script:asking) { continue }
                }
            }
            $names[$k] = $new; break
        }
    }

    if ($names['cc'] -or $names['cx']) {
        Write-Host ''
        Write-Host 'Claude Code and Codex stop and ask you before they run a command.'
        Write-Host 'That check is what keeps an agent from deleting work you wanted.'
        Write-Host 'You can turn it off. Only do that on a machine you could wipe tomorrow.'
        $yolo = [bool](YesNo 'Turn the safety check OFF?')
    }
}

# ── Save the choices ────────────────────────────────────────────────────────
# Plain LF lines with no byte order mark, so bash reads the same file cleanly.
New-Item -ItemType Directory -Force -Path $confDir | Out-Null
$lines = @(
    "# spl-alias-wrappers settings, written by install.ps1 on $(Get-Date -Format yyyy-MM-dd).",
    '# One shortcut per line: shortcut=the name you type. An empty name leaves',
    '# that shortcut out. yolo=1 turns OFF the safety check for Claude Code and',
    '# Codex. Bash and PowerShell both read this file. Open a new terminal after',
    '# you change it.'
)
foreach ($k in $keys) { $lines += "$k=$($names[$k])" }
$lines += "yolo=$(if ($yolo) { 1 } else { 0 })"
[IO.File]::WriteAllText("$config.new", (($lines -join "`n") + "`n"), (New-Object System.Text.UTF8Encoding $false))
Move-Item -Force -LiteralPath "$config.new" -Destination $config

# ── Let the profile run, on Windows ─────────────────────────────────────────
$policyNote = ''
if ($onWindows) {
    # A zip download marks files as coming from the internet. Clear that mark
    # on this repo's own scripts so the profile is allowed to load them.
    Get-ChildItem -LiteralPath $repo -Filter '*.ps1' | Unblock-File

    # The policy that applies when a new window opens. The Process scope is
    # skipped on purpose: -ExecutionPolicy Bypass on this run does not last.
    $effective = if ($PSVersionTable.PSEdition -eq 'Desktop') { 'Restricted' } else { 'RemoteSigned' }
    $setBy = 'default'
    foreach ($scope in 'MachinePolicy', 'UserPolicy', 'CurrentUser', 'LocalMachine') {
        $p = "$(Get-ExecutionPolicy -Scope $scope)"
        if ($p -ne 'Undefined') { $effective = $p; $setBy = $scope; break }
    }

    if ($effective -in 'Restricted', 'AllSigned') {
        if ($setBy -in 'MachinePolicy', 'UserPolicy') {
            $policyNote = "  Your organization blocks PowerShell scripts ($effective, set by group policy).`n" +
                          "  The shortcuts cannot load in PowerShell on this computer. WSL2 or Git Bash with install.sh will work."
        } else {
            Write-Host ''
            Write-Host "PowerShell is set to $effective, which stops your profile from loading these shortcuts."
            Write-Host 'The usual fix lets scripts you wrote or cloned run, for your account only:'
            Write-Host '  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned'
            if (YesNo 'Run that now?') {
                Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force
                $policyNote = '  Scripts are now allowed for your account (RemoteSigned).'
            } else {
                $policyNote = "  PowerShell is still set to $effective, so the shortcuts will not load yet.`n" +
                              '  To fix it later: Set-ExecutionPolicy -Scope CurrentUser RemoteSigned'
            }
        }
    }
}

# ── Add the load line to your profile ───────────────────────────────────────
if (-not $ProfilePath) { $ProfilePath = @($PROFILE.CurrentUserAllHosts) }
$quoted = $source -replace "'", "''"
$nl = [Environment]::NewLine
$block = $nl + $mark + $nl +
         "# Shortcuts from $repo. Remove with uninstall.ps1 in that folder." + $nl +
         "if (Test-Path -LiteralPath '$quoted') { . '$quoted' }" + $nl +
         $end + $nl

$report = @()
foreach ($p in $ProfilePath) {
    $dir = Split-Path -Parent $p
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $text = ''
    if (Test-Path -LiteralPath $p) { $text = [IO.File]::ReadAllText($p) }
    if ($text.Contains($mark)) {
        $report += "  Load line in ${p}: already there"
        continue
    }
    if (Test-Path -LiteralPath $p) {
        $backup = "$p.bak.$(Get-Date -Format yyyyMMdd-HHmmss)"
        Copy-Item -LiteralPath $p -Destination $backup
        $report += "  Load line in ${p}: added, old copy saved as $backup"
    } else {
        $report += "  Load line in ${p}: added, new profile file"
    }
    # UTF-8 with a byte order mark, so Windows PowerShell 5.1 reads a folder
    # name with accents correctly.
    [IO.File]::WriteAllText($p, $text + $block, (New-Object System.Text.UTF8Encoding $true))
}

# ── Report ──────────────────────────────────────────────────────────────────
Write-Host ''
Write-Host 'Done.'
$report | ForEach-Object { Write-Host $_ }
Write-Host "  Your names saved in $config"
Write-Host ''
Show
foreach ($k in $keys) {
    if (-not $names[$k]) { continue }
    $used = ClashWith $names[$k]
    if ($used) { Write-Host "  Note: '$($names[$k])' hides $used. Run install.ps1 again to rename it." }
}
Write-Host ''
if ($yolo) { Write-Host '  Safety check is OFF for Claude Code and Codex.' }
else       { Write-Host '  Safety check is ON for Claude Code and Codex.' }
if ($policyNote) { Write-Host ''; Write-Host $policyNote }
Write-Host ''
Write-Host 'Open a new PowerShell window to start using them.'
