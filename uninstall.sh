#!/usr/bin/env bash
# Take the load line back out of your shell startup file.
# Your saved names stay, because PowerShell may still be using them.
set -uo pipefail

MARK="# >>> spl-alias-wrappers >>>"
END="# <<< spl-alias-wrappers <<<"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/spl-alias-wrappers/config"

removed=0
for RC in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.bash_login" "$HOME/.zshrc" "$HOME/.profile"; do
    [ -f "$RC" ] || continue
    grep -qF "$MARK" "$RC" || continue

    BACKUP="$RC.bak.$(date +%Y%m%d-%H%M%S)"
    cp "$RC" "$BACKUP" && echo "Backed up $RC to $BACKUP"

    # Drop every line from the start marker through the end marker.
    sed -i.tmp "\|^${MARK}\$|,\|^${END}\$|d" "$RC" && rm -f "$RC.tmp"
    echo "Removed the load line from $RC"
    removed=1
done

if [ "$removed" -eq 0 ]; then
    echo "Not installed for bash or zsh. Nothing to do."
else
    echo
    echo "Open a new terminal, and the shortcuts are gone."
fi

if [ -f "$CONF" ]; then
    echo "Your saved names are still in $CONF."
    echo "Delete that file once you are done with both bash and PowerShell."
fi
