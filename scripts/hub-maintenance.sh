#!/bin/bash
# hub-maintenance.sh: the weekly hub hygiene sweep (deterministic, no LLM).
# 1. hub-lint every sub-hub; write report to ~/.claude/job-logs/hub-lint-report.txt
# 2. git snapshot (auto-commit local changes so history accrues without discipline)
# 3. macOS notification if any BLOCK, or if WARN count grew since last run
# 4. update ~/.claude/job-registry.yaml (lastRun/lastResult/lastNote) for job-dashboard
# Run by a scheduler (launchd/cron) or by hand.
set -o pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOGDIR="$HOME/.claude/job-logs"
REPORT="$LOGDIR/hub-lint-report.txt"
STATE="$LOGDIR/hub-lint-state"
REGISTRY="$HOME/.claude/job-registry.yaml"
mkdir -p "$LOGDIR"

blocks=0
warns=0
{
  echo "hub maintenance sweep: $(date '+%F %T')"
  echo "repo: $ROOT"
  echo
  for hub in "$ROOT"/hubs/*/; do
    [ -d "$hub" ] || continue
    out=$("$ROOT/scripts/checks/hub-lint.sh" "$hub" 2>&1)
    rc=$?
    echo "$out"
    echo
    [ $rc -ne 0 ] && blocks=$((blocks + 1))
    w=$(echo "$out" | grep -oE 'WARN \([0-9]+\)' | grep -oE '[0-9]+' || echo 0)
    warns=$((warns + ${w:-0}))
  done
  echo "totals: blocks=$blocks warns=$warns"
  echo
  echo "--- citation drift (notes vs upstream code) ---"
  "$ROOT/scripts/citation-drift.sh" 2>&1
} > "$REPORT" 2>&1

# git snapshot: commit drift so every state is recoverable
cd "$ROOT"
snap="none"
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  git add -A
  git commit -qm "auto: maintenance snapshot ($(date +%F), blocks=$blocks warns=$warns)" && snap="committed"
fi

# notify on BLOCK or WARN growth
prev=$(cat "$STATE" 2>/dev/null || echo 999999)
if [ "$blocks" -gt 0 ]; then
  osascript -e "display notification \"$blocks BLOCK finding(s). Run /hub-lint.\" with title \"agent-knowledge-hub: lint BLOCK\"" 2>/dev/null
elif [ "$warns" -gt "$prev" ]; then
  osascript -e "display notification \"warnings grew: $prev -> $warns\" with title \"agent-knowledge-hub: lint warnings up\"" 2>/dev/null
fi
echo "$warns" > "$STATE"

# update job registry (line-edits within the hub-maintenance block only)
if [ -f "$REGISTRY" ] && grep -q '^  hub-maintenance:' "$REGISTRY"; then
  python3 - "$REGISTRY" "$blocks" "$warns" "$snap" <<'PY'
import sys, datetime
path, blocks, warns, snap = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
lines = open(path).read().splitlines(keepends=True)
out, inblock = [], False
now = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
result = 'failure' if int(blocks) > 0 else 'success'
note = f"blocks={blocks} warns={warns} snapshot={snap}"
for ln in lines:
    if ln.startswith('  ') and not ln.startswith('    '):
        inblock = ln.strip() == 'hub-maintenance:'
    if inblock and ln.lstrip().startswith('lastRun:'):
        ln = f'    lastRun: {now}\n'
    elif inblock and ln.lstrip().startswith('lastResult:'):
        ln = f'    lastResult: {result}\n'
    elif inblock and ln.lstrip().startswith('lastNote:'):
        ln = f'    lastNote: "{note}"\n'
    out.append(ln)
open(path, 'w').write(''.join(out))
PY
fi

echo "sweep done: blocks=$blocks warns=$warns snapshot=$snap (report: $REPORT)"
[ "$blocks" -eq 0 ]
