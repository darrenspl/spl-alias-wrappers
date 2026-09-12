#!/usr/bin/env bash
# Add one line to your shell startup file so these shortcuts load every time.
# Safe to run twice. It backs up your file and never writes the same line twice.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO/aliases.sh"
MARK="# >>> spl-alias-wrappers >>>"
END="# <<< spl-alias-wrappers <<<"

[ -f "$SRC" ] || { echo "install: cannot find $SRC" >&2; exit 1; }

# Pick the startup file that your shell actually reads.
case "${SHELL##*/}" in
    zsh)  RC="$HOME/.zshrc" ;;
    bash) RC="$HOME/.bashrc" ;;
    *)    RC="$HOME/.profile"
          echo "install: shell is '${SHELL##*/}', falling back to $RC" ;;
esac

# macOS bash reads .bash_profile for a login shell, .bashrc often is not read.
if [ "${SHELL##*/}" = "bash" ] && [ "$(uname -s)" = "Darwin" ]; then
    RC="$HOME/.bash_profile"
fi

touch "$RC"

if grep -qF "$MARK" "$RC"; then
    echo "Already installed in $RC. Nothing to do."
    echo "Run 'git pull' in $REPO to get the newest shortcuts."
    exit 0
fi

BACKUP="$RC.bak.$(date +%Y%m%d-%H%M%S)"
cp "$RC" "$BACKUP" && echo "Backed up $RC to $BACKUP"

{
    printf '\n%s\n' "$MARK"
    printf '# Five shortcuts: lsa c lsd cc cx. Remove with %s/uninstall.sh\n' "$REPO"
    printf '[ -f "%s" ] && . "%s"\n' "$SRC" "$SRC"
    printf '%s\n' "$END"
} >> "$RC" || { echo "install: could not write to $RC" >&2; exit 1; }

echo "Added the load line to $RC"
echo
echo "Start using them now:   . $SRC"
echo "Or open a new terminal."
echo
echo "Shortcuts: lsa (list all)  c (clear)  lsd <word> (find folder)"
echo "           cc (Claude Code)  cx (Codex)"
echo
echo "cc and cx keep their safety check ON. Read the SAFETY note in aliases.sh"
echo "before you set SPL_YOLO=1."
