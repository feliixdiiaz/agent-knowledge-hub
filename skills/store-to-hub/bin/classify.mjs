#!/usr/bin/env node
// store-to-hub classifier (deterministic). Given a topic/keywords, return:
//  - candidateHubs: each sub-hub with its AGENTS.md charter snippet (for the LLM to pick the target)
//  - dedupHits: existing notes whose INDEX summary overlaps the topic (possible append targets)
//
// dedupHits is a CANDIDATE list (keyword recall), not a verdict. The LLM decides
// append-vs-new from the charters + the hits. Usage:
//   node classify.mjs "<topic>" [--json]
import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { match } from "../../load-context/bin/match.mjs";

export function hubsRoot() {
  if (process.env.STORE_TO_HUB_ROOT) return process.env.STORE_TO_HUB_ROOT;
  const base = process.env.HUB_ROOT || path.join(os.homedir(), "workspace", "agent-knowledge-hub");
  return path.join(base, "hubs");
}

export function listHubs(root = hubsRoot()) {
  try {
    return fs.readdirSync(root, { withFileTypes: true })
      .filter((d) => d.isDirectory())
      .map((d) => {
        const dir = path.join(root, d.name);
        let charter = "";
        try { charter = fs.readFileSync(path.join(dir, "AGENTS.md"), "utf8").slice(0, 800); } catch {}
        return { name: d.name, dir, charter };
      });
  } catch {
    return [];
  }
}

export function classify(topic, { root = hubsRoot() } = {}) {
  const hubs = listHubs(root);
  // Dedup needs precision, not recall: a fuzzy subsequence hit is a retrieval
  // aid ("did you mean"), never an append target. fuzzy: false also keeps
  // classification deterministic regardless of whether fzf is installed.
  const dedupHits = match(topic, { hubs: hubs.map((h) => h.dir), limit: 3, fuzzy: false });
  return { candidateHubs: hubs.map(({ name, charter }) => ({ name, charter })), dedupHits };
}

function main() {
  const topic = process.argv.slice(2).filter((a) => !a.startsWith("--")).join(" ");
  if (!topic) {
    console.error('usage: classify.mjs "<topic>"');
    process.exit(2);
  }
  console.log(JSON.stringify(classify(topic), null, 2));
}

import { realpathSync } from "node:fs";
import { pathToFileURL } from "node:url";
const invokedAsCli = process.argv[1] &&
  import.meta.url === pathToFileURL(realpathSync(process.argv[1])).href;
if (invokedAsCli) main();
