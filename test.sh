#!/usr/bin/env bash
# Check that the shortcuts load, behave, and install cleanly. No test tools.
# Run it: ./test.sh     Prints one line per check, exits 1 on any failure.
#
# Every check runs in a fresh shell with no startup file and a throwaway home
# folder, so nothing on your own machine is read or changed.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO/aliases.sh"
SANDBOX=$(mktemp -d) || exit 1
trap 'rm -rf "$SANDBOX"' EXIT
pass=0; fail=0

check() {  # check <what> <want> <got>
    if [ "$2" = "$3" ]; then
        printf 'ok    %s\n' "$1"; pass=$((pass+1))
    else
        printf 'FAIL  %s\n        want: %s\n        got:  %s\n' "$1" "$2" "$3"
        fail=$((fail+1))
    fi
}

# run <config file contents> <snippet>: fresh interactive bash, no rc file,
# the given saved settings, aliases.sh loaded, then the snippet.
run() {
    local home="$SANDBOX/run.$RANDOM$RANDOM"
    mkdir -p "$home/.config/spl-alias-wrappers"
    [ -n "$1" ] && printf '%s\n' "$1" > "$home/.config/spl-alias-wrappers/config.sh"
    env -u SPL_YOLO HOME="$home" XDG_CONFIG_HOME="$home/.config" \
        bash --norc -ic ". '$SRC' >/dev/null 2>&1
$2" 2>/dev/null
}

# ── Default names ───────────────────────────────────────────────────────────
check "lsa is an alias for ls -la" "alias lsa='ls -la'" "$(run '' 'alias lsa')"
check "c is an alias for clear"    "alias c='clear'"    "$(run '' 'alias c')"
for fn in lsd cc cx; do
    check "$fn is a function" "function" "$(run '' "type -t $fn")"
done

# ── lsd ─────────────────────────────────────────────────────────────────────
dirs="$SANDBOX/dirs" && mkdir -p "$dirs/PlaneNotes" "$dirs/other"
check "lsd matches ignoring case" "PlaneNotes" "$(run '' "cd '$dirs' && lsd plane")"
check "lsd exits 1 on no match"   "1" "$(run '' "cd '$dirs' && lsd zzzz >/dev/null 2>&1; echo \$?")"
check "lsd exits 2 with no word"  "2" "$(run '' 'lsd >/dev/null 2>&1; echo $?')"
check "lsd still works when find is aliased to something else" "PlaneNotes" \
      "$(env -u SPL_YOLO HOME="$SANDBOX" bash --norc -ic "alias find='echo broken'
. '$SRC' >/dev/null 2>&1
cd '$dirs' && lsd plane" 2>/dev/null)"

# ── Safety ──────────────────────────────────────────────────────────────────
check "cc is safe by default" "" \
      "$(run '' 'declare -f _spl_cc' | grep -o 'dangerously-skip-permissions')"
check "cx is safe by default" "" \
      "$(run '' 'declare -f _spl_cx' | grep -o 'dangerously-bypass-approvals-and-sandbox')"
check "SPL_YOLO=1 in settings turns cc loose" "dangerously-skip-permissions" \
      "$(run 'SPL_YOLO=1' 'declare -f _spl_cc' | grep -o 'dangerously-skip-permissions')"
check "SPL_YOLO=1 in settings turns cx loose" "dangerously-bypass-approvals-and-sandbox" \
      "$(run 'SPL_YOLO=1' 'declare -f _spl_cx' | grep -o 'dangerously-bypass-approvals-and-sandbox')"

# ── Custom names ────────────────────────────────────────────────────────────
check "a new name works"          "function" "$(run "SPL_NAME_CC='cl'" 'type -t cl')"
check "the old name is handed back" "free"   "$(run "SPL_NAME_CC='cl'" 'declare -F cc >/dev/null || echo free')"
check "an empty name leaves it out" ""       "$(run "SPL_NAME_CX=''"   'type -t cx')"
check "a broken name is skipped, shell still loads" "ok" \
      "$(run "SPL_NAME_LSD='bad name;x'" 'type -t lsd >/dev/null || echo ok')"
check "second source is a no-op"  "1" "$(run '' ". '$SRC'; echo \$SPL_ALIAS_WRAPPERS_LOADED")"

# ── install.sh and uninstall.sh ─────────────────────────────────────────────
inst() {  # inst <home> <script> [args]: run a script against a throwaway home
    local h="$1"; shift
    env -u SPL_YOLO HOME="$h" XDG_CONFIG_HOME="$h/.config" SHELL=/bin/bash "$@"
}
h1="$SANDBOX/home1" && mkdir -p "$h1" && printf 'export KEEP_ME=1\n' > "$h1/.bashrc"
inst "$h1" "$REPO/install.sh" --no-prompt >/dev/null 2>&1
inst "$h1" "$REPO/install.sh" --no-prompt >/dev/null 2>&1
check "install adds the load line once, even run twice" "1" \
      "$(grep -c '>>> spl-alias-wrappers >>>' "$h1/.bashrc")"
check "install --no-prompt saves the default names" "SPL_NAME_CC='cc'" \
      "$(grep -o "^SPL_NAME_CC='cc'" "$h1/.config/spl-alias-wrappers/config.sh")"

h2="$SANDBOX/home2" && mkdir -p "$h2" && touch "$h2/.bashrc"
# Answers, in order: change names? y, lsa, c, lsd, cc as cl, cx left out, safety off? n
printf 'y\n\n\n\ncl\n-\nn\n' | inst "$h2" "$REPO/install.sh" >/dev/null 2>&1
conf2="$h2/.config/spl-alias-wrappers/config.sh"
check "install saves a renamed shortcut" "SPL_NAME_CC='cl'" "$(grep -o "^SPL_NAME_CC='cl'" "$conf2")"
check "install saves a left-out shortcut" "SPL_NAME_CX=''"  "$(grep -o "^SPL_NAME_CX=''" "$conf2")"
check "install keeps the safety check on when told no" "0"  "$(grep -c '^SPL_YOLO=1' "$conf2")"

h3="$SANDBOX/home3" && mkdir -p "$h3" && touch "$h3/.bashrc"
printf 'y\nlsa\n' | inst "$h3" "$REPO/install.sh" >/dev/null 2>&1
check "install finishes when the answers run out" "SPL_NAME_CX='cx'" \
      "$(grep -o "^SPL_NAME_CX='cx'" "$h3/.config/spl-alias-wrappers/config.sh")"

inst "$h1" "$REPO/uninstall.sh" >/dev/null 2>&1
check "uninstall removes the load line" "0" "$(grep -c 'spl-alias-wrappers' "$h1/.bashrc")"
check "uninstall leaves the rest of the file alone" "export KEEP_ME=1" "$(grep 'KEEP_ME' "$h1/.bashrc")"
check "uninstall removes the saved names" "gone" \
      "$([ -e "$h1/.config/spl-alias-wrappers" ] || echo gone)"

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
