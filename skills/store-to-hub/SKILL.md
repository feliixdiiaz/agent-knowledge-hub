---
name: store-to-hub
description: Capture a finding into the right agent-knowledge-hub sub-hub as a note, appending to an existing note or creating a new one, and proposing a brand-new sub-hub when no existing charter fits. Use when the user says "store this", "store to hub", "save this to the hub", "file this", "remember this in the hub", "/store-to-hub", or after an investigation produces a durable learning worth keeping. Classifies the target sub-hub from each hub's charter, dedupes against the hub INDEX, and always shows a diff for confirmation before writing.
---

# store-to-hub

File a durable finding into the correct `agent-knowledge-hub` sub-hub. Picks the hub, decides append-vs-new-note, and writes only after you confirm a diff. Never silently corrupts a note.

**Propose-confirm is the skill.** Classification and dedup are mechanical; the one rule that must never break is showing the full diff and waiting. Never write without it.

New notes follow the canonical shape in `docs/note-format.md` in the hub repo (TL;DR first, code-grounded body, verified-vs-inferred, sources, related). Read it before authoring.

## Input

Two modes, both supported:
- **(a) Synthesize from conversation:** no text given. Distill the finding from what was just learned in this session into a hub-voice note (TL;DR + code-grounded body).
- **(b) Explicit blob:** the user pasted text / a finding. File that content, reshaped to hub voice. Do not drop technical substance.

If the topic is ambiguous, ask for one short phrase before classifying.

## Procedure

1. **Classify (deterministic):**

   ```bash
   node "${HUB_ROOT:-$HOME/workspace/agent-knowledge-hub}"/skills/store-to-hub/bin/classify.mjs "<topic>" --json
   ```

   Returns `candidateHubs` (each sub-hub name + its `AGENTS.md` charter snippet) and `dedupHits` (existing notes whose INDEX summary overlaps the topic, a candidate list, not a verdict).

2. **Pick the target sub-hub, or decide none fits.** Read the `candidateHubs[].charter` snippets (returned for every sub-hub, however many exist) and match the finding to the hub whose charter claims it. Charters carry their own scope tests and tie-breakers; do not assume any fixed set of hubs. If two charters could claim it, the charters decide. If NO charter claims it, go to step 6 (propose a new sub-hub) instead of forcing a fit. If genuinely unsure between two, ask.

3. **Decide append vs new note.**
   - If a `dedupHits` note clearly covers the same topic, propose **appending** to it: read the existing note, show the exact section and the lines you would add.
   - Otherwise propose a **new note** following `docs/note-format.md`: kebab-case filename, the skeleton (TL;DR, body, verified-vs-inferred, sources, related), matching that hub's voice.

4. **Propose and confirm (mandatory).** Print the full new-note content or the exact append diff and wait for explicit confirmation. NEVER write without it. Be extra strict on appends: show enough surrounding context that the user can see you are not clobbering or duplicating existing content.

5. **On confirm, write + bookkeep** (in this order):
   - For a NEW note, gate the content first: `"${HUB_ROOT:-$HOME/workspace/agent-knowledge-hub}"/.claude/hooks/validate-note.sh <note-path>` must pass (strict: a new em dash is a hard fail). Fix before writing the final file.
   - Write the note (new file) or apply the append.
   - Add or update the note's one-line entry in that hub's `INDEX.md`.
   - Append a log entry: `"${HUB_ROOT:-$HOME/workspace/agent-knowledge-hub}"/.claude/hooks/append-log.sh <hub-dir> <op> <note> "<one-line what+why>"` (op = `add` | `update` | `merge` | `delete` | `rename`).
   - Run the deterministic gate and report it: `"${HUB_ROOT:-$HOME/workspace/agent-knowledge-hub}"/.claude/hooks/hub-lint.sh <hub-dir>`. A BLOCK finding means you broke INDEX or a link; fix it immediately. WARN findings are fine to leave.

6. **No hub fits: propose a new sub-hub.** A finding with no home is a signal the hub set should grow, that is the point of the monorepo. Propose: a kebab-case hub name, a one-line scope for its charter, and the command (`"${HUB_ROOT:-$HOME/workspace/agent-knowledge-hub}"/scripts/hub create <name>`). On confirm, create it, fill in the charter scope, then file the note there (steps 4-5 as normal). If the user prefers an existing hub instead, respect that. Never force a note into a hub whose charter does not claim it.

## Notes

- Hub discovery and dedup share the `load-context` matcher (`bin/classify.mjs` imports `match` from `../../load-context/bin/match.mjs`), so a note this skill files is findable by `load-context` immediately.
- Override the hubs root with `STORE_TO_HUB_ROOT` (absolute path to a `hubs/` dir) for testing.
- Tests: `cd ~/.claude/skills/store-to-hub && node --test`.
- Eval (dedup recall vs real hubs): `node evals/run.mjs`.
