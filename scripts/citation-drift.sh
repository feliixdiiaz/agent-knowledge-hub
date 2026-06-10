#!/bin/bash
# citation-drift.sh: detect notes whose cited code paths changed after the
# note was last touched (the confident-but-stale failure mode).
#
# For each root note in each sub-hub:
#   1. extract repo-relative cited paths (apps/..., packages/...)
#   2. resolve each against local clones in ~/workspace/*
#   3. compare note's last commit date (this repo) vs the cited path's last
#      commit date on origin's default branch (after git fetch, unless SKIP_FETCH=1)
#   4. report: DRIFT (cited path newer than note), GONE (path no longer exists)
#
# Advisory output for the weekly maintenance report; exit 0 always.
set -o pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WS="$HOME/workspace"
PATH_RE='(apps|packages)/[A-Za-z0-9_./-]+\.[A-Za-z0-9]+'

# candidate repos: local clones with git, excluding this hub
repos=()
for r in "$WS"/*/; do
  [ -d "$r/.git" ] || continue
  [ "$(basename "$r")" = "agent-knowledge-hub" ] && continue
  repos+=("${r%/}")
done

# fetch once per repo (quiet, non-invasive; working copies untouched)
if [ "${SKIP_FETCH:-0}" != "1" ]; then
  for r in "${repos[@]}"; do git -C "$r" fetch -q 2>/dev/null; done
fi

default_ref() { # origin default branch for a repo
  git -C "$1" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null \
    || { git -C "$1" show-ref -q refs/remotes/origin/main && echo origin/main; } \
    || { git -C "$1" show-ref -q refs/remotes/origin/master && echo origin/master; } \
    || echo HEAD
}

drift=0; gone=0; unresolved=0
for hub in "$ROOT"/hubs/*/; do
  for note in "$hub"*.md; do
    [ -e "$note" ] || continue
    case "$(basename "$note")" in INDEX.md|AGENTS.md|CLAUDE.md|README.md|log.md) continue;; esac
    note_ts=$(git -C "$ROOT" log -1 --format=%ct -- "${note#$ROOT/}" 2>/dev/null)
    [ -n "$note_ts" ] || continue
    while IFS= read -r cited; do
      # pass A: does the path exist TODAY in any repo? (check all before any history verdict)
      resolved=""
      for r in "${repos[@]}"; do
        ref=$(default_ref "$r")
        if git -C "$r" cat-file -e "$ref:$cited" 2>/dev/null; then
          resolved="$r"
          cited_ts=$(git -C "$r" log -1 --format=%ct "$ref" -- "$cited" 2>/dev/null)
          if [ -n "$cited_ts" ] && [ "$cited_ts" -gt "$note_ts" ]; then
            echo "DRIFT: $(basename "$note") cites $cited (changed $(date -r "$cited_ts" +%F) in $(basename "$r"), note last touched $(date -r "$note_ts" +%F))"
            drift=$((drift+1))
          fi
          break
        fi
      done
      [ -n "$resolved" ] && continue
      # pass B: nowhere today; did it exist historically somewhere? then it moved/died
      for r in "${repos[@]}"; do
        if git -C "$r" log -1 --format=%ct "$(default_ref "$r")" -- "$cited" 2>/dev/null | grep -q .; then
          resolved="$r"
          echo "GONE: $(basename "$note") cites $cited (existed in $(basename "$r"), now deleted/moved)"
          gone=$((gone+1))
          break
        fi
      done
      [ -z "$resolved" ] && unresolved=$((unresolved+1))
    done < <(grep -ohE "$PATH_RE" "$note" 2>/dev/null | sort -u)
  done
done
echo "citation drift: drift=$drift gone=$gone unresolved=$unresolved"
exit 0
