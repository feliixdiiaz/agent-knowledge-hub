# Note format

The canonical shape of a hub note. `store-to-hub` writes to this; `hub-lint` checks against it; sub-hub charters link here instead of repeating it. See `CONTEXT.md` for the terms (note, work, canonical note, TL;DR).

## Skeleton

```markdown
# <Title: the topic, stated plainly>

## TL;DR
Three to five lines. What you learned, plus the one fact future-you needs to act.
If you cannot summarize it in five lines, the note is not done.

## <Body sections, named for the content>
The investigation, code-grounded. Cite file paths with line ranges and quote the
relevant lines, e.g. `apps/web/src/contexts/UserContext.tsx:603-680`.

## Verified vs inferred
- Verified: what you actually read or ran.
- Inferred / unknown: caveats, gaps, things still to confirm.

## Sources
- repo `file:line`, Slack thread URL, Notion URL, Linear ticket, Datadog query.

## Related
- `other-note.md` for a note in the same sub-hub.
- `../<sub-hub>/<note>.md` for a cross-hub reference (relative path, never a bare name).
```

## Never include

- **PHI** as defined in `CONTEXT.md` (HIPAA Safe Harbor identifiers + any clinical payload: transcript fragments, SOAP-note text, CDS/order/AVS content tied to a real encounter). Cite the pointer (encounter UUID, FHIR resource ID, collection path, query), never the payload. Hand-stripping names is not de-identification.
- **Credentials**: tokens, passwords, API keys, private keys. Cite where a value lives (1Password item, Keychain entry, env var name), never the value.

## Rules

- Lead with `## TL;DR`. Kebab-case filename. No em dashes.
- Cite, do not paraphrase. A grep hit is a lead, not an answer; open the file first.
- One topic per note. One topic is never split across sub-hubs (see `CONTEXT.md`, "canonical note"); merge instead of forking.
- Every new or renamed note gets a one-line entry in its sub-hub `INDEX.md`. Write that one-liner as a retrieval surface: include the words future-you would actually search ("dark mode / theming / theme tokens"), not just the title restated.
- A `works/<slug>/` project is not a note: it gets a `## TL;DR` in its lead file and stays as the durable record.
