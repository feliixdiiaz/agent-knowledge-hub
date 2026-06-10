#!/bin/bash
# hub-lint.sh: deterministic hub health gate (the "CI" pass; no LLM).
# Usage: hub-lint.sh <hub-dir>
#
# BLOCK (exit 1): note file not in INDEX; INDEX entry whose .md file is missing;
#                 broken relative .md link in a root note body.
# WARN  (exit 0): em dash in any note; root note missing a log.md entry;
#                 root note without ## TL;DR.
# Scope: INDEX / log / TL;DR checks cover ROOT notes only (works/** is not
#        individually indexed). The em-dash check recurses into works/** as WARN.
#
# bash 3.2 safe: no `set -u` (empty-array expansion lands), pipefail only.
set -o pipefail
shopt -s nullglob

hub="${1:?usage: hub-lint.sh <hub-dir>}"
[ -d "$hub" ] || { echo "FAIL: no hub dir $hub"; exit 2; }
idx="$hub/INDEX.md"
log="$hub/log.md"

BLOCKS=()
WARNS=()

is_meta() { case "$(basename "$1")" in INDEX.md|AGENTS.md|CLAUDE.md|README.md|log.md) return 0;; *) return 1;; esac; }

root_notes=()
for n in "$hub"/*.md; do is_meta "$n" && continue; root_notes+=("$n"); done

# 1. note file not in INDEX (BLOCK)
if [ -f "$idx" ]; then
  for n in "${root_notes[@]}"; do
    b=$(basename "$n")
    grep -qF "$b" "$idx" || BLOCKS+=("note not in INDEX: $b")
  done
else
  BLOCKS+=("no INDEX.md in $hub")
fi

# 2. INDEX entry whose .md file is missing (BLOCK); skip http + dir (trailing /) links
if [ -f "$idx" ]; then
  while IFS= read -r link; do
    case "$link" in http*|"") continue;; */) continue;; esac
    case "$link" in *.md) [ -f "$hub/$link" ] || BLOCKS+=("INDEX links missing file: $link");; esac
  done < <(grep -oE '\]\([^)]+\)' "$idx" | sed -E 's/^\]\(//; s/\)$//')
fi

# 3. broken relative .md links in root note bodies (BLOCK)
for n in "${root_notes[@]}"; do
  d=$(dirname "$n")
  while IFS= read -r link; do
    case "$link" in http*|"") continue;; esac
    [ -f "$d/$link" ] || BLOCKS+=("broken link in $(basename "$n"): $link")
  done < <(grep -oE '\]\([^)]+\.md\)' "$n" | sed -E 's/^\]\(//; s/\)$//')
done

# 4. em dash anywhere (WARN), root + works
while IFS= read -r f; do
  [ -n "$f" ] && WARNS+=("em dash: ${f#$hub/}")
done < <(grep -rl '—' "$hub" --include='*.md' 2>/dev/null)

# 4b. secret-shaped strings anywhere (WARN on scan; the write gate FAILs them)
SECRET_RE='npm_[A-Za-z0-9]{30,}|(^|[^[:alnum:]-])sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY|Bearer [A-Za-z0-9_.=-]{25,}'
while IFS= read -r f; do
  [ -n "$f" ] && WARNS+=("secret-shaped string: ${f#$hub/}")
done < <(grep -rlE "$SECRET_RE" "$hub" --include='*.md' 2>/dev/null)

# 4c. stale small hub (WARN): fewer than 3 notes AND nothing touched in 60 days
if [ ${#root_notes[@]} -lt 3 ]; then
  recent=$(find "$hub" -name '*.md' -newermt '-60 days' 2>/dev/null | head -1)
  [ -z "$recent" ] && WARNS+=("stale small hub: ${#root_notes[@]} note(s), no activity in 60 days; consider merging into a broader charter")
fi

# 4d. stalled work (WARN): no TL;DR anywhere in the work AND nothing touched in 45 days
for wdir in "$hub"/works/*/; do
  [ -d "$wdir" ] || continue
  grep -rqE '## TL;DR' "$wdir" --include='*.md' 2>/dev/null && continue
  recent=$(find "$wdir" -name '*.md' -newermt '-45 days' 2>/dev/null | head -1)
  [ -z "$recent" ] && WARNS+=("stalled work: ${wdir#$hub/} has no TL;DR and no activity in 45 days; stabilize, promote findings, or archive")
done

# 5. root note missing a log.md entry (WARN)
if [ -f "$log" ]; then
  for n in "${root_notes[@]}"; do
    b=$(basename "$n")
    grep -qF "$b" "$log" || WARNS+=("no log entry: $b")
  done
else
  WARNS+=("no log.md in $hub")
fi

# 6. root note without ## TL;DR (WARN)
for n in "${root_notes[@]}"; do
  grep -qE '## TL;DR' "$n" || WARNS+=("no ## TL;DR: $(basename "$n")")
done

echo "hub-lint: $hub (${#root_notes[@]} root notes)"
if [ ${#BLOCKS[@]} -gt 0 ]; then echo "  BLOCK (${#BLOCKS[@]}):"; printf '    - %s\n' "${BLOCKS[@]}"; fi
if [ ${#WARNS[@]} -gt 0 ];  then echo "  WARN (${#WARNS[@]}):";  printf '    - %s\n' "${WARNS[@]}"; fi
[ ${#BLOCKS[@]} -eq 0 ] && [ ${#WARNS[@]} -eq 0 ] && echo "  clean"

[ ${#BLOCKS[@]} -eq 0 ] || exit 1
exit 0
