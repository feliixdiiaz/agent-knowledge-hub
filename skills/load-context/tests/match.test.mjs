// Unit tests for the load-context matcher. Stdlib only (node:test).
// Run: node --test
//
// Tests run against a throwaway fixture hub so they do not depend on the real
// hub contents (which drift). Eval (evals/run.mjs) is what runs against real hubs.

import { test } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { parseIndex, tokenize, scoreEntry, extractTldr, match, fzfAvailable } from "../bin/match.mjs";

function makeFixtureHub() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "lc-fixture-"));
  // Note the deliberately glued entry (no newline before the next bullet),
  // mirroring the real agent-knowledge-hub INDEX quirk.
  const index = `# fixture index

## Notes

- [theme-system-map.md](theme-system-map.md): Dark mode is wired in dashboard-app only. Tokens at theme.css.
- [npm-token.md](npm-token.md): Consume private packages with a static token, no npm login.- [icon-stroke-leak.md](icon-stroke-leak.md): Icon.module.scss blanket stroke rule paints phantom strokes.

## Works

- [works/patient-consent/](works/patient-consent/): Patient-consent feature research and design.
`;
  fs.writeFileSync(path.join(dir, "INDEX.md"), index);
  fs.writeFileSync(path.join(dir, "theme-system-map.md"), "# Theme\n\n## TL;DR\n\nDark mode dashboard-app only.\n\n## Tokens\n\ndetails\n");
  fs.writeFileSync(path.join(dir, "npm-token.md"), "# npm\n\n## TL;DR\n\nUse a static token in .npmrc.\n\n## Body\n\nx\n");
  fs.writeFileSync(path.join(dir, "icon-stroke-leak.md"), "# icon\n\nno tldr here\n");
  return dir;
}

test("tokenize drops stopwords and short tokens", () => {
  assert.deepEqual(tokenize("how do I fix the npm token"), ["fix", "npm", "token"]);
});

test("parseIndex handles glued entries (missing newline)", () => {
  const hub = makeFixtureHub();
  const entries = parseIndex(fs.readFileSync(path.join(hub, "INDEX.md"), "utf8"));
  const labels = entries.map((e) => e.link);
  assert.ok(labels.includes("npm-token.md"), "npm-token parsed");
  assert.ok(labels.includes("icon-stroke-leak.md"), "glued icon-stroke entry still parsed");
  assert.ok(labels.includes("works/patient-consent/"), "dir entry parsed");
});

test("scoreEntry counts distinct query terms", () => {
  const entry = { label: "npm-token.md", link: "npm-token.md", summary: "static token no npm login" };
  const { distinct } = scoreEntry(entry, tokenize("npm token"));
  assert.equal(distinct, 2);
});

test("extractTldr pulls the TL;DR section, null when absent", () => {
  const hub = makeFixtureHub();
  assert.match(extractTldr(path.join(hub, "theme-system-map.md")), /Dark mode dashboard-app only/);
  assert.equal(extractTldr(path.join(hub, "icon-stroke-leak.md")), null);
});

test("match: topic selects the right note as top hit", () => {
  const hub = makeFixtureHub();
  const hits = match("npm token auth", { hubs: [hub], limit: 3 });
  assert.equal(hits[0].file, "npm-token.md");
});

test("match: dark mode theme selects theme note and carries its TL;DR", () => {
  const hub = makeFixtureHub();
  const hits = match("dark mode theme", { hubs: [hub] });
  assert.equal(hits[0].file, "theme-system-map.md");
  assert.match(hits[0].tldr, /dashboard-app only/);
});

test("fzf fallback: typo'd topic still finds the note (patietn -> patient)", (t) => {
  if (!fzfAvailable()) return t.skip("fzf not installed; fuzzy fallback inactive");
  const hub = makeFixtureHub();
  const hits = match("patietn", { hubs: [hub] });
  assert.equal(hits[0].file, "works/patient-consent/");
  assert.equal(hits[0].matchType, "fuzzy");
});

test("fzf fallback: only used when exact matching is empty", () => {
  const hub = makeFixtureHub();
  const hits = match("npm token auth", { hubs: [hub], limit: 3 });
  assert.equal(hits[0].matchType, "exact");
});

test("match: no match returns empty, not a throw", () => {
  const hub = makeFixtureHub();
  assert.deepEqual(match("kubernetes helm chart", { hubs: [hub] }), []);
});

test("match: missing hub dir is skipped, not fatal", () => {
  const hits = match("npm token", { hubs: ["/nonexistent/hub/path"] });
  assert.deepEqual(hits, []);
});
