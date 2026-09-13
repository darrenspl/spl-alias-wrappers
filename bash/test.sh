#!/usr/bin/env bash
# Check that the shortcuts load, behave, and install cleanly. No test tools.
# Run it: bash bash/test.sh     Prints one line per check, exits 1 on any failure.
#
# Every check runs in a fresh shell with no startup file and a throwaway home
# folder, so nothing on your own machine is read or changed. The zsh checks
# run only when zsh is installed.
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

# load <shell> <settings file contents> <code>: a fresh interactive shell with
# no startup file, the given saved settings, aliases.sh loaded, then the code.
load() {
    local home="$SANDBOX/run.$RANDOM$RANDOM"
    mkdir -p "$home/.config/spl-alias-wrappers"
    [ -n "$2" ] && printf '%b' "$2" > "$home/.config/spl-alias-wrappers/config"
    # shellcheck disable=SC2086  # $1 holds the shell and its flags on purpose
    env -u SPL_YOLO HOME="$home" XDG_CONFIG_HOME="$home/.config" \
        $1 -c ". '$SRC' >/dev/null 2>&1
$3" 2>/dev/null
}
run()  { load "bash --norc -i" "$@"; }
zrun() { load "zsh -f -i" "$@"; }

dirs="$SANDBOX/dirs" && mkdir -p "$dirs/PlaneNotes" "$dirs/other" "$SANDBOX/empty"

# ── Default names ───────────────────────────────────────────────────────────
check "lsa is an alias for ls -la" "alias lsa='ls -la'" "$(run '' 'alias lsa')"
check "c is an alias for clear"    "alias c='clear'"    "$(run '' 'alias c')"
for fn in lsd cc cx; do
    check "$fn is a function" "function" "$(run '' "type -t $fn")"
done

# ── lsd ─────────────────────────────────────────────────────────────────────
check "lsd matches ignoring case" "PlaneNotes" "$(run '' "cd '$dirs' && lsd plane")"
check "lsd exits 1 on no match"   "1" "$(run '' "cd '$dirs' && lsd zzzz >/dev/null 2>&1; echo \$?")"
check "lsd exits 2 with no word"  "2" "$(run '' 'lsd >/dev/null 2>&1; echo $?')"
check "lsd still works when find is aliased to something else" "PlaneNotes" \
      "$(env -u SPL_YOLO HOME="$SANDBOX" bash --norc -ic "alias find='echo broken'
. '$SRC' >/dev/null 2>&1
cd '$dirs' && lsd plane" 2>/dev/null)"

# ── Claude Code and Codex ───────────────────────────────────────────────────
check "cc is safe by default" "" \
      "$(run '' 'declare -f _spl_cc' | grep -o 'dangerously-skip-permissions')"
check "cx is safe by default" "" \
      "$(run '' 'declare -f _spl_cx' | grep -o 'dangerously-bypass-approvals-and-sandbox')"
check "yolo=1 in settings turns cc loose" "dangerously-skip-permissions" \
      "$(run 'yolo=1\n' 'declare -f _spl_cc' | grep -o 'dangerously-skip-permissions')"
check "yolo=1 in settings turns cx loose" "dangerously-bypass-approvals-and-sandbox" \
      "$(run 'yolo=1\n' 'declare -f _spl_cx' | grep -o 'dangerously-bypass-approvals-and-sandbox')"
check "yolo=0 in settings keeps cc safe" "" \
      "$(run 'yolo=0\n' 'declare -f _spl_cc' | grep -o 'dangerously-skip-permissions')"
check "cc says so when Claude Code is not installed" "127" \
      "$(run '' "PATH='$SANDBOX/empty'; cc >/dev/null 2>&1; echo \$?")"

# ── Custom names ────────────────────────────────────────────────────────────
check "a new name works"            "function" "$(run 'cc=cl\n' 'type -t cl')"
check "the old name is handed back" "free"     "$(run 'cc=cl\n' 'declare -F cc >/dev/null || echo free')"
check "an empty name leaves it out" ""         "$(run 'cx=\n'   'type -t cx')"
check "a settings file with Windows line endings still works" "function" \
      "$(run 'cc=cl\r\n' 'type -t cl')"
check "a broken name is skipped, shell still loads" "ok" \
      "$(run 'lsd=bad name;x\n' 'type -t lsd >/dev/null || echo ok')"
check "second source is a no-op"    "1" "$(run '' ". '$SRC'; echo \$SPL_ALIAS_WRAPPERS_LOADED")"

# ── zsh ─────────────────────────────────────────────────────────────────────
if command -v zsh >/dev/null 2>&1; then
    check "zsh: lsa is an alias"       "lsa='ls -la'"  "$(zrun '' 'alias lsa')"
    check "zsh: lsd is a function"     "lsd: function" "$(zrun '' 'whence -w lsd')"
    check "zsh: lsd matches ignoring case" "PlaneNotes" "$(zrun '' "cd '$dirs' && lsd plane")"
    check "zsh: a new name works"      "cl: function"  "$(zrun 'cc=cl\n' 'whence -w cl')"
    check "zsh: cc is safe by default" "0" \
          "$(zrun '' 'whence -f _spl_cc' | grep -c 'dangerously')"
    check "zsh: yolo=1 turns cc loose" "1" \
          "$(zrun 'yolo=1\n' 'whence -f _spl_cc' | grep -c 'dangerously')"
else
    echo "skip  zsh checks, zsh is not installed"
fi

# ── install.sh and uninstall.sh ─────────────────────────────────────────────
inst() {  # inst <home> <script> [args]: run a script against a throwaway home
    local h="$1"; shift
    env -u SPL_YOLO HOME="$h" XDG_CONFIG_HOME="$h/.config" SHELL=/bin/bash bash "$@"
}
# The installer picks .bashrc or .bash_profile depending on the OS, so the
# checks read every startup file bash might use.
startup() { cat "$1/.bashrc" "$1/.bash_profile" "$1/.bash_login" "$1/.profile" 2>/dev/null; }

h1="$SANDBOX/home1" && mkdir -p "$h1" && printf 'export KEEP_ME=1\n' > "$h1/.bashrc"
inst "$h1" "$REPO/install.sh" --no-prompt >/dev/null 2>&1
inst "$h1" "$REPO/install.sh" --no-prompt >/dev/null 2>&1
check "install adds the load line once, even run twice" "1" \
      "$(startup "$h1" | grep -c '>>> spl-alias-wrappers >>>')"
check "install --no-prompt saves the default names" "cc=cc" \
      "$(grep -x 'cc=cc' "$h1/.config/spl-alias-wrappers/config")"

h2="$SANDBOX/home2" && mkdir -p "$h2"
# Answers, in order: change names? y, lsa, c, lsd, cc as cl, cx left out, safety off? n
printf 'y\n\n\n\ncl\n-\nn\n' | inst "$h2" "$REPO/install.sh" >/dev/null 2>&1
conf2="$h2/.config/spl-alias-wrappers/config"
check "install saves a renamed shortcut"  "cc=cl" "$(grep -x 'cc=cl' "$conf2")"
check "install saves a left-out shortcut" "cx="   "$(grep -x 'cx=' "$conf2")"
check "install keeps the safety check on when told no" "yolo=0" "$(grep -x 'yolo=0' "$conf2")"

h3="$SANDBOX/home3" && mkdir -p "$h3"
printf 'y\nlsa\n' | inst "$h3" "$REPO/install.sh" >/dev/null 2>&1
check "install finishes when the answers run out" "cx=cx" \
      "$(grep -x 'cx=cx' "$h3/.config/spl-alias-wrappers/config")"

inst "$h1" "$REPO/uninstall.sh" >/dev/null 2>&1
check "uninstall removes the load line" "0" "$(startup "$h1" | grep -c 'spl-alias-wrappers')"
check "uninstall leaves the rest of the file alone" "export KEEP_ME=1" "$(grep 'KEEP_ME' "$h1/.bashrc")"
check "uninstall keeps the saved names for PowerShell" "yes" \
      "$([ -f "$h1/.config/spl-alias-wrappers/config" ] && echo yes)"

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
