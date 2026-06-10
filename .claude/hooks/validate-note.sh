#!/bin/bash
# Validate a single hub note (STRICT, write-path gate): no em dashes, non-empty,
# has an H1 or TL;DR. Used by store-to-hub before writing a NEW note, so a new
# em dash is a hard failure. For scanning EXISTING notes leniently, use hub-lint.sh.
# Usage: validate-note.sh <note.md>
set -euo pipefail
f="${1:?usage: validate-note.sh <note.md>}"
[ -s "$f" ] || { echo "FAIL: $f is empty"; exit 1; }
grep -q '—' "$f" && { echo "FAIL: $f contains em dash"; exit 1; }
# secret shapes (tokens/keys must never enter a note; cite where the value lives instead)
SECRET_RE='npm_[A-Za-z0-9]{30,}|(^|[^[:alnum:]-])sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY|Bearer [A-Za-z0-9_.=-]{25,}'
grep -qE "$SECRET_RE" "$f" && { echo "FAIL: $f contains a secret-shaped string"; exit 1; }
grep -qE '^#|## TL;DR' "$f" || echo "WARN: $f has no H1 or TL;DR"
echo "OK: $f"
