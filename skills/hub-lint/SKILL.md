---
name: hub-lint
description: Health-check an agent-knowledge-hub sub-hub for rot. Use when the user says "lint the hub", "hub-lint", "check the hub", "/hub-lint", or before relying on hub notes for important work. Runs the deterministic gate first (orphans, broken links, missing INDEX/log entries, em dashes, missing TL;DRs), then an LLM pass for what scripts cannot see (contradictions between notes, duplicate topics, stale/hedged claims). Propose-only, never auto-fixes.
---

# hub-lint

Catch knowledge rot before it produces confident wrong answers. The freshness loop is the highest-value maintenance in a knowledge hub (a stale note read confidently is worse than no note).

**The deterministic gate is the skill.** Run it first, exhaustively. The LLM pass only flags what a script genuinely cannot see (contradictions, duplicate topics, hedged claims). Notes are judged against the canonical shape in `~/workspace/agent-knowledge-hub/docs/note-format.md`.

## Input

A sub-hub name: `/hub-lint <sub-hub>`. No arg means lint every sub-hub under `~/workspace/agent-knowledge-hub/hubs/`, one at a time, results grouped per hub.

## Procedure

1. **Deterministic gate first (the CI pass, no judgment):**

   ```bash
   ~/workspace/agent-knowledge-hub/.claude/hooks/hub-lint.sh ~/workspace/agent-knowledge-hub/hubs/<hub>
   ```

   It reports BLOCK (note not in INDEX, INDEX entry with no file, broken relative link) and WARN (em dash, missing log entry, missing `## TL;DR`), exiting nonzero only on BLOCK. Relay its output. Do not re-derive these by hand; the script is the source of truth for them.

2. **LLM pass (only what bash cannot see).** Read lean: start from `INDEX.md` one-liners + each note's `## TL;DR`, cluster notes by topic, and full-read **only** clusters with 2+ notes or notes the gate flagged. Do not dump every body. Then flag:
   - **Contradictions:** two notes asserting opposite things (e.g. one says "run X", another says "X is harmful"). High severity.
   - **Duplicate topic:** two notes covering the same thing (a boundary-rule violation; one should be canonical). Medium.
   - **Stale / hedged claims:** "I think", "probably", "unverified", or a claim about code that may have moved. Low. Emit as "verify note X's claim about Y against current code", a suggestion, not a verdict. Do NOT re-read live code/Firestore here; that is a separate investigation, out of scope for a lint.
   - **Buried reusable finding:** a file inside a `works/<slug>/` project that reads like atomic, concept-oriented knowledge useful beyond that project, but was never promoted to a root note. Low. Suggest promoting it (via `store-to-hub`) and linking it from the work. This keeps reusable investigations findable. Scan a couple of work files' headings, not every line.
   - **Misrouted content:** a note or `works/<slug>/` project whose topic does not fit its sub-hub's charter. Low. Suggest moving it to the hub whose charter claims it, or creating a new sub-hub if none does.

3. **Report, propose-only.** Group findings by severity. For each, name the notes, quote the conflicting lines, and suggest an action. **Never auto-fix.** If the user approves a fix, apply it through `store-to-hub` (which logs + re-lints), not by silent edit.

## Notes

- BLOCK findings mean retrieval or navigation is broken; fix those before trusting the hub.
- WARN findings (em dash, missing log/TL;DR) are a burn-down list, not a wall; pre-existing notes predate the log on purpose.
- This skill reads; it does not write. Writes go through `store-to-hub`.
- Run order matters: gate before LLM, so the LLM pass can focus on flagged clusters and skip the rest (keeps its own context lean).
