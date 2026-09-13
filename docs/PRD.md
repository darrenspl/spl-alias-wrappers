# PRD: spl-alias-wrappers

Written: 2026-09-12

## What this is

A small public repo holding five shell shortcuts, plus the scripts to install,
update, remove and check them.

## Who it is for

1. Darren, setting up a new workstation. One clone and one script.
2. Students and viewers, who see these shortcuts used in a class or a video and
   want the same ones without copying text off a screen.

## What it must do

- Install with one clone and one script, on Linux, macOS and Windows, in bash,
  zsh, Windows PowerShell 5.1 or PowerShell 7.
- Let the user rename or leave out any shortcut, and keep those choices in one
  settings file that bash and PowerShell both read.
- Behave the same in bash and PowerShell. Where a shell cannot do the same
  thing, say so in the README.
- Update with `git pull` and nothing else.
- Never overwrite or damage a startup file. Back it up, add one marked line.
- Uninstall cleanly, leaving only the backup and the saved names.
- Ship `cc` and `cx` with their agent safety checks ON. See ADR 0001.
- Prove itself with a test script per shell that needs no test tools, run on
  real Linux, macOS and Windows machines on every push.

## What it is not

- Not a dotfiles manager. It manages one line in one file.
- Not a record of Darren's full setup. That is `docs/ALIASES.md`, reference only.
- Not a place for anything machine specific, and never a place for a secret.

## Done looks like

`bash bash/test.sh` and `./powershell/test.ps1` pass on a clean machine, and a student who has never seen this
repo can read the README and be running `lsd` in under two minutes.
