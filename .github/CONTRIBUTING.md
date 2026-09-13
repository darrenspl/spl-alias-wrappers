# Contributing

Thanks for helping. This repo stays small on purpose, so the rules are short.

## The one rule

**Every shortcut exists twice**: once in `bash/` and once in `powershell/`, with
the same four file names in each folder. A change to one side needs the same
change on the other side, or a note in the pull request saying why it cannot.

## Before you open a pull request

Run all four from the repo folder:

```bash
bash bash/test.sh
shellcheck bash/*.sh
```

```powershell
./powershell/test.ps1
Invoke-ScriptAnalyzer -Path powershell -Recurse -Settings powershell/PSScriptAnalyzerSettings.psd1
```

CI runs the same checks on Linux, macOS and Windows, so a pull request that
passes here should pass there.

Then:

- Add a line under `## [Unreleased]` in `CHANGELOG.md` if people will notice
  the change.
- Update `README.md` if the change affects how someone installs or uses a
  shortcut.

## How the code is written

**Bash side**

- Must work in bash 3.2, because that is what macOS ships. No associative
  arrays, no `mapfile`, no `${var,,}`.
- `aliases.sh` must also load in zsh. `bash/test.sh` checks zsh when it is
  installed.
- Inside a function, call outside tools as `command find`, `command sed` and so
  on, so a user's own aliases cannot change what the function does.

**PowerShell side**

- Must work in Windows PowerShell 5.1. No `??`, no `? :`, no `&&` between
  commands.
- ASCII characters only in `.ps1` files. Windows PowerShell 5.1 can misread
  anything else.

**Both sides**

- LF line endings and four spaces. `.editorconfig` and `.gitattributes` set
  this up for you.
- Plain words in comments and messages. The people reading this are often new.

## Adding a new shortcut

1. Add it to `bash/aliases.sh` and `powershell/aliases.ps1`.
2. Add its name to the list the installers ask about, in both installers.
3. Add checks for it to both test files.
4. Add it to the tables in `README.md`.
5. Add a line to `CHANGELOG.md`.

Before step 1, open an issue. A new shortcut should have earned its place in
daily use.

## Safety

Never ship a shortcut that turns off a safety check by default. See
`docs/adr/0001-ship-agent-wrappers-safe-by-default.md` for why.
