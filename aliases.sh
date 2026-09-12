# shellcheck shell=bash
# spl-alias-wrappers  ·  https://github.com/darrenspl/spl-alias-wrappers
#
# Five shortcuts. Works in bash and zsh, on Linux, WSL2 and macOS.
# Install:  ./install.sh      Remove:  ./uninstall.sh      Check:  ./test.sh
#
# Nothing here is machine specific and nothing here holds a secret.

# Load once per shell, even if something sources this file twice.
[ -n "${SPL_ALIAS_WRAPPERS_LOADED:-}" ] && return 0
SPL_ALIAS_WRAPPERS_LOADED=1

# An interactive shell swaps aliases while it is still reading a function
# definition. If a name below is already an alias, the function that follows
# it will not parse. Clear the names first so these always win.
unalias lsa c lsd cc cx 2>/dev/null || true


# ── lsa ── list everything in this folder, including dotfiles ────────────────
alias lsa='ls -la'


# ── c ── clear the screen ───────────────────────────────────────────────────
alias c='clear'


# ── lsd <word> ── list folders whose name holds <word>, case ignored ────────
# lsd plane   shows  plane-api/  Planeboard/  my-plane-notes/
lsd() {
    if [ -z "${1:-}" ]; then
        echo "usage: lsd <word>" >&2
        return 2
    fi
    # `command` on purpose. Plenty of people alias find to fd, and a function
    # must not change behavior based on what else the user has set up.
    # -L follows a symlink that points at a folder, the way `ls -d */` does.
    # -iname is case insensitive on both GNU find and the BSD find on macOS.
    local hits
    hits=$(command find -L . -maxdepth 1 -mindepth 1 -type d -iname "*$1*" 2>/dev/null \
           | command sed 's|^\./||' | command sort)
    if [ -z "$hits" ]; then
        echo "no folder matches '$1'" >&2
        return 1
    fi
    printf '%s\n' "$hits"
}


# ── cc ── Claude Code ───────────────────────────────────────────────────────
# ── cx ── OpenAI Codex ──────────────────────────────────────────────────────
#
# SAFETY. Both tools can turn off the check that asks you before they run a
# command. That check is the thing that stops an agent from deleting a folder
# you wanted. These wrappers leave it ON.
#
# To turn it off, you are opting in on purpose. Put this in your own rc file,
# ABOVE the line that sources this one:
#
#     export SPL_YOLO=1
#
# Do that only on a machine where you are fine with an agent running anything
# without asking. Never on a work laptop, never on a shared box.

if [ "${SPL_YOLO:-0}" = "1" ]; then
    cc() { claude --dangerously-skip-permissions "$@"; }
    cx() { codex  --cd "$(pwd)" --dangerously-bypass-approvals-and-sandbox "$@"; }
else
    cc() { claude "$@"; }
    cx() { codex --cd "$(pwd)" "$@"; }
fi

# Say so plainly if the tool behind the shortcut is not installed yet.
command -v claude >/dev/null 2>&1 || \
    cc() { echo "cc: Claude Code is not installed. See https://claude.com/claude-code" >&2; return 127; }
command -v codex >/dev/null 2>&1 || \
    cx() { echo "cx: Codex is not installed. See https://developers.openai.com/codex" >&2; return 127; }
