#!/bin/bash
# Append a one-line entry to a hub's log.md. Creates log.md with a header if absent.
# Usage: append-log.sh <hub-dir> <op> <note> <message>
#   op in: add update merge delete rename
# Format: - <YYYY-MM-DD> | <op> | <note> | <what+why>   (newest at bottom)
set -euo pipefail
hub="${1:?usage: append-log.sh <hub-dir> <op> <note> <message>}"
op="${2:?op required (add|update|merge|delete|rename)}"
note="${3:?note required}"
msg="${4:?message required}"
case "$op" in add|update|merge|delete|rename) ;; *) echo "FAIL: bad op '$op' (add|update|merge|delete|rename)"; exit 2;; esac
[ -d "$hub" ] || { echo "FAIL: no hub dir $hub"; exit 1; }
log="$hub/log.md"
if [ ! -f "$log" ]; then
  printf '# %s log\n\nAppend-only operations log. Format: `- <date> | <op> | <note> | <what+why>`. Newest at bottom.\n\n' "$(basename "$hub")" > "$log"
fi
printf -- '- %s | %s | %s | %s\n' "$(date +%F)" "$op" "$note" "$msg" >> "$log"
echo "logged: $op $note"
