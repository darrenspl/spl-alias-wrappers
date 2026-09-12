# ADR 0002: Ship a PowerShell version next to the bash one

Date: 2026-09-12
**Status:** Accepted

## Context

The five shortcuts started as bash, which covers Linux, macOS, WSL2 and Git
Bash. A Windows user who lives in plain PowerShell gets nothing from bash.

Darren's own rule for his tooling bans Windows-only shells and `.ps1` files.
That rule protects the config he syncs across his own machines. This repo is
different: it is public, and it is for students and viewers, many of whom are
on Windows and never open anything but PowerShell.

## Options considered

a. Bash only. Tell PowerShell users to install WSL2 or Git Bash.
b. A PowerShell version of every script, kept in step with the bash one.
c. Generate both versions from one list of shortcuts.

## Decision

Option b.

Each of `aliases`, `install`, `uninstall` and `test` exists as `.sh` and `.ps1`,
side by side at the top of the repo. The PowerShell files work in Windows
PowerShell 5.1, which every Windows computer has, and in PowerShell 7 on any OS.

## Why

- Option a asks a beginner to set up a second environment before they can try
  a shortcut they just watched someone use. That is the wrong first step.
- Option c needs a generator, and the generator would be more code than the
  shortcuts. Five shortcuts do not need it.
- Keeping the pairs side by side makes a change to one easy to spot as missing
  from the other.

## How the two stay in step

- **One settings file.** Both read `~/.config/spl-alias-wrappers/config`, plain
  `name=value` lines. It is parsed, never run as code, in either shell.
- **Same checks.** `test.sh` and `test.ps1` cover the same behavior: default
  names, `lsd`, the safety flags, renaming, leaving out, broken names, install,
  uninstall.
- **Every push.** GitHub Actions runs both on Ubuntu, macOS and Windows, and
  runs `test.ps1` in Windows PowerShell 5.1 as well.

## Differences we accept

- PowerShell aliases cannot take arguments, so every PowerShell shortcut is a
  small function. Same result at the prompt.
- `lsd` in bash returns exit code 1 or 2 on a miss. PowerShell functions do not
  have exit codes the same way, so it prints the same message and returns
  nothing.
- Windows PowerShell 5.1 and PowerShell 7 each read their own profile, so a
  user with both runs the installer twice.
- On Windows, scripts are blocked out of the box. The installer detects that
  and asks before changing the policy for the user's own account. It never
  changes it without a yes, and cannot change a policy set by an organization.

## Cost

Every change is made twice. That is the price of reaching PowerShell users, and
the shared settings file and paired tests keep it honest.
