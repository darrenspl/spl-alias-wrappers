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

- Install with one clone and one script, on Linux, WSL2 and macOS, in bash or zsh.
- Update with `git pull` and nothing else.
- Never overwrite or damage a startup file. Back it up, add one marked line.
- Uninstall cleanly, leaving no trace but the backup.
- Ship `cc` and `cx` with their agent safety checks ON. See ADR 0001.
- Prove itself with a test script that needs no test tools.

## What it is not

- Not a dotfiles manager. It manages one line in one file.
- Not a record of Darren's full setup. That is `docs/ALIASES.md`, reference only.
- Not a place for anything machine specific, and never a place for a secret.

## Done looks like

`./test.sh` passes on a clean machine, and a student who has never seen this
repo can read the README and be running `lsd` in under two minutes.
