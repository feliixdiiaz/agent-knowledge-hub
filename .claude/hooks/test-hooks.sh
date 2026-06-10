#!/bin/bash
# Tests for the deterministic hub hooks: validate-note, check-index-updated,
# append-log, hub-lint. Run: ./test-hooks.sh
set -uo pipefail
H="$(cd "$(dirname "$0")" && pwd)"
fail() { echo "FAIL: $1"; exit 1; }

# --- validate-note.sh ---
tmp=$(mktemp -d)
printf '# t\nhas — dash\n' > "$tmp/bad.md"
"$H/validate-note.sh" "$tmp/bad.md" >/dev/null 2>&1 && fail "em-dash not caught"
printf '# t\n## TL;DR\nok\n' > "$tmp/good.md"
"$H/validate-note.sh" "$tmp/good.md" >/dev/null || fail "clean note rejected"
# secret-shaped string fails the strict gate
printf '# t\ntoken is npm_%s\n' "abcdefghijklmnopqrstuvwxyz123456" > "$tmp/secret.md"
"$H/validate-note.sh" "$tmp/secret.md" >/dev/null 2>&1 && fail "secret not caught"
# citing WHERE a secret lives passes
printf '# t\n## TL;DR\ntoken lives in Keychain item abridge-npm\n' > "$tmp/pointer.md"
"$H/validate-note.sh" "$tmp/pointer.md" >/dev/null || fail "pointer-style citation rejected"

# --- check-index-updated.sh ---
mkdir -p "$tmp/cidx"; printf '# i\n## Notes\n' > "$tmp/cidx/INDEX.md"; printf '# n\n' > "$tmp/cidx/note.md"
"$H/check-index-updated.sh" "$tmp/cidx" >/dev/null 2>&1 && fail "unindexed note not caught"
printf '# i\n## Notes\n- [note.md](note.md): x\n' > "$tmp/cidx/INDEX.md"
"$H/check-index-updated.sh" "$tmp/cidx" >/dev/null || fail "indexed note rejected"
# log.md must be skipped by the index check
printf '# l\n- x\n' > "$tmp/cidx/log.md"
"$H/check-index-updated.sh" "$tmp/cidx" >/dev/null || fail "log.md not skipped by index check"

# --- append-log.sh ---
mkdir -p "$tmp/lh"
"$H/append-log.sh" "$tmp/lh" add foo.md "created foo" >/dev/null || fail "append-log failed"
[ -f "$tmp/lh/log.md" ] || fail "log.md not created"
grep -qE '^- [0-9]{4}-[0-9]{2}-[0-9]{2} \| add \| foo.md \| created foo$' "$tmp/lh/log.md" || fail "log line format wrong"
"$H/append-log.sh" "$tmp/lh" bogus foo.md msg >/dev/null 2>&1 && fail "bad op accepted"
"$H/append-log.sh" "$tmp/lh" update foo.md "edited" >/dev/null || fail "second append failed"
[ "$(grep -c '^- ' "$tmp/lh/log.md")" -eq 2 ] || fail "append count wrong"

# --- hub-lint.sh ---
mkhub() { # $1 dir: build a fully clean hub with one good note
  local d="$1"; mkdir -p "$d"
  printf '# a\n## TL;DR\nclean note\n' > "$d/a.md"
  printf '# h index\n## Notes\n- [a.md](a.md): clean note.\n' > "$d/INDEX.md"
  printf '# h log\n\n- 2026-06-09 | add | a.md | created\n' > "$d/log.md"
  printf '# h\ncharter\n' > "$d/AGENTS.md"
}
# clean -> exit 0
hb="$tmp/clean"; mkhub "$hb"
"$H/hub-lint.sh" "$hb" >/dev/null || fail "clean hub did not pass"
# orphan note (not in INDEX) -> BLOCK exit 1
hb="$tmp/orphan"; mkhub "$hb"; printf '# b\n## TL;DR\nx\n' > "$hb/b.md"
"$H/hub-lint.sh" "$hb" >/dev/null 2>&1 && fail "orphan note not BLOCKed"
# INDEX entry whose file is missing -> BLOCK exit 1
hb="$tmp/danglingidx"; mkhub "$hb"; printf '# h index\n## Notes\n- [a.md](a.md): x\n- [gone.md](gone.md): missing\n' > "$hb/INDEX.md"
"$H/hub-lint.sh" "$hb" >/dev/null 2>&1 && fail "dangling INDEX entry not BLOCKed"
# broken body link -> BLOCK exit 1
hb="$tmp/brokenlink"; mkhub "$hb"; printf '# a\n## TL;DR\nsee [x](../nope/z.md)\n' > "$hb/a.md"
"$H/hub-lint.sh" "$hb" >/dev/null 2>&1 && fail "broken body link not BLOCKed"
# em dash -> WARN only, exit 0
hb="$tmp/emdash"; mkhub "$hb"; printf '# a\n## TL;DR\nhas — dash\n' > "$hb/a.md"
out=$("$H/hub-lint.sh" "$hb"); rc=$?
[ "$rc" -eq 0 ] || fail "em dash should be WARN not BLOCK"
echo "$out" | grep -q 'em dash: a.md' || fail "em dash not reported as WARN"
# missing log entry -> WARN only, exit 0
hb="$tmp/nolog"; mkhub "$hb"; printf '# h log\n\n' > "$hb/log.md"
out=$("$H/hub-lint.sh" "$hb"); rc=$?
[ "$rc" -eq 0 ] || fail "missing log entry should be WARN not BLOCK"
echo "$out" | grep -q 'no log entry: a.md' || fail "missing log entry not reported"
# no TL;DR -> WARN only, exit 0
hb="$tmp/notldr"; mkhub "$hb"; printf '# a\nno summary\n' > "$hb/a.md"
out=$("$H/hub-lint.sh" "$hb"); rc=$?
[ "$rc" -eq 0 ] || fail "no TL;DR should be WARN not BLOCK"
echo "$out" | grep -q 'no ## TL;DR: a.md' || fail "no-TLDR not reported"

rm -rf "$tmp"
echo "ALL HOOK TESTS PASS"
