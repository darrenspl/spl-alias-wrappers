# shellcheck shell=bash
# spl-alias-wrappers  ·  https://github.com/darrenspl/spl-alias-wrappers
#
# Five shortcuts for bash and zsh, on Linux, macOS, WSL2 and Git Bash.
# Using PowerShell? powershell/aliases.ps1 is the same five shortcuts.
#
# From the repo folder:
#   Install:  bash bash/install.sh   Remove:  bash bash/uninstall.sh   Check:  bash bash/test.sh
#
# The names are yours to change. install.sh saves them in
# ~/.config/spl-alias-wrappers/config, a plain name=value file that lives
# outside this repo, so a git pull never undoes them. powershell/aliases.ps1
# reads the same file.
#
# Nothing here is machine specific and nothing here holds a secret.

# Load once per shell, even if something sources this file twice.
[ -n "${SPL_ALIAS_WRAPPERS_LOADED:-}" ] && return 0
SPL_ALIAS_WRAPPERS_LOADED=1


# ── Saved settings ──────────────────────────────────────────────────────────
# Read line by line and never run as code, so a bad line is simply ignored.
_spl_n_lsa=lsa _spl_n_c=c _spl_n_lsd=lsd _spl_n_cc=cc _spl_n_cx=cx
_spl_yolo="${SPL_YOLO:-0}"
_spl_conf="${XDG_CONFIG_HOME:-$HOME/.config}/spl-alias-wrappers/config"
if [ -f "$_spl_conf" ]; then
    while IFS='=' read -r _spl_k _spl_v || [ -n "$_spl_k" ]; do
        _spl_v="${_spl_v%$'\r'}"    # a file saved on Windows can end lines in CR
        case "$_spl_k" in
            lsa|c|lsd|cc|cx) eval "_spl_n_$_spl_k=\$_spl_v" ;;
            yolo)            [ "$_spl_v" = 1 ] && _spl_yolo=1 ;;
        esac
    done < "$_spl_conf"
fi


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

# _spl_need <program> <label> <link>: true when the program is installed.
# Checked each time, so a tool installed after the shell opened just works.
_spl_need() {
    command -v "$1" >/dev/null 2>&1 && return 0
    echo "$2 is not installed. See $3" >&2
    return 127
}

# cc starts Claude Code. cx starts OpenAI Codex.
#
# SAFETY. Both tools can turn off the check that asks you before they run a
# command. That check is the thing that stops an agent from deleting a folder
# you wanted. These wrappers leave it ON.
#
# To turn it off, you opt in on purpose: answer yes when install.sh asks, or
# set yolo=1 in the settings file, or `export SPL_YOLO=1` above the line that
# loads this file. Do that only on a machine where you are fine with an agent
# running anything without asking. Never on a work laptop, never on a shared box.
#
# `command` skips shell functions, so naming a shortcut "claude" cannot loop.
if [ "$_spl_yolo" = 1 ]; then
    _spl_cc() {
        _spl_need claude "Claude Code" https://claude.com/claude-code || return
        command claude --dangerously-skip-permissions "$@"
    }
    _spl_cx() {
        _spl_need codex Codex https://developers.openai.com/codex || return
        command codex --cd "$(pwd)" --dangerously-bypass-approvals-and-sandbox "$@"
    }
else
    _spl_cc() {
        _spl_need claude "Claude Code" https://claude.com/claude-code || return
        command claude "$@"
    }
    _spl_cx() {
        _spl_need codex Codex https://developers.openai.com/codex || return
        command codex --cd "$(pwd)" "$@"
    }
fi


# ── The names ───────────────────────────────────────────────────────────────
# An empty name leaves that shortcut out.

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

# The name expands now, on purpose: it is the name being defined.
# shellcheck disable=SC2139
_spl_name "$_spl_n_lsa" && alias "$_spl_n_lsa=ls -la"
# shellcheck disable=SC2139
_spl_name "$_spl_n_c"   && alias "$_spl_n_c=clear"
_spl_name "$_spl_n_lsd" && eval "$_spl_n_lsd() { _spl_lsd \"\$@\"; }"
_spl_name "$_spl_n_cc"  && eval "$_spl_n_cc() { _spl_cc \"\$@\"; }"
_spl_name "$_spl_n_cx"  && eval "$_spl_n_cx() { _spl_cx \"\$@\"; }"

unset _spl_n_lsa _spl_n_c _spl_n_lsd _spl_n_cc _spl_n_cx _spl_yolo _spl_conf _spl_k _spl_v
