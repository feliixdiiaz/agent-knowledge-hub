# Contributing

Small repo, one hard rule.

## The fresh-agent gate

Before shipping any change that affects how a NEW user adopts this template (README, install.sh, scripts/hub, the skills, the guide), run a **fresh-agent e2e**:

1. Spawn a coding agent with zero context about this project.
2. Give it only the public repo URL and a sandboxed `HOME` (so installs cannot touch the real machine).
3. Phrase the task as goals, not instructions: "set it up, create a sub-hub, write a note per the docs, find it via retrieval, lint it."
4. Demand a numbered friction log and exact command outputs.
5. Verify its claims yourself afterward.

Why: author-written tests verify the author's mental model. This repo's unit tests, evals, and smoke tests were all green while a naive agent found five real adoption bugs in one run (an unfilled template placeholder, an unseeded log file, an undocumented step, an oversold feature claim, a stale warning). The only reliable test of documentation is a reader who does not share your head.

When the gate finds a bug, fix the generator or the doc, never just the instance it produced.

## Everything else

- Deterministic checks over LLM judgment wherever a script can do the job; tests live next to what they test (`skills/*/tests`, `scripts/checks/test-hooks.sh`).
- Design changes that are hard to reverse, surprising without context, and a real trade-off get an ADR in `docs/adr/`.
- Note conventions live in `docs/note-format.md`; vocabulary in `CONTEXT.md`. Keep both authoritative; do not duplicate them in prose.
