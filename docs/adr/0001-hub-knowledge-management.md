# 0001: Hub knowledge-management stance

Status: Accepted (2026-06-09)

## Context

abridge-hub is a personal, LLM-maintained knowledge monorepo (umbrella + sub-hubs), retrieved by the `load-context` and `store-to-hub` skills and health-checked by `hub-lint`. The dominant patterns in the wild (Karpathy LLM-wiki, Letta context repositories, the Udemy teach-and-learn hub it was seeded from) push toward per-file YAML frontmatter, git-versioned memory, and a deep `docs/` taxonomy. We researched those and deliberately chose a leaner shape. This records why, because a future reader (or agent) will otherwise assume the conventional choices were just missed.

## Decision

1. **No per-note frontmatter.** The retrieval description lives in the `INDEX.md` one-liner (progressive-disclosure Layer 1) and the per-note `## TL;DR` (Layer 2). Filenames are kebab-case and descriptive (the cheap navigational signal).
2. **`log.md` per sub-hub as the change record, not git (for now).** Append-only, one line per op: `- <date> | <op> | <note> | <what+why>`, ops `{add, update, merge, delete, rename}`, newest at bottom. Written by `append-log.sh` (so the format is consistent) and by `store-to-hub` on every write.
3. **Lint is two pieces, deterministic-first.** `hub-lint.sh` is the mechanical gate (orphans, dangling INDEX/links = BLOCK; em dash, missing log entry, missing TL;DR = WARN). The `hub-lint` skill runs that gate, then adds an LLM pass only for what a script cannot see (contradictions, duplicate topics, hedged/stale claims). Propose-only.
4. **Boundary routing rule** (in the umbrella `AGENTS.md`): dev-exp = "would the answer change if I switched laptops" (env, tooling, auth, IDE, CLI); eng-investigations = how Abridge product systems behave, grounded in code. One topic never splits across hubs. `store-to-hub` classifies on this rule.

## Alternatives considered

- **Per-note frontmatter (`tags`/`related`/`sources`) + matcher wired to read it.** Rejected for now: the matcher reads INDEX + TL;DR, never bodies/frontmatter, so frontmatter is redundant with INDEX and costs N file reads to triage where INDEX costs 1. Retrieval is already 100% on the eval, so there is no measured gap to justify the build + per-note maintenance. Letta uses frontmatter because its filetree is always in the system prompt; ours is not.
- **Git-versioned memory (Letta).** The strongest alternative: free history (replaces `log.md`), real undo, diff-based change detection, worktree concurrency. Deferred by explicit choice, not oversight. Consequence captured below. Re-open when undo/history pain is felt.
- **Full Udemy `docs/` taxonomy** (architecture/research/decisions/proposals/...). Rejected: that serves a multi-author team wiki; this is personal investigation notes. The 9-way "where does this go" decision fights the minimal-friction principle. We keep flat notes + `works/<project>/` + `docs/adr/`.

## Consequences

- Cheapest possible write path; the friction never blocks a note. Retrieval stays a single INDEX read plus targeted TL;DRs.
- Without git, the log can only be guaranteed complete for tool-mediated writes (`store-to-hub`). Hand-edits are not auto-detected; `hub-lint` can only verify a note has at least one log entry, not that every change was logged. Accepted because hand-edits are rare. If that stops being true, adopt git (which subsumes the log).
- Frontmatter-based features (tag search, an explicit note graph) are not available. If a future retrieval gap is measured, revisit alternative 1.

## Sources

- Karpathy LLM-wiki: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
- Letta context repositories: https://www.letta.com/blog/context-repositories
- Progressive disclosure as a system-design pattern: https://www.newsletter.swirlai.com/p/agent-skills-progressive-disclosure
- Enterprise LLM-wiki scaling (freshness loop): https://falconer.com/guides/enterprise-llm-wiki-karpathy/
