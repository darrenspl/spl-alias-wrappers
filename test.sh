#!/usr/bin/env bash
# Check that all five shortcuts load and behave. No test framework needed.
# Run it: ./test.sh     Prints one line per check, exits 1 on any failure.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO/aliases.sh"
pass=0; fail=0

check() {  # check <name> <expected> <actual>
    if [ "$2" = "$3" ]; then
        printf 'ok    %s\n' "$1"; pass=$((pass+1))
    else
        printf 'FAIL  %s\n        want: %s\n        got:  %s\n' "$1" "$2" "$3"
        fail=$((fail+1))
    fi
}

# Run a snippet in a fresh interactive bash with the file loaded.
run() { env -u SPL_YOLO bash -ic ". '$SRC' >/dev/null 2>&1; $1" 2>/dev/null; }
run_yolo() { SPL_YOLO=1 bash -ic ". '$SRC' >/dev/null 2>&1; $1" 2>/dev/null; }

# 1. The two plain aliases exist and point at the right command.
check "lsa is an alias for ls -la" "alias lsa='ls -la'" "$(run 'alias lsa')"
check "c is an alias for clear"    "alias c='clear'"    "$(run 'alias c')"

# 2. The three functions exist.
for fn in lsd cc cx; do
    check "$fn is a function" "function" "$(run "type -t $fn")"
done

# 3. lsd finds a folder, ignores case, and says so when there is no match.
tmp=$(mktemp -d) && mkdir -p "$tmp/PlaneNotes" "$tmp/other"
check "lsd matches ignoring case" "PlaneNotes" \
      "$(run "cd '$tmp' && lsd plane")"
check "lsd exits 1 on no match" "1" \
      "$(run "cd '$tmp' && lsd zzzz >/dev/null 2>&1; echo \$?")"
check "lsd exits 2 with no word" "2" \
      "$(run "lsd >/dev/null 2>&1; echo \$?")"
rm -rf "$tmp"

# 4. Safety. The dangerous flag is OFF unless SPL_YOLO=1 is set.
check "cc is safe by default" "" \
      "$(run 'declare -f cc' | grep -o 'dangerously-skip-permissions')"
check "cx is safe by default" "" \
      "$(run 'declare -f cx' | grep -o 'dangerously-bypass-approvals-and-sandbox')"
check "SPL_YOLO=1 turns cc loose" "dangerously-skip-permissions" \
      "$(run_yolo 'declare -f cc' | grep -o 'dangerously-skip-permissions')"
check "SPL_YOLO=1 turns cx loose" "dangerously-bypass-approvals-and-sandbox" \
      "$(run_yolo 'declare -f cx' | grep -o 'dangerously-bypass-approvals-and-sandbox')"

# 5. Sourcing twice does not double anything up.
check "second source is a no-op" "1" \
      "$(run ". '$SRC'; echo \$SPL_ALIAS_WRAPPERS_LOADED")"

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
