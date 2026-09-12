# Check that the shortcuts load, behave, and install cleanly. No test tools.
# Run it: ./test.ps1     Prints one line per check, exits 1 on any failure.
#
# Every check runs in a fresh PowerShell with no profile and a throwaway
# settings folder, so nothing on your own machine is read or changed.
# Works in Windows PowerShell 5.1 and in PowerShell 7 on any OS.
$ErrorActionPreference = 'Stop'

$repo    = $PSScriptRoot
$source  = Join-Path $repo 'aliases.ps1'
$shell   = (Get-Process -Id $PID).Path          # the same PowerShell running this file
$sandbox = Join-Path ([IO.Path]::GetTempPath()) ('spl-alias-test-' + [guid]::NewGuid())
$mark    = '# >>> spl-alias-wrappers >>>'
$script:pass = 0
$script:fail = 0

function Check([string]$What, $Want, $Got) {
    if ("$Want" -ceq "$Got") {
        Write-Host "ok    $What"; $script:pass++
    } else {
        Write-Host "FAIL  $What"
        Write-Host "        want: $Want"
        Write-Host "        got:  $Got"
        $script:fail++
    }
}

# Run <settings file contents> <code> [code to run before loading]: a fresh
# PowerShell with no profile, the given saved settings, aliases.ps1 loaded,
# then the code. Returns everything it printed, errors included, as one string.
function Run([string]$Settings, [string]$Code, [string]$Before = '') {
    $configRoot = Join-Path $sandbox ([guid]::NewGuid())
    $dir = Join-Path $configRoot 'spl-alias-wrappers'
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    if ($Settings) { [IO.File]::WriteAllText((Join-Path $dir 'config'), $Settings) }
    $q = $source -replace "'", "''"
    # Send the child's error text to its normal output. Windows PowerShell 5.1
    # tries to read a child PowerShell's error stream as XML and fails on
    # plain text, which is exactly what the shortcuts print on a miss.
    $text = "[Console]::SetError([Console]::Out)`n$Before`n. '$q'`n$Code"
    # An encoded command survives quotes and new lines on every OS and edition.
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($text))
    $out = WithSettings $configRoot {
        & $shell -NoProfile -NonInteractive -ExecutionPolicy Bypass -OutputFormat Text -EncodedCommand $encoded 2>&1
    }
    return ((@($out) | ForEach-Object { "$_".TrimEnd() }) -join "`n").Trim()
}

# WithSettings <folder> <block>: run the block with the settings folder pointed
# at <folder> and SPL_YOLO cleared, then put both back.
function WithSettings([string]$ConfigRoot, [scriptblock]$Block) {
    $oldXdg = $env:XDG_CONFIG_HOME; $oldYolo = $env:SPL_YOLO
    $env:XDG_CONFIG_HOME = $ConfigRoot; $env:SPL_YOLO = $null
    try { & $Block } finally { $env:XDG_CONFIG_HOME = $oldXdg; $env:SPL_YOLO = $oldYolo }
}

$free = "if (Get-Command {0} -CommandType Function -ErrorAction SilentlyContinue) {{ 'taken' }} else {{ 'free' }}"

try {
    New-Item -ItemType Directory -Force -Path $sandbox | Out-Null
    $dirs  = Join-Path $sandbox 'dirs'
    $empty = Join-Path $sandbox 'empty'
    New-Item -ItemType Directory -Force -Path (Join-Path $dirs 'PlaneNotes'), (Join-Path $dirs 'other'), $empty | Out-Null
    $cdDirs = "Set-Location -LiteralPath '$($dirs -replace "'", "''")'"

    # ── Default names ───────────────────────────────────────────────────────
    foreach ($name in 'lsa', 'c', 'lsd', 'cc', 'cx') {
        Check "$name is a function" 'Function' (Run '' "(Get-Command $name).CommandType")
    }
    Check 'lsa lists hidden files too' 'True' `
          (Run '' "(Get-Command lsa).Definition.Contains('-Force')")

    # ── lsd ─────────────────────────────────────────────────────────────────
    Check 'lsd matches ignoring case' 'PlaneNotes' (Run '' "$cdDirs; lsd plane")
    Check 'lsd says so on no match' "no folder matches 'zzzz'" (Run '' "$cdDirs; lsd zzzz")
    Check 'lsd shows how to use it with no word' 'usage: lsd <word>' (Run '' 'lsd')
    Check 'lsd still works when an alias already had that name' 'PlaneNotes' `
          (Run '' "$cdDirs; lsd plane" 'Set-Alias -Name lsd -Value Get-Date -Scope Global')

    # ── Claude Code and Codex ───────────────────────────────────────────────
    Check 'cc is safe by default' 'False' `
          (Run '' "(Get-Command SplCc).Definition.Contains('dangerously-skip-permissions')")
    Check 'cx is safe by default' 'False' `
          (Run '' "(Get-Command SplCx).Definition.Contains('dangerously-bypass-approvals-and-sandbox')")
    Check 'yolo=1 in settings turns cc loose' 'True' `
          (Run "yolo=1`n" "(Get-Command SplCc).Definition.Contains('dangerously-skip-permissions')")
    Check 'yolo=1 in settings turns cx loose' 'True' `
          (Run "yolo=1`n" "(Get-Command SplCx).Definition.Contains('dangerously-bypass-approvals-and-sandbox')")
    Check 'yolo=0 in settings keeps cc safe' 'False' `
          (Run "yolo=0`n" "(Get-Command SplCc).Definition.Contains('dangerously-skip-permissions')")
    Check 'cc says so when Claude Code is not installed' `
          'Claude Code is not installed. See https://claude.com/claude-code' `
          (Run '' "`$env:PATH = '$($empty -replace "'", "''")'; cc")

    # ── Custom names ────────────────────────────────────────────────────────
    Check 'a new name works'            'Function' (Run "cc=cl`n" '(Get-Command cl).CommandType')
    Check 'the old name is handed back' 'free'     (Run "cc=cl`n" ($free -f 'cc'))
    Check 'an empty name leaves it out' 'free'     (Run "cx=`n"   ($free -f 'cx'))
    Check 'a settings file with Windows line endings still works' 'Function' `
          (Run "cc=cl`r`n" '(Get-Command cl).CommandType')
    Check 'a broken name is skipped, PowerShell still loads' 'free' `
          ((Run "lsd=bad name;x`n" ($free -f 'lsd')) -split "`n" | Select-Object -Last 1)
    Check 'loading twice is a no-op' 'Function' `
          (Run '' ". '$($source -replace "'", "''")'; (Get-Command lsa).CommandType")

    # ── install.ps1 and uninstall.ps1 ───────────────────────────────────────
    $installer   = Join-Path $repo 'install.ps1'
    $uninstaller = Join-Path $repo 'uninstall.ps1'
    function Invoke-Script([string]$ConfigRoot, [string]$Answers, [string[]]$ScriptArgs) {
        WithSettings $ConfigRoot {
            if ($null -ne $Answers) {
                $Answers | & $shell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File @ScriptArgs *> $null
            } else {
                & $shell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File @ScriptArgs *> $null
            }
        }
    }
    function MarkCount([string]$Path) {
        if (-not (Test-Path -LiteralPath $Path)) { return 0 }
        return ([regex]::Matches([IO.File]::ReadAllText($Path), [regex]::Escape($mark))).Count
    }
    function Lines([string]$Path) { return @(Get-Content -LiteralPath $Path) }

    $c1 = Join-Path $sandbox 'conf1'; $p1 = Join-Path $sandbox 'p1/profile.ps1'
    New-Item -ItemType Directory -Force -Path (Split-Path $p1) | Out-Null
    [IO.File]::WriteAllText($p1, "`$KEEP_ME = 1`n")
    Invoke-Script $c1 $null @($installer, '-NoPrompt', '-ProfilePath', $p1)
    Invoke-Script $c1 $null @($installer, '-NoPrompt', '-ProfilePath', $p1)
    $conf1 = Join-Path $c1 'spl-alias-wrappers/config'
    Check 'install adds the load line once, even run twice' 1 (MarkCount $p1)
    Check 'install -NoPrompt saves the default names' 'True' ((Lines $conf1) -contains 'cc=cc')

    $loaded = WithSettings $c1 {
        & $shell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ". '$($p1 -replace "'", "''")'; (Get-Command lsa).CommandType" 2>&1
    }
    Check 'the profile it writes really loads the shortcuts' 'Function' ("$loaded".Trim())

    $c2 = Join-Path $sandbox 'conf2'; $p2 = Join-Path $sandbox 'p2/profile.ps1'
    # Answers, in order: change names? y, lsa, c, lsd, cc as cl, cx left out, safety off? n
    Invoke-Script $c2 "y`n`n`n`ncl`n-`nn`n" @($installer, '-ProfilePath', $p2)
    $conf2 = Join-Path $c2 'spl-alias-wrappers/config'
    Check 'install saves a renamed shortcut'  'True' ((Lines $conf2) -contains 'cc=cl')
    Check 'install saves a left-out shortcut' 'True' ((Lines $conf2) -contains 'cx=')
    Check 'install keeps the safety check on when told no' 'True' ((Lines $conf2) -contains 'yolo=0')
    Check 'install writes plain LF lines bash can read' 'False' `
          ([IO.File]::ReadAllText($conf2).Contains("`r"))

    $c3 = Join-Path $sandbox 'conf3'; $p3 = Join-Path $sandbox 'p3/profile.ps1'
    Invoke-Script $c3 "y`nlsa`n" @($installer, '-ProfilePath', $p3)
    Check 'install finishes when the answers run out' 'True' `
          ((Lines (Join-Path $c3 'spl-alias-wrappers/config')) -contains 'cx=cx')

    Invoke-Script $c1 $null @($uninstaller, '-ProfilePath', $p1)
    Check 'uninstall removes the load line' 0 (MarkCount $p1)
    Check 'uninstall leaves the rest of the profile alone' 'True' ((Lines $p1) -contains '$KEEP_ME = 1')
    Check 'uninstall keeps the saved names for bash' 'True' (Test-Path -LiteralPath $conf1)
}
finally {
    Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
Write-Host "$($script:pass) passed, $($script:fail) failed"
if ($script:fail -gt 0) { exit 1 }
