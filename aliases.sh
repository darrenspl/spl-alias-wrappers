# shellcheck shell=bash
# spl-alias-wrappers  ·  https://github.com/darrenspl/spl-alias-wrappers
#
# Five shortcuts. Works in bash and zsh, on Linux, WSL2 and macOS.
# Install:  ./install.sh      Remove:  ./uninstall.sh      Check:  ./test.sh
#
# The names are yours to change. install.sh saves your choices in
# ~/.config/spl-alias-wrappers/config.sh. That file lives outside this repo,
# so a git pull never undoes them.
#
# Nothing here is machine specific and nothing here holds a secret.

# Load once per shell, even if something sources this file twice.
[ -n "${SPL_ALIAS_WRAPPERS_LOADED:-}" ] && return 0
SPL_ALIAS_WRAPPERS_LOADED=1

SPL_ALIAS_WRAPPERS_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/spl-alias-wrappers/config.sh"
# shellcheck disable=SC1090
[ -f "$SPL_ALIAS_WRAPPERS_CONFIG" ] && . "$SPL_ALIAS_WRAPPERS_CONFIG"


# ── What each shortcut does ─────────────────────────────────────────────────
# lsa and c are plain aliases, set at the bottom. The other three call these.

# lsd <word>: list folders whose name holds <word>, case ignored.
#   lsd plane   shows  plane-api  Planeboard  my-plane-notes
_spl_lsd() {
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

# cc starts Claude Code. cx starts OpenAI Codex.
#
# SAFETY. Both tools can turn off the check that asks you before they run a
# command. That check is the thing that stops an agent from deleting a folder
# you wanted. These wrappers leave it ON.
#
# To turn it off, you opt in on purpose: answer yes when install.sh asks, or
# put `export SPL_YOLO=1` in your own rc file ABOVE the line that sources this
# one. Do that only on a machine where you are fine with an agent running
# anything without asking. Never on a work laptop, never on a shared box.
if [ "${SPL_YOLO:-0}" = "1" ]; then
    _spl_cc() { claude --dangerously-skip-permissions "$@"; }
    _spl_cx() { codex  --cd "$(pwd)" --dangerously-bypass-approvals-and-sandbox "$@"; }
else
    _spl_cc() { claude "$@"; }
    _spl_cx() { codex --cd "$(pwd)" "$@"; }
fi

# Say so plainly if the tool behind the shortcut is not installed yet.
command -v claude >/dev/null 2>&1 || \
    _spl_cc() { echo "Claude Code is not installed. See https://claude.com/claude-code" >&2; return 127; }
command -v codex >/dev/null 2>&1 || \
    _spl_cx() { echo "Codex is not installed. See https://developers.openai.com/codex" >&2; return 127; }


# ── The names ───────────────────────────────────────────────────────────────
# A name that is not set gets the default. A name set to empty is left out.

# True when the name is safe to define. Clears any alias in the way, because an
# interactive shell swaps aliases while it reads a function definition.
_spl_name() {
    [ -n "$1" ] || return 1
    case "$1" in
        [!A-Za-z]*|*[!A-Za-z0-9_-]*)
            echo "spl-alias-wrappers: '$1' is not a usable name, skipped it" >&2
            return 1 ;;
    esac
    unalias "$1" 2>/dev/null
    return 0
}

_spl_name "${SPL_NAME_LSA-lsa}" && alias "${SPL_NAME_LSA-lsa}=ls -la"
_spl_name "${SPL_NAME_C-c}"     && alias "${SPL_NAME_C-c}=clear"
_spl_name "${SPL_NAME_LSD-lsd}" && eval "${SPL_NAME_LSD-lsd}() { _spl_lsd \"\$@\"; }"
_spl_name "${SPL_NAME_CC-cc}"   && eval "${SPL_NAME_CC-cc}() { _spl_cc \"\$@\"; }"
_spl_name "${SPL_NAME_CX-cx}"   && eval "${SPL_NAME_CX-cx}() { _spl_cx \"\$@\"; }"
