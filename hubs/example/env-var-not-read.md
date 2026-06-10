# Tool ignores the env var you exported

## TL;DR

Many CLIs read configuration only from their own config file, not from a bare env var, exporting `TOOL_TOKEN` in your shell does nothing unless the config file interpolates it. Check the tool's config precedence before assuming the variable works. The fix is one config line referencing the env var, not more exporting.

## The pattern

The failure looks like "I set the token but it is still unauthenticated". The tool's config file (e.g. `~/.toolrc`) is the only thing it reads; CI works because the CI image bakes the interpolation line into the config.

## Verified vs inferred

- Verified: the generic shape, config file beats env var, applies to npm (`.npmrc`) among others.
- Inferred: your specific tool's precedence; read its docs.

## Sources

- This is a sample note demonstrating the format from `docs/note-format.md`. Replace with your own findings.
