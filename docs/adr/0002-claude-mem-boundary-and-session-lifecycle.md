# 0002: claude-mem boundary and the session lifecycle

Status: Accepted (2026-06-09)

## Context

The hub now has read (`load-context`), write (`store-to-hub`), and maintain (`hub-lint`). Two operational questions were unresolved: what a working session looks like end to end, and how knowledge actually gets gathered into the hub. The complication is that claude-mem is already installed and auto-captures observations every session, so the hub is not the only memory layer. Without a clear boundary, capture is either redundant with claude-mem or rots because nobody remembers to do it.

## Decision

**Two memory layers, different jobs, not competing.**

| | claude-mem | the hub |
|---|---|---|
| capture | passive, automatic, every session | deliberate, on `/store-to-hub` |
| content | episodic ("what I did, when") | semantic ("how X works, verified") |
| precision | low, catch-all | high, curated, code-grounded |
| shareable | no, machine-managed | yes, can become team docs / a CLI |

claude-mem is the safety net (nothing is lost). The hub is the compounding asset (the good stuff, promoted). Hub capture is therefore *selective on purpose*: file back only when a finding clears the bar (30+ minutes, reusable, non-obvious), because claude-mem backstops everything below it.

**The session lifecycle (4 phases):**

1. **Prime** with `/load-context <topic>`: pull existing hub notes (one-liners + TL;DRs). Optionally consult claude-mem `mem-search` ("did we solve this before?") and tail the hub `log.md` for recent activity.
2. **Gather** during the work: read code (LSP/grep), Slack, Notion, Datadog, Linear. Raw material accrues in the conversation. Capture provenance as you go (file:line, thread URLs, queries).
3. **Capture** when a finding clears the bar: `/store-to-hub`. The agent proactively offers this after a substantive investigation rather than waiting to be asked. `store-to-hub` synthesizes from the conversation; it does not re-fetch sources.
4. **Maintain** with `/hub-lint` periodically, before trusting notes for important work.

**Capture must fire outside the hub directory.** Investigations happen in other repos (clinician-web, etc.), where `abridge-hub/AGENTS.md` is not loaded. So the proactive-capture nudge lives in global `~/.claude/CLAUDE.md` and in the `store-to-hub` skill description, not only in the hub charter.

## Alternatives considered

- **Hub as the single memory layer (drop claude-mem reliance).** Rejected: that forces capture to be near-complete and reliable, which it cannot be without automation, and would lose the passive episodic backstop claude-mem gives for free.
- **Wire claude-mem into the `load-context` matcher.** Rejected: the matcher stays deterministic, hub-only, and testable. claude-mem consultation is an optional SKILL-prompt step, not part of the scored retrieval.
- **A hard Stop-hook that blocks until you file back.** Rejected: noisy, fires on every session including non-hub work. A proactive offer respects the selective-capture principle.

## Consequences

- Clear division: passive (claude-mem) vs curated (hub). No redundant capture, no rot from forgotten filing, because the bar is intentionally high and the backstop exists.
- The proactive-offer rule in global CLAUDE.md means capture is suggested anywhere, not just inside the hub.
- Provenance discipline shifts to the gather phase: a note without cited sources is incomplete, and `store-to-hub` will not invent them.
- Branch-based auto-priming remains future work; priming stays an explicit `/load-context`.

## Related

- ADR [0001-hub-knowledge-management](0001-hub-knowledge-management.md) (no frontmatter, log-over-git, lint architecture).
