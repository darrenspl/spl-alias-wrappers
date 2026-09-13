# spl-alias-wrappers  -  https://github.com/darrenspl/spl-alias-wrappers
#
# The same five shortcuts as bash/aliases.sh, for PowerShell. Works in Windows
# PowerShell 5.1, and in PowerShell 7 on Windows, macOS and Linux.
#
# From the repo folder:
#   Install:  powershell -ExecutionPolicy Bypass -File powershell/install.ps1
#   Remove:   powershell -ExecutionPolicy Bypass -File powershell/uninstall.ps1
#   Check:    ./powershell/test.ps1
#
# Your names live in ~/.config/spl-alias-wrappers/config, the same plain
# name=value file the bash version reads, so both shells agree.
#
# Nothing here is machine specific and nothing here holds a secret.

# Load once per session, even if a profile loads this file twice.
if ($global:SplAliasWrappersLoaded) { return }
$global:SplAliasWrappersLoaded = $true

# Everything runs inside this block so its working variables do not end up in
# your session. The functions it makes are global on purpose.
& {
    # -- Saved settings ------------------------------------------------------
    # Read line by line and never run as code, so a bad line is simply ignored.
    $names = [ordered]@{ lsa = 'lsa'; c = 'c'; lsd = 'lsd'; cc = 'cc'; cx = 'cx' }
    $yolo  = $env:SPL_YOLO -eq '1'

    $configRoot = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }
    $config = Join-Path (Join-Path $configRoot 'spl-alias-wrappers') 'config'
    if (Test-Path -LiteralPath $config) {
        foreach ($line in Get-Content -LiteralPath $config) {
            if ($line -cnotmatch '^([a-z]+)=(.*)$') { continue }
            $key = $Matches[1]; $value = $Matches[2]
            if ($names.Contains($key)) { $names[$key] = $value }
            elseif ($key -eq 'yolo' -and $value -eq '1') { $yolo = $true }
        }
    }

    # -- What each shortcut does ---------------------------------------------

    # lsd <word>: list folders here whose name holds <word>, case ignored.
    #   lsd plane   shows  plane-api  Planeboard  my-plane-notes
    function global:SplLsd {
        param([string]$Word)
        if (-not $Word) { [Console]::Error.WriteLine('usage: lsd <word>'); return }
        # IndexOf with OrdinalIgnoreCase ignores case on every OS, and treats
        # characters like [ and * as plain text instead of patterns.
        $hits = @(Get-ChildItem -LiteralPath . -Directory -Force -ErrorAction SilentlyContinue |
                  Where-Object { $_.Name.IndexOf($Word, [StringComparison]::OrdinalIgnoreCase) -ge 0 } |
                  Sort-Object Name |
                  ForEach-Object { $_.Name })
        if ($hits.Count -eq 0) { [Console]::Error.WriteLine("no folder matches '$Word'"); return }
        $hits
    }

    # SplNeed <program> <label> <link>: the installed program, or a plain
    # message when it is missing. Checked each time, so a tool installed after
    # the window opened just works. Looking only for programs, never
    # functions, means naming a shortcut "claude" cannot loop.
    function global:SplNeed([string]$Program, [string]$Label, [string]$Link) {
        $found = Get-Command $Program -CommandType Application, ExternalScript -ErrorAction SilentlyContinue |
                 Select-Object -First 1
        if (-not $found) { [Console]::Error.WriteLine("$Label is not installed. See $Link") }
        $found
    }

    # cc starts Claude Code. cx starts OpenAI Codex.
    #
    # SAFETY. Both tools can turn off the check that asks you before they run
    # a command. That check is the thing that stops an agent from deleting a
    # folder you wanted. These wrappers leave it ON.
    #
    # To turn it off, you opt in on purpose: answer yes when install.ps1 asks,
    # or set yolo=1 in the settings file. Do that only on a machine where you
    # are fine with an agent running anything without asking. Never on a work
    # laptop, never on a shared computer.
    if ($yolo) {
        function global:SplCc {
            $exe = SplNeed 'claude' 'Claude Code' 'https://claude.com/claude-code'
            if ($exe) { & $exe --dangerously-skip-permissions @args }
        }
        function global:SplCx {
            $exe = SplNeed 'codex' 'Codex' 'https://developers.openai.com/codex'
            if ($exe) { & $exe --cd (Get-Location).Path --dangerously-bypass-approvals-and-sandbox @args }
        }
    } else {
        function global:SplCc {
            $exe = SplNeed 'claude' 'Claude Code' 'https://claude.com/claude-code'
            if ($exe) { & $exe @args }
        }
        function global:SplCx {
            $exe = SplNeed 'codex' 'Codex' 'https://developers.openai.com/codex'
            if ($exe) { & $exe --cd (Get-Location).Path @args }
        }
    }

    # -- The names -----------------------------------------------------------
    # PowerShell aliases cannot take arguments, so every shortcut here is a
    # small function. An empty name leaves that shortcut out.
    $bodies = @{
        lsa = { Get-ChildItem -Force @args }
        c   = { Clear-Host }
        lsd = { SplLsd @args }
        cc  = { SplCc @args }
        cx  = { SplCx @args }
    }
    foreach ($key in $names.Keys) {
        $name = $names[$key]
        if (-not $name) { continue }
        if ($name -cnotmatch '^[A-Za-z][A-Za-z0-9_-]*$') {
            [Console]::Error.WriteLine("spl-alias-wrappers: '$name' is not a usable name, skipped it")
            continue
        }
        # In PowerShell an alias wins over a function with the same name, so
        # clear any alias in the way.
        if (Test-Path -LiteralPath "alias:$name") {
            Remove-Item -LiteralPath "alias:$name" -Force -ErrorAction SilentlyContinue
        }
        Set-Item -Path "function:global:$name" -Value $bodies[$key]
    }
}
