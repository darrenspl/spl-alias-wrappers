# spl-alias-wrappers

Five shell shortcuts I use every day. This repo is how I put them on a new
machine, and how you can put them on yours.

Works in bash and zsh, on Linux, WSL2 and macOS.

## The five

| Type this | And you get |
|---|---|
| `lsa` | every file in this folder, hidden ones too |
| `c` | a clear screen |
| `lsd <word>` | every folder here whose name holds that word |
| `cc` | Claude Code |
| `cx` | OpenAI Codex |

## Install

```bash
git clone https://github.com/darrenspl/spl-alias-wrappers.git ~/src/spl-alias-wrappers
cd ~/src/spl-alias-wrappers
./install.sh
```

Then open a new terminal, or run `. ~/src/spl-alias-wrappers/aliases.sh` to
start using them right now.

`install.sh` backs up your startup file first, then adds one line to it. Run it
twice and it tells you it is already done. It changes nothing else.

## Update

```bash
cd ~/src/spl-alias-wrappers && git pull
```

That is the whole update. The startup line points at this folder, so every new
shell picks up the change. There is no second install step.

## Remove

```bash
cd ~/src/spl-alias-wrappers && ./uninstall.sh
```

It backs up your startup file, takes the one line back out, and leaves the rest
of your setup alone.

## Check that it works

```bash
./test.sh
```

Thirteen checks, one line each. It needs no test tools, just bash.

---

## What each one does

### `lsa`

```
lsa
```

Short for `ls -la`. Lists every file in the folder you are standing in,
including the hidden ones that start with a dot, with size and date.

### `c`

```
c
```

Short for `clear`. Wipes the screen. One keystroke instead of five.

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
in a folder with hundreds of projects.

Say nothing and it prints how to use it. Match nothing and it says so.

**Name clash.** `lsd` is also a real program, an `ls` replacement with colors,
in the Ubuntu and Homebrew package lists. If you install that program, this
shortcut hides it. Rename the function in `aliases.sh` if you want both.

### `cc`

```
cc
```

Starts Claude Code in the folder you are standing in.

**Name clash, and this one matters.** `cc` is the old Unix name for the C
compiler, and `/usr/bin/cc` exists on nearly every Linux box. This shortcut
hides it. If you compile C, `cc hello.c` will start Claude Code instead of
building your program. Use `gcc` or `clang` directly, or rename this one.

### `cx`

```
cx
```

Starts OpenAI Codex in the folder you are standing in.

---

## Safety, please read this part

Both Claude Code and Codex can be told to stop asking before they run a
command. That question is the thing that stops an agent from deleting work you
wanted to keep.

**These shortcuts leave the question ON.** That is the whole point of shipping
them this way. You get the short name without giving up the guard rail.

If you want it off, you turn it off yourself, on purpose. Put this line in your
own startup file, above the line `install.sh` added:

```bash
export SPL_YOLO=1
```

Now `cc` and `cx` will run anything without asking you first.

Do that only on a machine where that is fine with you. A spare box, a throwaway
virtual machine, a container you can rebuild in a minute. Never on a work
laptop. Never on a machine other people share.

I run it that way on my own machines. I am telling you what it costs so you can
make your own call.

---

## Why one file and not five

Five shortcuts is about thirty lines of shell. A folder for each one would give
you five README files to keep in step and five ways to end up half installed.
One file, one load line, one `git pull` to update.

If one of these ever grows into a real program with its own options and its own
tests, it earns its own folder that day.

## The bigger list

`docs/ALIASES.md` holds every alias and function on my main workstation, about a
hundred of them, and which file sets each one. That file is a record of my
setup, not something to install.

## License

MIT. See `LICENSE`. Use these, change them, teach them, sell a course with them.
