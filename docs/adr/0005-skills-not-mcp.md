# 0005: Cross-platform via skills + CLIs, not an MCP server (deferred)

Status: Accepted (2026-06-10)

## Context

Goal: the hub should be usable as the agent's knowledge layer on any platform, all the time. An MCP server looked like the obvious portable backbone: every major harness speaks MCP, tool descriptions sit in every session (structural awareness), and a server could enforce the propose-confirm write gate in code rather than prompt. A 4-tool surface was designed (`hub_search`, `hub_read`, two-phase `hub_store` with propose-time validation, content-hash confirm, ephemeral proposals, atomic bookkeeping, plus `hub_lint`).

## Decision

**Do not build the MCP server now.** The platforms actually in use (Claude Code, Codex, Cursor, and most coding agents) all have shell access, so the existing mechanism already covers them:

1. `AGENTS.md` is the in-repo contract (read natively by most agents).
2. The skills carry the workflow on Claude Code and Codex; the skills CLI distributes the packaging further.
3. The plain CLIs (`match.mjs`, `classify.mjs`, the hooks) work from any agent that can run a command.
4. Awareness outside the repo comes from a short pointer in each platform's global instructions (see README, "Make your agents aware of it").

An MCP server would add an SDK dependency, an install step, a server process, and per-platform registration to deliver capabilities these agents already have. That is complexity without new reach.

## Revisit when

Either trigger justifies building it, using the designed blueprint above (official `@modelcontextprotocol/sdk`, stdio, 4 tools, server-enforced two-phase writes):

1. **A shell-less platform needs the hub** (e.g. a web/mobile assistant that can only reach local context through MCP).
2. **Autonomous agents write to the hub** (the queue phase): prompt-level propose-confirm is not enforceable on unattended agents; the server-side gate is.

## Consequences

- Zero new dependencies or processes today; the template stays clone-and-run.
- Write safety remains a prompt convention plus deterministic validation hooks; acceptable while a human is in every write loop, insufficient for unattended agents (hence the revisit trigger).
- Awareness on new platforms is a one-paragraph paste rather than a config entry; slightly more manual, much simpler.

## Related

ADR [0004](0004-maintenance-loop.md) (deterministic-first), README "Make your agents aware of it".
