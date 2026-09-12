#!/usr/bin/env bash
# Take the load line back out of your shell startup file.
set -uo pipefail

MARK="# >>> spl-alias-wrappers >>>"
END="# <<< spl-alias-wrappers <<<"

removed=0
for RC in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zshrc" "$HOME/.profile"; do
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
    echo "Not installed in any startup file. Nothing to do."
    exit 0
fi

echo
echo "Open a new terminal, or run: unset SPL_ALIAS_WRAPPERS_LOADED"
