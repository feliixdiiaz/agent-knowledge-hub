# agent-knowledge-hub

A template for a personal, agent-maintained knowledge monorepo: dense, code-grounded notes that your coding agents read to prime on a topic and write to capture durable findings, so investigations compound instead of evaporating when the session ends.

Three skills drive it: read (`/load-context`), write (`/store-to-hub`), maintain (`/hub-lint`). Works with **Claude Code, Codex, and Cursor** (`AGENTS.md` is the shared contract; the skills install into Claude Code and Codex, and every operation underneath is a plain CLI any agent can run).

Open `docs/hub-guide.html` for the full why/how/workflow.

## How it works

```mermaid
flowchart TB
    classDef store fill:#f7f2ed,stroke:#a7988a,color:#141312
    classDef act fill:#fff,stroke:#ea2c00,color:#141312
    classDef gate fill:#fff,stroke:#02745f,color:#141312

    A["agent session<br/>(Claude Code / Codex / Cursor)"]:::act

    subgraph READ ["prime: /load-context &lt;topic&gt;"]
        M["match.mjs: exact keyword match<br/>over INDEX one-liners"]:::act
        FZ["empty? fzf fuzzy fallback<br/>'did you mean'"]:::act
        T1["tier 1: INDEX one-liner"]:::store
        T2["tier 2: note TL;DR"]:::store
        T3["tier 3: full note body<br/>only on demand"]:::store
        M --> FZ
        M --> T1 --> T2 --> T3
    end

    subgraph HUB ["the monorepo"]
        IDX["hubs/&lt;name&gt;/INDEX.md<br/>one line per note"]:::store
        N["notes: atomic findings<br/>TL;DR + cited sources"]:::store
        W["works/&lt;slug&gt;/: project folders<br/>reusable findings promoted to notes"]:::store
        LOG["log.md: append-only ops record"]:::store
        CH["AGENTS.md charter per sub-hub<br/>declares its scope"]:::store
    end

    subgraph WRITE ["capture: /store-to-hub"]
        C["classify.mjs: match finding<br/>against every charter"]:::act
        D{"a charter<br/>claims it?"}
        P["propose diff,<br/>wait for confirm"]:::gate
        NEW["propose a NEW sub-hub<br/>scripts/hub create"]:::act
        WR["write note + INDEX line<br/>+ log entry + lint"]:::act
        C --> D
        D -- yes --> P --> WR
        D -- no --> NEW --> P
    end

    subgraph MAINTAIN ["maintain: scheduled weekly + on demand"]
        SW["hub-maintenance.sh<br/>deterministic, ~0.3s"]:::gate
        G["hub-lint.sh gate:<br/>orphans, broken links, secrets,<br/>stale hubs, stalled works"]:::gate
        CD["citation-drift.sh:<br/>cited code changed or gone upstream?"]:::gate
        SNAP["git snapshot + notify<br/>only on regressions"]:::gate
        LLM["/hub-lint LLM pass on demand:<br/>contradictions, duplicates, stale claims"]:::act
        SW --> G --> SNAP
        SW --> CD --> SNAP
    end

    A -- "resume a topic" --> M
    T1 -.reads.-> IDX
    A -- "durable finding" --> C
    C -.reads.-> CH
    WR --> N
    WR --> IDX
    WR --> LOG
    SW -.checks.-> HUB
    LLM -.judges.-> N
```

The loop in one sentence: **prime** pulls the smallest useful slice of past knowledge (index line, then TL;DR, then body), **capture** routes a new finding to whichever sub-hub charter claims it (or grows a new one) behind a propose-confirm gate, and **maintain** runs deterministic hygiene on a schedule so the knowledge stays trustworthy without anyone remembering to check.

## Get started

Use this template (or clone), then:

```bash
cd ~/workspace/agent-knowledge-hub && ./install.sh
```

`install.sh` symlinks the skills into `~/.claude/skills/` and `~/.codex/skills/` (restart the harness after), makes the hooks runnable, and records `HUB_ROOT`. Optional: `brew install fzf` enables typo-tolerant retrieval.

The `hubs/example/` sub-hub ships with two sample notes; read them for the format, then clear it and create your own:

```bash
./scripts/hub create <your-hub>
```

Then edit `hubs/<your-hub>/AGENTS.md`: one line of scope (what findings this hub claims) is enough to start.

Skills-only install (no clone): `npx skills add <your-fork> --all` distributes them to every supported harness via the [skills CLI](https://github.com/vercel-labs/skills).

## Layout

```
hubs/<name>/     a full hub: AGENTS.md + INDEX.md + log.md + notes (+ works/)
template/        starter scaffold for a new hub
scripts/hub      CLI: create, list
scripts/         hub-maintenance.sh (weekly sweep), citation-drift.sh
skills/          load-context, store-to-hub, hub-lint (symlinked by install.sh)
install.sh       setup
.claude/hooks/   deterministic checks: validate-note, check-index, append-log, hub-lint
docs/            note-format.md, hub-guide.html, adr/ (design rationale)
```

## The model in five lines

1. A **note** is atomic, cross-project, and findable: one INDEX line + a `## TL;DR` + a code-cited body (`docs/note-format.md`).
2. A **work** is a goal-bound project folder; reusable findings get **promoted** to notes.
3. **Routing is charter-driven**: each sub-hub's `AGENTS.md` declares its scope; no fit means create a new sub-hub.
4. Retrieval is a ladder: INDEX one-liners, then TL;DRs, then full bodies, never a bulk dump. Exact match first, `fzf` fuzzy fallback, agent judgment last.
5. **Maintenance is scheduled, not remembered**: `scripts/hub-maintenance.sh` (weekly via launchd/cron) lints every hub, snapshots to git, checks citation drift, and notifies only on regressions.

## Maintenance

Wire `scripts/hub-maintenance.sh` into launchd/cron weekly. It runs the deterministic gate over every sub-hub, auto-commits a git snapshot, and reports citation drift (notes citing code that changed or vanished upstream in your local clones). The LLM pass (`/hub-lint`) stays on demand.

## Design rationale

`docs/adr/` records why the system is shaped this way (no frontmatter, INDEX as the retrieval surface, log + git, charter-driven routing, the maintenance loop), with sources (Karpathy's LLM-wiki, Anthropic's context-engineering guidance, PARA/evergreen notes, Letta's context repositories). Read `0001` first.
