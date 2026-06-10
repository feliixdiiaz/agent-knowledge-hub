---
name: load-context
description: Load relevant domain knowledge from the agent-knowledge-hub sub-hubs (however many exist; discovered dynamically) to spin up work on a topic. Use when resuming a project after a break, or when the user says "load context", "load-context", "spin up on X", "get me back into X", or "/load-context <topic>". Retrieves hub notes by topic via INDEX match, surfaces TL;DRs as a jump-start, dives into full notes on demand.
---

# load-context

Resume work fast by pulling the right hub knowledge for a topic, without dumping every note (bloat) or hand-feeding files. Scoped to hub **domain knowledge** only.

**The INDEX-first read-ladder is the skill:** one read of `INDEX.md` triages every note, TL;DRs confirm relevance, full bodies load only on demand. That ordering is what keeps context lean. Work-state and past-session history have other homes (your session-memory layer); the hub holds domain knowledge only.

## Input

A topic, e.g. `/load-context patient consent`. The topic may be precise, vague ("something about patient... content?"), or absent. All three are valid; only the retrieval stage differs. Topic inference from the git branch is a future addition, not v1.

## Procedure (two-stage retrieval)

Retrieval is two-stage by design: a deterministic fast path, and a semantic fallback that exploits the INDEX being tiny (one read covers every note). Never let a keyword miss become a silent zero.

1. **Fast path** for a crisp topic. Run the matcher (deterministic, cheap, testable):

   ```bash
   node "${HUB_ROOT:-$HOME/workspace/agent-knowledge-hub}"/skills/load-context/bin/match.mjs "<topic>" --json
   ```

   It scans each hub's `INDEX.md`, scores entries by exact query-term hits, and returns the top matches with `summary`, `tldr`, and the full-note `path`. When exact matching finds nothing, it automatically falls back to **fzf** (`fzf --filter`, optional dependency; skipped silently if not installed) over the INDEX lines, and marks those results `matchType: "fuzzy"`. Present fuzzy results as "did you mean", not as confident hits.

2. **Semantic stage, mandatory when any of these hold:** the topic is vague or hedged ("there was this work about...", "I'm not sure what it was called"), the matcher returns zero results even after the fzf fallback, or the results look off for the question asked. Read EVERY sub-hub's `INDEX.md` in full (they are one-liners; this is a few hundred tokens by design) and judge semantically: present the 2-4 plausible candidates as "did you mean", with their one-liners. The user's fuzzy memory plus your reading of the whole catalog beats any keyword trick.

3. **No topic at all: browse mode.** Do not ask for "one short phrase". Show the catalog: each sub-hub with its note one-liners and works list, straight from the INDEXes. Let them point.

4. **Jump-start:** present the selected notes, their one-line summaries, and TL;DRs. Keep it tight, this is orientation, not the full dump.

5. **Dive:** offer to read the full body of specific notes. Read a note in full only when the work actually needs it. For directory entries (e.g. `works/patient-consent/`), list the files in that dir and offer to open specific ones.

Never silently return nothing: the semantic stage or browse mode always produces candidates or the catalog.

## Hubs

Defaults to every sub-hub under `$HUB_ROOT/hubs/` (`~/workspace/agent-knowledge-hub` if unset). New sub-hubs are picked up automatically. Override with the `LOAD_CONTEXT_HUBS` env var (colon-separated absolute paths).

## Optional, on top of the hub

- The hub is the curated layer; claude-mem is the passive episodic layer (see `docs/adr/0002-claude-mem-boundary-and-session-lifecycle.md` in the hub repo). For a richer prime, you may also consult claude-mem `mem-search` ("did we solve this before?") and `tail` the active hub's `log.md` for recent activity. These are optional context, not part of the deterministic match.

## Notes

- Selection is deterministic keyword matching over `INDEX.md`, so it is fast, cheap, and testable. The matcher is hub-only by design; claude-mem stays out of the scored retrieval. Quality depends on the hub `INDEX.md` one-liners + per-note `## TL;DR` staying current.
- Tests: `cd ~/.claude/skills/load-context && node --test`.
- Eval (selection quality vs real hubs): `node evals/run.mjs`.
