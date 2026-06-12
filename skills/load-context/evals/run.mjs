#!/usr/bin/env node
// Evaluation harness for load-context selection quality.
// Runs the deterministic matcher against the REAL hubs over cases.json and
// reports hit rate (expected note in top-N) and top-1 accuracy.
//
// Run: node evals/run.mjs          (deterministic core: fuzzy disabled, same
//                                    result on every machine, fzf or not)
//      node evals/run.mjs --fzf    (also run the fuzzy cases; fails loudly if
//                                    fzf is missing rather than skipping)
// Exits nonzero if hit rate < THRESHOLD, so it works as a CI/regression gate.

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { match, fzfAvailable } from "../bin/match.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const THRESHOLD = 0.8; // require 80% of cases to surface the expected note in top-N

const { topN, cases: allCases } = JSON.parse(fs.readFileSync(path.join(HERE, "cases.json"), "utf8"));
const runFzf = process.argv.includes("--fzf");
if (runFzf && !fzfAvailable()) {
  console.error("FAIL: --fzf requested but fzf is not installed (brew/apt install fzf)");
  process.exit(2);
}
const cases = allCases.filter((c) => !c.requiresFzf || runFzf);
const omitted = allCases.length - cases.length;
if (omitted > 0) console.log(`(${omitted} fuzzy case(s) not selected; opt in with --fzf)\n`);

let hits = 0;
let topOk = 0;
let topApplicable = 0;
const rows = [];

for (const c of cases) {
  // Core cases run with fuzzy disabled so the result cannot depend on
  // whether fzf happens to be installed; fuzzy cases opt in explicitly.
  const results = match(c.topic, { limit: topN, fuzzy: Boolean(c.requiresFzf) });
  const files = results.map((r) => r.file);
  const inTopN = files.includes(c.expect);
  const isTop = results[0]?.file === c.expect;
  if (inTopN) hits += 1;
  if (c.expectTop) {
    topApplicable += 1;
    if (isTop) topOk += 1;
  }
  rows.push({
    topic: c.topic,
    expect: c.expect,
    hit: inTopN ? "✓" : "✗",
    top1: c.expectTop ? (isTop ? "✓" : "✗") : "-",
    got: files.join(", ") || "(none)",
  });
}

const hitRate = hits / cases.length;
const topRate = topApplicable ? topOk / topApplicable : 1;

console.log("load-context selection eval\n");
for (const r of rows) {
  console.log(`[topN ${r.hit}] [top1 ${r.top1}] "${r.topic}"`);
  console.log(`    expect: ${r.expect}`);
  console.log(`    got:    ${r.got}`);
}
console.log(`\nhit rate (expected in top-${topN}): ${hits}/${cases.length} = ${(hitRate * 100).toFixed(0)}%`);
console.log(`top-1 accuracy (where required):  ${topOk}/${topApplicable} = ${(topRate * 100).toFixed(0)}%`);

if (hitRate < THRESHOLD) {
  console.error(`\nFAIL: hit rate ${(hitRate * 100).toFixed(0)}% < threshold ${(THRESHOLD * 100).toFixed(0)}%`);
  process.exit(1);
}
console.log(`\nPASS: hit rate >= ${(THRESHOLD * 100).toFixed(0)}%`);
