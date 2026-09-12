# Alias wrappers on titan

Read from a live shell on 2026-09-12. 85 aliases, 24 hand-written functions.

## Where they come from

Three files load, in this order. Later wins on a name clash.

| Order | File | Loaded at | What it holds |
|---|---|---|---|
| 1 | `~/.claude/shell/shared-aliases.sh` | `.bashrc:146` | Portable set, same on every machine |
| 2 | `~/.config/shell/aliases.sh` | `.bashrc:156` | Modern tool swaps, git shortcuts, GitHub account switcher |
| 3 | `~/.bashrc` itself | inline | Host names, launchers, one-off shortcuts |

`.bashrc:156` calls file 2 "managed by `_alias_wrappers_init`". No such
function exists anywhere on this machine. The comment is a label, nothing more.

## Command swaps

These replace a standard command with a different program. The new program
does not take the same flags as the old one.

| Alias | Runs | Source |
|---|---|---|
| `ls` | `eza --icons --group-directories-first` | aliases.sh |
| `l` | `eza --icons --group-directories-first -la --git` | aliases.sh |
| `la` | `eza --icons --group-directories-first -a` | aliases.sh |
| `ll` | `eza --icons --group-directories-first -l --git` | aliases.sh |
| `lt` | `eza --icons --tree --level=2 --git-ignore` | aliases.sh |
| `llt` | `eza --icons --tree --level=3 --long --git-ignore` | aliases.sh |
| `cat` | `bat --paging=never` | aliases.sh |
| `less` | `bat` | aliases.sh |
| `grep` | `rg` | aliases.sh |
| `find` | `fd` | aliases.sh |
| `bat` | `batcat` | shared-aliases.sh |
| `fd` | `fdfind` | shared-aliases.sh |
| `egrep` | `egrep --color=auto` | .bashrc:84 |
| `fgrep` | `fgrep --color=auto` | .bashrc:83 |

`btop`, `dust` and `duf` are wired for `top`, `du` and `df` in aliases.sh but
none of the three is installed, so those three aliases never take effect.

Neither `bat` nor `fd` is installed under that name. Ubuntu ships them as
`batcat` and `fdfind`. The chain still works because `bat` and `fd` are
themselves aliases, set one file earlier, and bash re-reads the first word
after it swaps an alias. So `cat` becomes `bat --paging=never` becomes
`batcat --paging=never`.

## Safety nets

| Alias | Runs |
|---|---|
| `rm` | `rm -i` |
| `cp` | `cp -i` |
| `mv` | `mv -i` |
| `mkdir` | `mkdir -pv` |

## Claude Code and other agents

| Name | Kind | Runs |
|---|---|---|
| `cc` | function | `claude --dangerously-skip-permissions --remote-control` |
| `cct` | function | `cc` inside a tmux session named `claude`, reattaches after a drop |
| `ccc` | alias | same as `cc` |
| `cc46` | alias | `cc` pinned to `claude-opus-4-6` |
| `claude-hr` | alias | `headroom wrap claude` |
| `cx` | function | `codex` in the current folder, approvals and sandbox off |
| `pie` | function | `pi --model openrouter/z-ai/glm-5.1` |
| `oclaw` | function | `docker exec -it openclaw-gateway node openclaw.mjs` |
| `oc` | alias | OpenClaw TUI through docker compose. Not active on titan, see Warnings |

## Git

| Alias | Runs |
|---|---|
| `g` | `git` |
| `gs` | `git status -sb` |
| `ga` | `git add` |
| `gaa` | `git add --all` |
| `gc` | `git commit -m` |
| `gca` | `git commit --amend --no-edit` |
| `gco` | `git checkout` |
| `gcb` | `git checkout -b` |
| `gsw` | `git switch` |
| `gb` | `git branch` |
| `gp` | `git push` |
| `gpl` | `git pull` |
| `gd` | `git diff` |
| `gds` | `git diff --staged` |
| `gl` | `git log --oneline --graph --decorate --all -20` |
| `gll` | `git log --graph` with a colored one-line format |

## GitHub, two accounts

All functions, all in aliases.sh. `ghhelp` prints this same list.

| Name | What it does |
|---|---|
| `ghhelp` | Print the quick reference |
| `ghwho` | Show which account is active now |
| `ghpa` | Switch to `PowerAppsDarren` |
| `ghreal` | Switch to `darrenspl` |
| `ghsetup-real` | One time login for `darrenspl` plus SSH key upload |
| `ghtest` | Test SSH for both accounts |
| `ghclone <repo>` | Clone from `PowerAppsDarren` |
| `ghclone-real <repo>` | Clone from `darrenspl` |

## Hosts over SSH

Every one of these is set in `.bashrc`, which loads last, so it beats the
shorter forms in aliases.sh.

| Alias | Target |
|---|---|
| `alienware` | `alienware.tail719f76.ts.net` |
| `asgard` | `darren@asgard.tail719f76.ts.net` |
| `beast` | `beast.tail719f76.ts.net` |
| `brains` | `brains.tail719f76.ts.net` |
| `dellminipc01` | `dellminipc01.tail719f76.ts.net` |
| `donna` | `donna-prod.tail719f76.ts.net` |
| `melen100` | `melen100.tail719f76.ts.net` |
| `mew` | `mew.tail719f76.ts.net` |
| `mini` | `darrens-mac-mini.tail719f76.ts.net` |
| `pihole` | `pihole.tail719f76.ts.net` |
| `pool` | `pool.tail719f76.ts.net` |
| `pve` | `pve.tail719f76.ts.net` |
| `santa` | `santabook.tail719f76.ts.net` |
| `titan` | `titan.tail719f76.ts.net` |
| `utmb` | `darren@lpt-559774.tail719f76.ts.net` |

Three more come from aliases.sh and use bare short names, which depend on SSH
config or LAN DNS rather than Tailscale:

| Alias | Target |
|---|---|
| `lpt` | `darren@lpt-559774` |
| `mac-mini` | `darren@darrens-mac-mini` |
| `srv` | `darren@srv778271` |

## Project launchers

Each one changes folder and starts `cc`.

| Alias | Folder |
|---|---|
| `mark` | `~/src/clients/mark-kloch` |
| `template` | `~/src/ai-web-app-template` |
| `bananas` | `~/src/bananas` |
| `cf` | `~/src/canvas-forge` |
| `oem` | runs `~/src/canvas-forge-repos/cf-oemeyer-gas/oem` |
| `skillz` | runs the skill review tool in a subshell |
| `fleet` | `~/src/terminal-auto-session/bin/fleet.sh` |
| `recents` | `repo-recents top` |

## Task Master

`tm`, `taskmaster`, `hamster` and `ham` all run `task-master`. The first two
are set twice, once in shared-aliases.sh and again at `.bashrc:245`.

## Folders and files

| Name | Kind | What it does |
|---|---|---|
| `mkcd <dir>` | function | make the folder and cd into it |
| `mkdircd <dir>` | function | same thing |
| `new <dir>` | function | same thing |
| `ccd`, `cdd` | alias | both point at `mkdircd` |
| `lsd <word>` | function | list folders whose name holds that word, case does not matter |
| `extract <file>` | function | unpack any of 13 archive types |
| `..`, `...`, `....` | alias | go up one, two, three folders |
| `-` | alias | `cd -`, back to the last folder |

## Everything else

| Name | Kind | What it does |
|---|---|---|
| `c` | alias | `clear` |
| `lsa` | alias | `ls -la` |
| `update` | alias | `sudo apt update && sudo apt upgrade -y` |
| `reload` | alias | restart the shell in place |
| `path` | alias | print `PATH` one folder per line |
| `ports` | alias | list listening ports |
| `myip` | alias | print the public IP address |
| `weather` | alias | one-line forecast from wttr.in |
| `alert` | alias | desktop popup when the last command ends |
| `zshconfig` | alias | edit `~/.zshrc` |
| `ghosttyconfig` | alias | edit `~/.config/ghostty/config` |
| `starshipconfig` | alias | edit `~/.config/starship.toml` |
| `killnode` | function | kill every node process |
| `clip` | function | pipe stdin to the clipboard on whichever Mac answers |
| `work` | function | the titan project menu, with `pin` and `unpin` |

## Warnings

1. The `oc` alias in `~/.claude/shell/shared-aliases.sh` holds a plain
   OpenClaw token in the command line. It is gated on `~/src/compose-openclaw`,
   which does not exist on titan, so the alias never loads here. The token is
   still sitting in the file, and that file is committed to the
   `claude-config-titan` repo. The value is not copied here on purpose.
2. `grep` runs ripgrep, `find` runs fd, `cat` runs bat. None of the three
   takes the old flags. A script that assumes real `grep` will break if it
   ever runs with these aliases live. Aliases do not carry into scripts, so
   this bites only at the prompt.
3. `zshconfig` edits `~/.zshrc`, but this machine runs bash.
4. Three files set the same names. `l`, `ll`, `la`, `c`, `lsa`, `update`,
   `tm` and `taskmaster` are each defined two or three times.
