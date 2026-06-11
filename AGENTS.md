# agent-knowledge-hub

A personal, agent-maintained knowledge monorepo. Holds any number of knowledge hubs, each a set of dense, code-grounded notes that coding agents read (to prime on a topic) and write (to capture durable findings). This file is the umbrella charter: how hubs are organized and isolated. Each hub has its own `AGENTS.md` with that hub's domain context and note rules.

Canonical vocabulary for the whole system is in `CONTEXT.md`. Use those terms: the **monorepo** (this repo) vs a **sub-hub** (a child under `hubs/`), **note** vs **work**, never a bare "hub" for a specific referent.

## Hub Isolation

Hubs are isolated from each other. Every operation (read, store, lint, query) targets a single hub at a time.

### Determining the Active Hub

1. If the user names a hub, use that.
2. If the working directory is inside a hub (`hubs/<name>/`), use that hub.
3. If there is only one hub in `hubs/`, use it as the default.
4. If there are multiple hubs and no clear signal, ask which hub before doing anything.

### Path Rules

All content operations happen inside the active hub:
- Notes: `hubs/<active>/*.md`
- Project research: `hubs/<active>/works/<project>/`
- Hub index: `hubs/<active>/INDEX.md`
- Hub charter: `hubs/<active>/AGENTS.md`

Never write one hub's content into another hub's directory. Cross-hub references use a relative path (`../<other-hub>/<note>.md`), never a bare filename.

### Multi-Hub Operations

If asked to run something across all hubs (e.g. "lint all hubs"), run sequentially, one hub at a time, and present results grouped by hub.

## Working in a Hub

1. Read the hub's `AGENTS.md` first. It has the domain context, note voice, and rules for that specific hub.
2. Read the hub's `INDEX.md` to find existing notes before creating a new one.
3. The umbrella owns shared machinery: `template/` (new-hub starter), `scripts/hub` (CLI), `scripts/checks/` (bookkeeping checks). Hubs inherit these; they do not duplicate them.

## Sub-hubs

The monorepo holds any number of sub-hubs; the set grows with the domains you work in. Each sub-hub's `AGENTS.md` charter declares its scope. This template ships one example sub-hub (`hubs/example/`); read it for the style, then clear it and create your own.

### Routing (which sub-hub does a finding belong in)

Routing is charter-driven, not hardcoded:

1. Match the finding against each sub-hub's charter (its scope declaration). File it in the hub whose charter claims it.
2. If two charters could claim it, the charters themselves should declare which wins (each charter carries its own scope test and tie-breakers). Never split one topic across two hubs; one canonical note.
3. **If no charter fits, do not force it.** Suggest creating a new sub-hub: propose a name and a one-line scope, then `./scripts/hub create <name>`. A finding that has no home is a signal the hub set should grow. After creating a sub-hub, fill its charter's scope line and add it to the root `INDEX.md` (the sub-hub catalog).

`store-to-hub` implements exactly this: classify against charters, route, or propose a new sub-hub.

## Notes vs works

Two kinds of content, two lifecycles:

- A **note** is atomic, concept-oriented, and useful across projects. It lives at a sub-hub root and is findable via `INDEX.md`. (Evergreen-note style.)
- A **work** (`works/<slug>/`) is a goal-bound project: a linear story across numbered files, plus status. Routed to a sub-hub by the same charter matching as notes.

When an investigation done inside a work is reusable beyond that project, **promote** it to a note (so it is findable) and link it from the work, rather than burying it in the project folder. The test: if future-you would search for it independent of the project, it is a note; otherwise it lives in the work. See `CONTEXT.md`.

## Context sources (the full context layer)

This monorepo is one leg of a wider context layer. When working, pull from the right leg instead of re-deriving:

1. **Hubs (here):** curated domain knowledge. Notes + works, retrieved via `/load-context` (INDEX then TL;DR then body; never bulk-load).
2. **Live sources (MCP, CLIs):** external state that changes: telemetry, tickets, docs, chat. Authoritative for anything that changes outside this repo; a hub note caches a finding, the live source verifies it is still true.
3. **Harness capabilities:** passive session memory (if you run one), skills, browser tools.

Rule of thumb: knowledge that compounds goes in a hub; state that changes stays behind live sources and gets cited, not copied wholesale.

## Working in a session

A session runs in four phases:

1. **Prime.** `/load-context <topic>` pulls existing hub notes (one-liners + TL;DRs).
2. **Gather.** Do the work. Capture provenance as you go (file:line, thread/ticket URLs, queries). A note without cited sources is incomplete.
3. **Capture.** When a finding clears the bar (30+ minutes, reusable, non-obvious), `/store-to-hub`. Offer this proactively after a substantive investigation.
4. **Maintain.** `/hub-lint` periodically, and before trusting notes for important work. A weekly scheduled run of `scripts/hub-maintenance.sh` automates the deterministic half.

## CLI

```bash
./scripts/hub list              # list all hubs with note counts
./scripts/hub create <name>     # scaffold a new hub from template/
```

## Harness compatibility

This file (`AGENTS.md`) is the contract, and it is the open standard most coding agents read natively: Claude Code, Codex, Cursor, Copilot, Gemini CLI, Aider, and others (`CLAUDE.md` is a redirect). The skills (`/load-context`, `/store-to-hub`, `/hub-lint`) are Claude Code / Codex conveniences installed by `./install.sh`; every operation underneath is harness-agnostic and any agent can run it directly:

```bash
node skills/load-context/bin/match.mjs "<topic>" --json    # retrieve
node skills/store-to-hub/bin/classify.mjs "<topic>" --json # classify + dedup
scripts/checks/hub-lint.sh hubs/<name>                       # health gate
scripts/checks/append-log.sh <hub> <op> <note> "<why>"       # log a write
```

Skills resolve the hub root from the `HUB_ROOT` env var (written by `install.sh`).

## Rules

1. Read before writing. Check the hub's `INDEX.md` and related notes before creating a file. Update an existing note instead of forking.
2. Cite code, do not paraphrase. Include file paths with line ranges; quote the relevant lines.
3. Verify before asserting. A grep hit is a lead, not an answer. Open the file before claiming anything.
4. Dense, opinionated, code-grounded prose. No filler.
5. Every new or renamed note gets an `INDEX.md` entry in its hub.
6. Never store sensitive data (see `CONTEXT.md`): cite the pointer, never the payload.
