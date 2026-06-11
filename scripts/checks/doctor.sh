#!/bin/bash
# doctor.sh: deterministic diagnosis of the hub installation itself.
# Checks the whole chain: env -> symlinks -> matcher resolution -> machinery.
# Born from a real bug: a stale HUB_ROOT in .zshrc silently re-routed all
# retrieval to a different repo, and an LLM session mis-diagnosed it.
#
# Usage: doctor.sh [--fix]
#   --fix re-runs install.sh (relink + chmod). Env fixes are PRINTED, never
#   applied: this process cannot change your shell's environment.
# Exit: 0 = healthy or warnings only; 1 = at least one FAIL.
set -o pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FIX=0; [ "${1:-}" = "--fix" ] && FIX=1
fails=0; warns=0
ok()   { echo "OK:   $1"; }
warn() { echo "WARN: $1"; warns=$((warns+1)); }
fail() { echo "FAIL: $1"; fails=$((fails+1)); }

echo "hub-doctor: $ROOT"
echo

# 1. env: HUB_ROOT sanity
if [ -n "${HUB_ROOT:-}" ]; then
  if [ ! -d "$HUB_ROOT/hubs" ]; then
    fail "HUB_ROOT=$HUB_ROOT is set but has no hubs/ dir. Fix: export HUB_ROOT=\"$ROOT\" (and update the line in ~/.zshrc)"
  elif [ "$(cd "$HUB_ROOT" && pwd)" != "$ROOT" ]; then
    warn "HUB_ROOT=$HUB_ROOT points at a DIFFERENT hub than this repo. If unintended (the classic stale-env bug): export HUB_ROOT=\"$ROOT\" and fix ~/.zshrc"
  else
    ok "HUB_ROOT matches this repo"
  fi
else
  default="$HOME/workspace/agent-knowledge-hub"
  if [ "$ROOT" = "$default" ]; then
    ok "HUB_ROOT unset; built-in default resolves to this repo"
  else
    warn "HUB_ROOT unset and this repo is not at the default path. Skills will look at $default. Fix: export HUB_ROOT=\"$ROOT\" (install.sh writes it to ~/.zshrc)"
  fi
fi

# 1b. shell-file vs process-env drift (the stale-session bug)
zline=$(grep -E '^export HUB_ROOT=' "$HOME/.zshrc" 2>/dev/null | tail -1 | sed -E 's/^export HUB_ROOT="?([^"]*)"?/\1/')
if [ -n "$zline" ] && [ -n "${HUB_ROOT:-}" ] && [ "$zline" != "$HUB_ROOT" ]; then
  warn "~/.zshrc exports HUB_ROOT=$zline but this process has HUB_ROOT=$HUB_ROOT. A long-lived session is carrying a stale env; restart it."
fi

# 2. skill symlinks per harness
for base in "$HOME/.claude/skills" "$HOME/.codex/skills"; do
  hname=$(basename "$(dirname "$base")")
  [ -d "$(dirname "$base")" ] || continue
  for s in load-context store-to-hub hub-lint hub-doctor; do
    t="$base/$s"
    if [ -L "$t" ]; then
      dest=$(readlink "$t")
      if [ ! -e "$t" ]; then
        fail "$hname/$s symlink is broken (-> $dest). Fix: ./install.sh"
      elif [ "$(cd "$(dirname "$t")" && cd "$(dirname "$dest")" 2>/dev/null && pwd)/$(basename "$dest")" != "$ROOT/skills/$s" ] && [ "$dest" != "$ROOT/skills/$s" ]; then
        warn "$hname/$s links to another hub ($dest), not this repo. If unintended: ./install.sh"
      else
        ok "$hname/$s linked to this repo"
      fi
    elif [ -e "$t" ]; then
      warn "$hname/$s exists but is not a symlink (local copy can drift). Fix: ./install.sh (backs it up first)"
    else
      [ "$s" = "hub-doctor" ] || warn "$hname/$s not installed. Fix: ./install.sh"
    fi
  done
done

# 3. matcher actually resolves to this repo's hubs
if command -v node >/dev/null 2>&1; then
  got=$(HUB_ROOT="$ROOT" node "$ROOT/skills/load-context/bin/match.mjs" "__doctor_probe__" --json 2>/dev/null)
  if [ "$got" = "[]" ] || echo "$got" | grep -q '"hub"'; then
    ok "matcher runs and resolves against this repo"
  else
    fail "matcher did not produce valid output. Run: node $ROOT/skills/load-context/bin/match.mjs \"test\" --json"
  fi
else
  fail "node not found on PATH; the matchers cannot run"
fi

# 4. machinery: checks executable, hubs lint-able
for c in validate-note.sh check-index-updated.sh append-log.sh hub-lint.sh; do
  if [ -x "$ROOT/scripts/checks/$c" ]; then ok "checks/$c executable"
  else warn "checks/$c not executable. Fix: chmod +x $ROOT/scripts/checks/*.sh"; fi
done
if [ -d "$ROOT/.git" ]; then ok "repo is git (snapshots and history available)"
else warn "repo is not git; maintenance snapshots and undo are unavailable. Fix: git init && git add -A && git commit -m init"; fi
command -v fzf >/dev/null 2>&1 && ok "fzf present (fuzzy retrieval active)" || warn "fzf not installed; fuzzy fallback disabled (optional: brew install fzf)"

# --fix: the safe, mechanical repairs
if [ "$FIX" = "1" ]; then
  echo
  echo "applying safe fixes (relink + chmod via install.sh)..."
  bash "$ROOT/install.sh"
fi

echo
echo "doctor summary: fails=$fails warns=$warns"
[ "$fails" -eq 0 ]
