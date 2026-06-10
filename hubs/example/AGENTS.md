# example

Example sub-hub demonstrating the note format and conventions. Scope: replace this line with a one-line scope declaration (what kinds of findings this hub claims), plus any tie-breakers against your other sub-hubs.

Part of the `agent-knowledge-hub` monorepo. See the root `AGENTS.md` for hub isolation rules. This file is this hub's charter: its domain, note voice, and rules.

## Structure

- **`*.md`**: Standalone topical notes. One file per topic, kebab-case filename. A topic is something you learned or investigated that future-you will want to find again.
- **`works/<project-slug>/`**: Active multi-step project research. Numbered files (`00-context.md`, `01-research-findings.md`, ...) capture the linear story of a project. When it stabilizes, add a `## TL;DR` to the top of its lead file (`00-context.md`, or a `README.md` in the folder). The folder stays as the durable record. Do not migrate it into a root note.
- **`INDEX.md`**: One-line summary of every note. First place to look when finding a note by topic.
- **`AGENTS.md` / `CLAUDE.md`**: This charter. `CLAUDE.md` redirects to `AGENTS.md`.

## What makes a good note

Canonical shape: `../docs/note-format.md` (TL;DR, code-grounded body, verified-vs-inferred, sources, related). Add any hub-specific requirements below this line for example.

## When to add a new note

File back when:
- You spent more than 30 minutes piecing something together that was not in one place.
- You answered a question that came up before or will come up again.
- The investigation revealed a non-obvious pattern, gotcha, or pipeline a future investigation will start from.

Do NOT file back:
- One-off lookups, status checks, fix-and-forget bugs.
- Things already captured in another note. Update the existing note instead of forking.

## Bookkeeping

After adding or substantially changing a note:
1. Add or update its entry in `INDEX.md`.
2. Reference related notes inline by filename when the relationship is non-obvious.

No frontmatter. No log file. Keep overhead minimal so friction never blocks a write.

## Rules

1. Read before writing. Check `INDEX.md` and related notes first. Update an existing note instead of forking.
2. Cite code, do not paraphrase. Include file path and line range; quote the relevant lines.
3. Verify before asserting. A grep hit is a lead, not an answer. Open the file before claiming anything.
4. Match existing style. Dense, code-grounded prose. No em dashes.
5. Every new or renamed note gets an `INDEX.md` entry.

## ADRs

Use `docs/adr/` for decisions that are hard to reverse, surprising without context, and the result of a real trade-off. Skip the ADR if any of the three is missing.
