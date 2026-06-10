# 0003: Notes vs works (and how investigations stay findable)

Status: Accepted (2026-06-09)

## Context

The hub holds two kinds of content: standalone notes and `works/<slug>/` project folders. The migration bulk-moved all works into `eng-investigations` without applying the routing rule, so a tooling project (`mise-adoption`) landed next to product notes. A sharper problem surfaced: an investigation is often done *inside* a work (numbered files), and those files are not in `INDEX.md`, so `load-context` cannot find them by topic. "How do we find an investigation done for a work?" had no answer. We grilled it and checked it against established knowledge-management systems.

## Decision

1. **A note is atomic, concept-oriented, cross-project, and findable** via `INDEX.md`. (Evergreen-note style.)
2. **A work is a goal-bound project**: a `works/<slug>/` folder of numbered files plus status. The folder persists; it is not migrated wholesale into a note.
3. **Works are domain-scoped**: routed to a sub-hub by the same laptop test as notes. So `mise-adoption` (a per-laptop tool version manager) is a **dev-exp** work; `clinician-web-ci-speed` stays **eng-investigations** (shared CI is a clinician-web system, not laptop-local).
4. **Promotion is how investigations stay findable**: when an investigation inside a work is reusable beyond that project, lift it to a root note (so it enters `INDEX.md`) and link it from the work. Project-specific material stays in the work. The test: *would future-you search for it independent of the project?* Yes then it is a note; otherwise it lives in the work.
5. **Term stays `works`** (not `features`: dev-exp works like `mise-adoption` are not features; not `projects`: pure rename churn).
6. `hub-lint`'s LLM pass flags misrouted works and buried reusable findings (unpromoted) as low-severity suggestions.

## Alternatives considered

- **Lifecycle-scoped / top-level `works/`** (domain-independent): rejected. The current works split cleanly by domain; a top-level works folder would need rewiring discovery (`load-context`/`store-to-hub` scan `hubs/*/`) for marginal benefit. Reconsider only if projects routinely span product + tooling.
- **Index every file inside a work** so all are findable: rejected. Bloats `INDEX.md` with project narrative. Promotion keeps the index to durable, reusable notes.
- **Rename `works` to `features` or `projects`**: rejected (see decision 5).
- **Make a work a pure Map-of-Content** (only links, no folder): deferred. The promote-and-link rule already gives MOC-style findability for the reusable parts without restructuring the project folders.

## Consequences

- `INDEX.md` stays lean (durable notes only); works hold project narrative; reusable findings are findable as notes.
- One rule (the laptop test) routes both notes and works.
- A small discipline cost: the promote step is manual (a `store-to-hub` action); `hub-lint` nudges when it is skipped.
- `mise-adoption` moved to `hubs/dev-exp/works/`; `clinician-web-ci-speed` + `linked-evidence` + `patient-consent` stay in `hubs/eng-investigations/works/`.

## Sources

- PARA, projects vs resources: https://fortelabs.com/blog/para/
- Evergreen notes (atomic, concept-oriented, cross-project): https://notes.andymatuschak.org/Evergreen_notes_should_be_concept-oriented
- Maps of Content: https://www.dsebastien.net/2022-05-15-maps-of-content/

## Related

- ADR [0001-hub-knowledge-management](0001-hub-knowledge-management.md), [0002-claude-mem-boundary-and-session-lifecycle](0002-claude-mem-boundary-and-session-lifecycle.md).
