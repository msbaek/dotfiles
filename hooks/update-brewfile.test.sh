#!/usr/bin/env bash
# Tests for hooks/update-brewfile.sh (add-only merge).
# Runs the hook in a throwaway git repo with a stub `brew` and a fake
# Applications directory, so it never touches the real Brewfile or Homebrew.
set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/update-brewfile.sh"
FAILS=0

fail() { echo "FAIL: $1"; FAILS=$((FAILS + 1)); }
pass() { echo "ok:   $1"; }

# setup <brewfile> <dump> <apps_txt> <installed_apps...>
setup() {
    WORK="$(mktemp -d)"
    mkdir -p "$WORK/repo" "$WORK/stub" "$WORK/Applications"
    printf '%s' "$1" > "$WORK/repo/Brewfile"
    printf '%s' "$2" > "$WORK/dump"
    printf '%s' "$3" > "$WORK/repo/Applications.txt"
    shift 3
    for app in "$@"; do mkdir -p "$WORK/Applications/$app"; done

    cat > "$WORK/stub/brew" <<'STUB'
#!/usr/bin/env bash
# Stub: `brew bundle dump --force --file=X` copies the fixture; all else is a no-op.
if [ "$1" = "bundle" ] && [ "$2" = "dump" ]; then
    for arg in "$@"; do
        case "$arg" in --file=*) cp "$DUMP_FIXTURE" "${arg#--file=}" ;; esac
    done
fi
exit 0
STUB
    chmod +x "$WORK/stub/brew"

    git -C "$WORK/repo" init -q
    git -C "$WORK/repo" add -A
    git -C "$WORK/repo" -c user.name=t -c user.email=t@t commit -qm init
}

run_hook() {
    (cd "$WORK/repo" && PATH="$WORK/stub:$PATH" DUMP_FIXTURE="$WORK/dump" \
        APPS_DIR="$WORK/Applications" bash "$HOOK" >/dev/null 2>&1)
}

teardown() { rm -rf "$WORK"; }

# 1. Entries not installed on this machine are kept.
setup $'brew "openjdk"\nbrew "acli"\n' $'brew "acli"\n' $''
run_hook
grep -qx 'brew "openjdk"' "$WORK/repo/Brewfile" \
    && pass "keeps entries missing from dump" || fail "openjdk was removed"
teardown

# 2. Newly installed entries are appended with their description comment.
setup $'brew "acli"\n' $'brew "acli"\n# Terminal spreadsheet\nbrew "visidata"\nnpm "ccstatusline"\n' $''
run_hook
tail -3 "$WORK/repo/Brewfile" | diff - <(printf '# Terminal spreadsheet\nbrew "visidata"\nnpm "ccstatusline"\n') >/dev/null \
    && pass "appends new entries with comment" || fail "new entries not appended: $(cat "$WORK/repo/Brewfile")"
teardown

# 3. Existing content (comments, conditionals) is preserved byte-for-byte as a prefix.
ORIG=$'# common\nbrew "acli"\nif Hardware::CPU.intel?\n  brew "intel-only"\nend\n'
setup "$ORIG" $'brew "acli"\nbrew "yq"\n' $''
run_hook
cmp -s -n ${#ORIG} <(printf '%s' "$ORIG") "$WORK/repo/Brewfile" \
    && pass "preserves existing content" || fail "existing content changed"
grep -c '"intel-only"' "$WORK/repo/Brewfile" | grep -qx 1 \
    && pass "does not duplicate entries inside conditionals" || fail "intel-only duplicated"
teardown

# 4. Tap-qualified and bare names are the same entry.
setup $'brew "atlassian/acli/acli"\n' $'brew "acli"\n' $''
run_hook
[ "$(grep -c 'acli' "$WORK/repo/Brewfile")" = 1 ] \
    && pass "matches tap-qualified and bare names" || fail "acli duplicated"
teardown

# 5. No new entries -> Brewfile untouched and nothing staged.
setup $'brew "acli"\nbrew "openjdk"\n' $'brew "acli"\n' $'A.app\n' A.app
run_hook
[ -z "$(git -C "$WORK/repo" status --porcelain)" ] \
    && pass "no-op when nothing new" || fail "repo changed: $(git -C "$WORK/repo" status --porcelain)"
teardown

# 6. Applications.txt: keep missing apps, add new ones, stay sorted and unique.
setup $'brew "acli"\n' $'brew "acli"\n' $'Alacritty.app\nZed.app\n' Alacritty.app Kitty.app
run_hook
diff "$WORK/repo/Applications.txt" <(printf 'Alacritty.app\nKitty.app\nZed.app\n') >/dev/null \
    && pass "Applications.txt is add-only" || fail "Applications.txt: $(cat "$WORK/repo/Applications.txt")"
teardown

# 7. Changed files are staged.
setup $'brew "acli"\n' $'brew "acli"\nbrew "yq"\n' $'' New.app
run_hook
staged="$(git -C "$WORK/repo" diff --cached --name-only | sort | tr '\n' ' ')"
[ "$staged" = "Applications.txt Brewfile " ] \
    && pass "stages changed files" || fail "staged: '$staged'"
teardown

echo
[ "$FAILS" -eq 0 ] && echo "ALL PASS" || { echo "$FAILS FAILED"; exit 1; }
