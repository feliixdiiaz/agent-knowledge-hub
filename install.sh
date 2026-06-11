#!/bin/bash
# install.sh - activate the agent-knowledge-hub skills + hooks after cloning.
#
# Symlinks the three skills into ~/.claude/skills so the repo is the single
# source of truth (edit in skills/, changes are live immediately). Makes the
# hooks executable. Idempotent. Any existing real skill dir is backed up to
# <name>.pre-install.bak first, so nothing is lost.
#
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.claude/skills"
mkdir -p "$DEST"

for s in load-context store-to-hub hub-lint hub-doctor; do
  target="$DEST/$s"
  if [ -L "$target" ]; then
    rm -f "$target"
  elif [ -e "$target" ]; then
    mv "$target" "$target.pre-install.bak"
    echo "backed up existing $s -> $s.pre-install.bak"
  fi
  ln -s "$ROOT/skills/$s" "$target"
  echo "linked skill: $s"
done

chmod +x "$ROOT"/scripts/checks/*.sh "$ROOT"/scripts/hub 2>/dev/null || true
echo "hooks + CLI executable"

# Record the hub root so skills resolve paths portably (matchers read $HUB_ROOT).
PROFILE="$HOME/.zshrc"
if [ -f "$PROFILE" ] && ! grep -qE '(^|[^A-Z_])HUB_ROOT' "$PROFILE"; then
  printf '\n# knowledge hub\nexport HUB_ROOT="%s"\n' "$ROOT" >> "$PROFILE"
  echo "added HUB_ROOT=$ROOT to $PROFILE (open a new shell to load it)"
fi
# Codex: same skills, same source of truth (Codex reads ~/.codex/skills natively)
if [ -d "$HOME/.codex" ]; then
  mkdir -p "$HOME/.codex/skills"
  for s in load-context store-to-hub hub-lint hub-doctor; do
    target="$HOME/.codex/skills/$s"
    if [ -L "$target" ]; then rm -f "$target"
    elif [ -e "$target" ]; then mv "$target" "$target.pre-install.bak"; echo "backed up existing codex $s"
    fi
    ln -s "$ROOT/skills/$s" "$target"
    echo "linked codex skill: $s"
  done
fi

command -v fzf >/dev/null 2>&1 || echo "note: fzf not found; fuzzy retrieval fallback disabled (optional: brew install fzf)"
echo
echo "Done. Try:  /load-context <topic>   /store-to-hub   /hub-lint"
echo "The hubs/ here are example notes. Read them for the style, then clear them"
echo "and run ./scripts/hub create <your-hub> to start your own."
