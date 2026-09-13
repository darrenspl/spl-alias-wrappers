# Lint rules for the PowerShell scripts. CI runs:
#   Invoke-ScriptAnalyzer -Path powershell -Recurse -Settings powershell/PSScriptAnalyzerSettings.psd1
@{
    Severity     = @('Error', 'Warning')
    ExcludeRules = @(
        # The installers and tests talk to a person at a console. Write-Host is
        # the right tool for that: the text is for the reader, not for a pipeline.
        'PSAvoidUsingWriteHost',

        # aliases.ps1 keeps one flag for the whole session, so a profile that
        # loads it twice does not define everything twice. It has to be global.
        'PSAvoidGlobalVars'
    )
}
