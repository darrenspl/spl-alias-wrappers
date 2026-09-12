# spl-alias-wrappers

[![test](https://github.com/darrenspl/spl-alias-wrappers/actions/workflows/test.yml/badge.svg)](https://github.com/darrenspl/spl-alias-wrappers/actions/workflows/test.yml)

Five shell shortcuts I use every day. This repo is how I put them on a new
machine, and how you can put them on yours.

Works in bash, zsh and PowerShell, on Linux, macOS and Windows.

## The five

| Type this | And you get |
|---|---|
| `lsa` | every file in this folder, hidden ones too |
| `c` | a clear screen |
| `lsd <word>` | every folder here whose name holds that word |
| `cc` | Claude Code |
| `cx` | OpenAI Codex |

## Install

### macOS, Linux, WSL2 or Git Bash

```bash
git clone https://github.com/darrenspl/spl-alias-wrappers.git ~/src/spl-alias-wrappers
cd ~/src/spl-alias-wrappers
bash install.sh
```

### Windows PowerShell or PowerShell 7

```powershell
git clone https://github.com/darrenspl/spl-alias-wrappers.git $HOME/src/spl-alias-wrappers
cd $HOME/src/spl-alias-wrappers
powershell -ExecutionPolicy Bypass -File install.ps1
```

Using PowerShell 7? Start it with `pwsh` in place of `powershell`. Windows
PowerShell and PowerShell 7 each keep their own profile, so run the installer
once from each one you use.

`-ExecutionPolicy Bypass` lets the installer itself run on a fresh Windows
computer, where scripts are blocked out of the box. If your account still
blocks scripts when a new window opens, the installer tells you, shows the
usual fix, and asks before it changes anything.

### What the installer does

It shows the five shortcuts and asks one question: do you want to change a
name, or leave one out? Say no and you are done. Say yes and it walks through
each one. Press Enter to keep a name, type a new one, or type `-` to skip that
shortcut. If a name you pick is already a program on your computer, it tells you
which one and asks before hiding it.

Then open a new terminal.

It touches two things, and nothing else:

- **Your startup file** gets one load line. That is `~/.bashrc` or
  `~/.bash_profile` for bash, `~/.zshrc` for zsh, and your profile for
  PowerShell. It backs the file up first, and never adds the line twice.
- **Your choices** go in `~/.config/spl-alias-wrappers/config`. That file lives
  outside the repo, so `git pull` never undoes them. Bash and PowerShell both
  read it, so Git Bash and PowerShell on the same Windows computer agree.
  WSL2 has its own home folder, so install there on its own.

To set it up with no questions, say on a fresh virtual machine:

```bash
bash install.sh --no-prompt
```

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1 -NoPrompt
```

## Change a name later

Run the installer again and answer yes. Or open
`~/.config/spl-alias-wrappers/config`, change the name after the `=`, and open a
new terminal:

```
lsa=lsa
c=c
lsd=folders
cc=cl
cx=
yolo=0
```

An empty name, like `cx=` above, leaves that shortcut out.

## Update

```bash
cd ~/src/spl-alias-wrappers && git pull
```

That is the whole update, for every shell. The load line points at this folder,
so every new terminal picks up the change.

## Remove

```bash
bash uninstall.sh
```

```powershell
powershell -ExecutionPolicy Bypass -File uninstall.ps1
```

Each one backs up your startup file, takes the load line back out, and leaves
the rest of your setup alone. Your saved names stay, in case the other shell
still uses them. Delete `~/.config/spl-alias-wrappers` when you are done with
both.

## Check that it works

```bash
bash test.sh
```

```powershell
./test.ps1
```

`test.sh` runs 30 checks in bash, plus 6 more in zsh when zsh is installed.
`test.ps1` runs 33 checks. Neither needs test tools, and every check runs in a
throwaway folder, so it never touches your own setup.

Every push runs both on real Linux, macOS and Windows machines, including
Windows PowerShell 5.1 and Git Bash. The badge at the top shows the last result.

---

## What each one does

### `lsa`

Lists every file in the folder you are standing in, including hidden ones, with
size and date. In bash and zsh it is `ls -la`. In PowerShell it is
`Get-ChildItem -Force`.

### `c`

Clears the screen. `clear` in bash and zsh, `Clear-Host` in PowerShell. One
keystroke instead of five.

### `lsd <word>`

```
lsd plane
```

```
plane-api
Planeboard
my-plane-notes
```

Lists folders in the current directory whose name holds that word. Upper and
lower case do not matter. It looks one level down, no deeper, so it stays fast
in a folder with hundreds of projects. Say nothing and it shows how to use it.
Match nothing and it says so.

**Name clash on macOS and Linux.** `lsd` is also a real program, an `ls`
replacement with colors, in the Ubuntu and Homebrew package lists. If you
install that program, this shortcut hides it. Run the installer and give this
one a different name if you want both.

### `cc`

Starts Claude Code in the folder you are standing in. If Claude Code is not
installed yet, it says so and shows where to get it.

**Name clash on macOS and Linux, and this one matters.** `cc` is the old Unix
name for the C compiler, and `/usr/bin/cc` exists on nearly every Linux box.
This shortcut hides it. If you compile C, `cc hello.c` will start Claude Code
instead of building your program. The installer warns you about this one and
offers to rename it. `cl` is free on most machines. Windows has no `cc`, so
PowerShell users can ignore this.

### `cx`

Starts OpenAI Codex in the folder you are standing in. Same "not installed"
message as `cc`.

---

## Safety, please read this part

Both Claude Code and Codex can be told to stop asking before they run a
command. That question is the thing that stops an agent from deleting work you
wanted to keep.

**These shortcuts leave the question ON.** That is the whole point of shipping
them this way. You get the short name without giving up the guard rail.

If you want it off, you turn it off yourself, on purpose. Run the installer, say
yes to changing names, and answer yes when it asks about the safety check. Or
set `yolo=1` in `~/.config/spl-alias-wrappers/config`. In bash and zsh,
`export SPL_YOLO=1` above the load line works too.

Now `cc` and `cx` will run anything without asking you first.

Do that only on a machine where that is fine with you. A spare box, a throwaway
virtual machine, a container you can rebuild in a minute. Never on a work
laptop. Never on a machine other people share.

I run it that way on my own machines. I am telling you what it costs so you can
make your own call.

---

## What is in here

| File | What it is |
|---|---|
| `aliases.sh` | the five shortcuts for bash and zsh |
| `aliases.ps1` | the same five for PowerShell |
| `install.sh`, `install.ps1` | ask about names, save them, add the load line |
| `uninstall.sh`, `uninstall.ps1` | take the load line back out |
| `test.sh`, `test.ps1` | the checks |
| `.gitattributes` | keeps every file on LF line endings, even on Windows |
| `.github/workflows/test.yml` | runs both checks on Linux, macOS and Windows |

## Why two versions

Bash cannot run inside plain PowerShell, and a lot of Windows users never leave
PowerShell. So each shortcut is written twice, once per shell. The two stay in
step three ways: they read the same settings file, they check the same
behavior, and every push tests both on all three operating systems. Details in
`docs/adr/0002-ship-a-powershell-version.md`.

Five shortcuts is still small enough to read every line of both in a few
minutes. If one ever grows into a real program with its own options and tests,
it earns its own folder that day.

## The bigger list

`docs/ALIASES.md` holds every alias and function on my main workstation, about a
hundred of them, and which file sets each one. That file is a record of my
setup, not something to install.

## License

MIT. See `LICENSE`. Use these, change them, teach them, sell a course with them.
