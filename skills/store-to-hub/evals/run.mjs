#!/usr/bin/env node
// Evaluation harness for store-to-hub dedup RECALL against the REAL hubs.
//
// dedupHits is a keyword-recall candidate list, not a precision verdict. So we
// test recall only: when a topic has a known existing note, that note MUST be a
// dedup candidate. For a topic that shares no tokens with any INDEX line, we
// expect zero candidates. We do NOT assert "no hits" for novel-but-overlapping
// topics; the matcher cannot decide that, the LLM does.
//
// Run: node evals/run.mjs   (exits nonzero below THRESHOLD, so it gates)

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { classify } from "../bin/classify.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const THRESHOLD = 0.8;

const { cases } = JSON.parse(fs.readFileSync(path.join(HERE, "cases.json"), "utf8"));

let ok = 0;
const rows = [];

for (const c of cases) {
  const { dedupHits } = classify(c.topic);
  const files = dedupHits.map((h) => h.file);
  let pass;
  if (c.expectEmpty) pass = files.length === 0;
  else pass = files.includes(c.expectHit);
  if (pass) ok += 1;
  rows.push({
    topic: c.topic,
    want: c.expectEmpty ? "(no hits)" : c.expectHit,
    got: files.join(", ") || "(none)",
    mark: pass ? "✓" : "✗",
  });
}

console.log("store-to-hub dedup recall eval\n");
for (const r of rows) {
  console.log(`[${r.mark}] "${r.topic}"`);
  console.log(`    want: ${r.want}`);
  console.log(`    got:  ${r.got}`);
}

const rate = ok / cases.length;
console.log(`\nrecall: ${ok}/${cases.length} = ${(rate * 100).toFixed(0)}%`);

if (rate < THRESHOLD) {
  console.error(`\nFAIL: ${(rate * 100).toFixed(0)}% < threshold ${(THRESHOLD * 100).toFixed(0)}%`);
  process.exit(1);
}
console.log(`\nPASS: recall >= ${(THRESHOLD * 100).toFixed(0)}%`);
