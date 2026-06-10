#!/bin/bash
# For a sub-hub dir, verify every *.md note (except INDEX/AGENTS/CLAUDE/README)
# is referenced in INDEX.md. Arg: sub-hub dir.
set -euo pipefail
hub="${1:?usage: check-index-updated.sh <hub-dir>}"
idx="$hub/INDEX.md"
[ -f "$idx" ] || { echo "FAIL: no INDEX.md in $hub"; exit 1; }
miss=0
for n in "$hub"/*.md; do
  [ -e "$n" ] || continue
  base=$(basename "$n")
  case "$base" in INDEX.md|AGENTS.md|CLAUDE.md|README.md|log.md) continue;; esac
  grep -qF "$base" "$idx" || { echo "MISSING from INDEX: $base"; miss=1; }
done
[ "$miss" -eq 0 ] && echo "OK: all notes indexed in $hub"
exit "$miss"
