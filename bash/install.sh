#!/usr/bin/env bash
# Install the five shortcuts for bash or zsh, and ask whether you want other names.
#
#   bash bash/install.sh               asks a few questions, Enter keeps what is shown
#   bash bash/install.sh --no-prompt   no questions, keeps saved choices or the defaults
#
# Safe to run again. Run it again any time to change a name.
# Using PowerShell? Run powershell/install.ps1 instead. Both read the same saved names.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO/aliases.sh"
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/spl-alias-wrappers"
CONF="$CONF_DIR/config"
MARK="# >>> spl-alias-wrappers >>>"
END="# <<< spl-alias-wrappers <<<"

ASK=1
case "${1:-}" in
    "")          ;;
    --no-prompt) ASK=0 ;;
    -h|--help)   sed -n '2,9p' "$0"; exit 0 ;;
    *)           echo "install: unknown option '$1'. Try --help." >&2; exit 2 ;;
esac

[ -f "$SRC" ] || { echo "install: cannot find $SRC" >&2; exit 1; }

KEYS=(lsa c lsd cc cx)
WHAT=("list every file, hidden ones too" "clear the screen" "find folders by name"
      "start Claude Code" "start OpenAI Codex")

# ── Start from the last run's choices, or the defaults ─────────────────────
NAMES=(lsa c lsd cc cx)
YOLO=0
if [ -f "$CONF" ]; then
    while IFS='=' read -r key value || [ -n "$key" ]; do
        value="${value%$'\r'}"
        for i in "${!KEYS[@]}"; do
            if [ "$key" = "${KEYS[i]}" ]; then NAMES[i]="$value"; fi
        done
        if [ "$key" = yolo ] && [ "$value" = 1 ]; then YOLO=1; fi
    done < "$CONF"
fi

# ── Small helpers ───────────────────────────────────────────────────────────
# ask <prompt>: reads one line into REPLY. At end of input it stops asking and
# every later question keeps what is shown, so piping in answers never hangs.
ask() {
    REPLY=""
    [ "$ASK" = 1 ] || return 1
    printf '%s' "$1" >&2
    IFS= read -r REPLY || { ASK=0; REPLY=""; echo >&2; return 1; }
    REPLY="${REPLY%$'\r'}"
}
yesno() { ask "$1 [y/N] " && [[ "$REPLY" =~ ^[Yy] ]]; }

valid() { [[ "$1" =~ ^[A-Za-z][A-Za-z0-9_-]*$ ]]; }

# taken <name> <index>: true when another shortcut already has this name.
taken() {
    local j
    for j in "${!NAMES[@]}"; do
        [ "$j" != "$2" ] && [ "${NAMES[j]}" = "$1" ] && return 0
    done
    return 1
}

# clash <name>: say what on this machine already answers to this name.
clash() {
    case "$(type -t "$1" 2>/dev/null)" in
        file)    printf 'the program %s' "$(type -P "$1")" ;;
        builtin) printf 'a command built into the shell' ;;
        keyword) printf 'a word the shell reserves' ;;
    esac
}

show() {
    local i
    for i in "${!KEYS[@]}"; do
        printf '  %-10s %s\n' "${NAMES[i]:-(off)}" "${WHAT[i]}"
    done
}

# ── Questions ───────────────────────────────────────────────────────────────
echo
echo "spl-alias-wrappers"
echo
echo "These shortcuts will be set up:"
show
echo

if yesno "Change a name, or leave one out?"; then
    echo
    echo "Press Enter to keep the name shown. Type - to leave that shortcut out."
    for i in "${!KEYS[@]}"; do
        while :; do
            ask "  ${WHAT[i]} [${NAMES[i]:--}]: "
            case "$REPLY" in
                "") new="${NAMES[i]}" ;;
                -)  new="" ;;
                *)  new="$REPLY" ;;
            esac
            if [ -z "$new" ]; then NAMES[i]=""; break; fi

            if ! valid "$new"; then
                echo "    '$new' will not work. Start with a letter, then letters, numbers, - or _." >&2
                [ "$ASK" = 1 ] && continue
                NAMES[i]=""; break
            fi
            if taken "$new" "$i"; then
                echo "    '$new' is already the name for another shortcut." >&2
                [ "$ASK" = 1 ] && continue
                NAMES[i]=""; break
            fi
            used=$(clash "$new")
            if [ -n "$used" ]; then
                if ! yesno "    '$new' is already $used. Your shortcut would hide it. Use it anyway?"; then
                    [ "$ASK" = 1 ] && continue
                fi
            fi
            NAMES[i]="$new"; break
        done
    done

    if [ -n "${NAMES[3]}${NAMES[4]}" ]; then
        echo
        echo "Claude Code and Codex stop and ask you before they run a command."
        echo "That check is what keeps an agent from deleting work you wanted."
        echo "You can turn it off. Only do that on a machine you could wipe tomorrow."
        if yesno "Turn the safety check OFF?"; then YOLO=1; else YOLO=0; fi
    fi
fi

# ── Save the choices ────────────────────────────────────────────────────────
mkdir -p "$CONF_DIR" || { echo "install: could not create $CONF_DIR" >&2; exit 1; }
{
    echo "# spl-alias-wrappers settings, written by install.sh on $(date +%Y-%m-%d)."
    echo "# One shortcut per line: shortcut=the name you type. An empty name leaves"
    echo "# that shortcut out. yolo=1 turns OFF the safety check for Claude Code and"
    echo "# Codex. Bash and PowerShell both read this file. Open a new terminal after"
    echo "# you change it."
    for i in "${!KEYS[@]}"; do
        printf '%s=%s\n' "${KEYS[i]}" "${NAMES[i]}"
    done
    printf 'yolo=%s\n' "$YOLO"
} > "$CONF.new"
if ! mv "$CONF.new" "$CONF"; then
    echo "install: could not write $CONF" >&2
    exit 1
fi

# ── Add the load line to the startup file your shell reads ──────────────────
case "${SHELL##*/}" in
    zsh)  RC="$HOME/.zshrc" ;;
    bash) RC="$HOME/.bashrc" ;;
    *)    RC="$HOME/.profile" ;;
esac
# macOS Terminal and Git Bash on Windows open a login shell. Bash reads only the
# first of these three files that exists, so write to that one. Making a new
# .bash_profile would quietly stop an existing .profile from loading.
if [ "${SHELL##*/}" = bash ]; then
    case "$(uname -s)" in
        Darwin|MINGW*|MSYS*|CYGWIN*)
            RC="$HOME/.bash_profile"
            for f in .bash_profile .bash_login .profile; do
                if [ -f "$HOME/$f" ]; then RC="$HOME/$f"; break; fi
            done ;;
    esac
fi

touch "$RC" || { echo "install: cannot write to $RC" >&2; exit 1; }
if grep -qF "$MARK" "$RC"; then
    added="already there"
else
    BACKUP="$RC.bak.$(date +%Y%m%d-%H%M%S)"
    cp "$RC" "$BACKUP" || { echo "install: could not back up $RC" >&2; exit 1; }
    {
        printf '\n%s\n' "$MARK"
        printf '# Shortcuts from %s. Remove with: bash %s/uninstall.sh\n' "$REPO" "$REPO"
        printf '[ -f "%s" ] && . "%s"\n' "$SRC" "$SRC"
        printf '%s\n' "$END"
    } >> "$RC" || { echo "install: could not write to $RC" >&2; exit 1; }
    added="added, old copy saved as $BACKUP"
fi

# ── Report ──────────────────────────────────────────────────────────────────
echo
echo "Done."
echo "  Load line in $RC: $added"
echo "  Your names saved in $CONF"
echo
show
for i in "${!KEYS[@]}"; do
    [ -n "${NAMES[i]}" ] || continue
    used=$(clash "${NAMES[i]}")
    [ -n "$used" ] && echo "  Note: '${NAMES[i]}' hides $used. Run install.sh again to rename it."
done
echo
if [ "$YOLO" = 1 ]; then
    echo "  Safety check is OFF for Claude Code and Codex."
else
    echo "  Safety check is ON for Claude Code and Codex."
fi
echo
echo "Open a new terminal to start using them."
