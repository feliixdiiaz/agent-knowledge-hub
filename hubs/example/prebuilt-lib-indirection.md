# Shared package edits do not reach the running app

## TL;DR

Editing a shared package's `src/` changes nothing at runtime when consumers import the prebuilt `lib/` output. After any edit, rebuild the package (or run its watcher) before judging whether your change worked. The symptom is "source looks right, app unchanged"; the cause is the build artifact, not your code.

## The trap

Monorepos often publish internal packages with a build step: consumers resolve `my-ui-lib` to `lib/` (compiled output), while you edit `src/`. The dev server, type checker, and Storybook all read `lib/`.

## The fix

Rebuild after any edit to the shared package, e.g. `pnpm --filter my-ui-lib build`, or keep a watcher running during iterative work.

## Verified vs inferred

- Verified: reproduce by editing `src/`, reloading, observing no change; rebuild; change appears.
- Inferred: your monorepo's package names and build commands differ; check its `package.json` exports field.

## Sources

- This is a sample note demonstrating the format from `docs/note-format.md`. Replace with your own findings.
