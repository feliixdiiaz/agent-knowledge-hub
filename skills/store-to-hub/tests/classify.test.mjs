import { test } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { classify } from "../bin/classify.mjs";

function fixtureRoot() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "sth-"));
  for (const [name, charter, idx] of [
    ["eng", "# eng\nCode-grounded investigation notes.\n", "## Notes\n- [theme.md](theme.md): dark mode dashboard-app only.\n"],
    ["dev-exp", "# dev-exp\nDeveloper-experience friction fixes.\n", "## Notes\n- [npm-token.md](npm-token.md): static npm token in .npmrc.\n"],
  ]) {
    const d = path.join(root, name);
    fs.mkdirSync(d);
    fs.writeFileSync(path.join(d, "AGENTS.md"), charter);
    fs.writeFileSync(path.join(d, "INDEX.md"), `# ${name} index\n\n${idx}`);
  }
  fs.writeFileSync(path.join(root, "eng", "theme.md"), "# theme\n## TL;DR\ndark mode\n");
  fs.writeFileSync(path.join(root, "dev-exp", "npm-token.md"), "# npm\n## TL;DR\ntoken in npmrc\n");
  return root;
}

test("classify returns all sub-hubs with charter snippets", () => {
  const root = fixtureRoot();
  const { candidateHubs } = classify("anything", { root });
  assert.deepEqual(candidateHubs.map((h) => h.name).sort(), ["dev-exp", "eng"]);
  assert.match(candidateHubs.find((h) => h.name === "dev-exp").charter, /friction/);
});

test("classify surfaces a dedup candidate for an overlapping topic", () => {
  const root = fixtureRoot();
  const { dedupHits } = classify("npm token", { root });
  assert.equal(dedupHits[0].file, "npm-token.md");
});

test("classify returns no dedup hits for a novel topic with no token overlap", () => {
  const root = fixtureRoot();
  const { dedupHits } = classify("kubernetes ingress tls", { root });
  assert.deepEqual(dedupHits, []);
});
