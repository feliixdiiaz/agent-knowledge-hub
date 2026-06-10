# agent-knowledge-hub

Glossary for the knowledge system. Canonical vocabulary so the skills (load-context, store-to-hub, hub-lint) and the charters use one word per concept. Devoid of implementation detail; see `AGENTS.md` and `docs/adr/` for how things work.

## Language

### Structure

**monorepo**:
The umbrella repo holding everything: charters, skills, the `hubs/` tree, docs.
_Avoid_: "the hub" (for the whole repo), "the vault".

**sub-hub**:
One self-contained knowledge area under `hubs/`, with its own `AGENTS.md`, `INDEX.md`, and `log.md`.
_Avoid_: "hub", "the hub", "folder".

**hub**:
Generic category word only ("a hub is an agent-maintained note set"). Never a specific referent. In any concrete sentence, name the monorepo or the sub-hub.

**charter**:
A sub-hub's `AGENTS.md`: its domain context, note voice, scope test, and rules.
_Avoid_: "config", "readme".

**INDEX**:
The one-line-per-note catalog at a sub-hub root (`INDEX.md`). The first retrieval layer; what load-context matches against.
_Avoid_: "table of contents", "index file".

**log**:
A sub-hub's append-only operations record (`log.md`), one line per write.
_Avoid_: "changelog", "history".

### Content

**note**:
A standalone, atomic, concept-oriented finding: one idea, durable, useful across projects, findable via `INDEX.md`. A sub-hub-root `*.md`, kebab-case, leads with `## TL;DR`, code-grounded with cited sources. (Cf. evergreen notes: atomic, concept-oriented, cross-project.)
_Avoid_: "doc", "entry", "page", "article".

**work**:
A project: goal-bound, multi-step, with a completion state. A `works/<slug>/` folder holding the project's linear story (numbered files) plus status. Routed to a sub-hub by the same charter matching as notes. The folder persists; reusable findings inside it are promoted to notes and linked, rather than buried. (Cf. a PARA "project" and a Map-of-Content that links to atomic notes.)
_Avoid_: "project note", "project folder".

**promote**:
Lift a reusable finding out of a work into a standalone note (so it lands in `INDEX.md` and is findable across projects); the work then links to it. Project-specific material stays in the work.
_Avoid_: "extract", "graduate".

**TL;DR**:
The mandatory 3-to-5 line summary at the top of a note. The second retrieval layer, surfaced before the full body.
_Avoid_: "summary", "abstract", "overview".

**canonical note**:
The single note that owns a topic. One topic is never split across sub-hubs; duplicates are merged into the canonical one.
_Avoid_: "primary", "master", "source-of-truth note".

### Routing

**routing**:
Matching a finding to the sub-hub whose charter claims it. Charter-driven: each sub-hub's `AGENTS.md` declares its scope and its tie-breakers; overlaps are resolved by the charters, not by a global rule. If no charter fits, create a new sub-hub rather than forcing a fit.
_Avoid_: "categorization", "bucketing".

### Safety

**sensitive data** (never in the hub):
Define this term for YOUR context and enforce it. The pattern: cite the pointer, never the payload. Opaque system identifiers, schema, configs, and aggregates are fine; personal data, regulated content (e.g. patient information under HIPAA, customer PII), and credentials are never. Hand-stripping names does not anonymize content. Credentials specifically: cite where a value lives (password manager item, Keychain entry, env var name), never the value; the write gate rejects secret-shaped strings.
_Avoid_: pasting any payload, "anonymized" quotes.

### Workflow

**prime**:
Pull existing sub-hub knowledge for a topic at the start of work (`/load-context`).
_Avoid_: "load", "warm up".

**capture**:
File a cleared-the-bar finding into the right sub-hub as a note (`/store-to-hub`).
_Avoid_: "save", "store" (loosely), "dump".

**maintain**:
Health-check a sub-hub for rot before trusting it (`/hub-lint`).
_Avoid_: "audit", "review" (loosely).
