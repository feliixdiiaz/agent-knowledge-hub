# example index

One-line summary of every note. See `AGENTS.md` for how this hub works.

## Notes

- [prebuilt-lib-indirection.md](prebuilt-lib-indirection.md): Editing a shared package's src/ does nothing at runtime; consumers import prebuilt lib/. Rebuild or watch after edits. Symptoms: source right, app unchanged, stale build artifact.
- [env-var-not-read.md](env-var-not-read.md): Exported env var ignored because the tool only reads its config file; add the interpolation line (auth, token, unauthenticated loop).
