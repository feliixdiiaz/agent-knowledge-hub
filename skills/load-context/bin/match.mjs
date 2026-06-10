#!/usr/bin/env node
// load-context matcher: deterministic retrieval over hub INDEX.md files.
// Given a topic, scan each hub's INDEX.md, score entries by query-term hits in
// (filename + summary), return the top matches with their note path + TL;DR.
//
// Usage:
//   node match.mjs "<topic>" [--limit N] [--json]
//
// Hubs: $LOAD_CONTEXT_HUBS (colon-separated abs paths) overrides the default
// list. Default: every sub-hub dir under $HUB_ROOT/hubs (or ~/workspace/agent-knowledge-hub/hubs).

import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { spawnSync } from "node:child_process";

const STOPWORDS = new Set([
  "the", "a", "an", "of", "to", "for", "in", "on", "and", "or", "is", "how",
  "what", "my", "me", "i", "with", "this", "that", "it", "do", "does",
]);

export function defaultHubs() {
  const env = process.env.LOAD_CONTEXT_HUBS;
  if (env) return env.split(":").filter(Boolean);
  const base = process.env.HUB_ROOT || path.join(os.homedir(), "workspace", "agent-knowledge-hub");
  const root = path.join(base, "hubs");
  try {
    return fs.readdirSync(root, { withFileTypes: true })
      .filter((d) => d.isDirectory())
      .map((d) => path.join(root, d.name));
  } catch {
    return [];
  }
}

export function tokenize(s) {
  return [...new Set(
    s.toLowerCase().split(/[^a-z0-9]+/).filter((t) => t.length > 1 && !STOPWORDS.has(t)),
  )];
}

// Parse INDEX.md into entries. Robust to glued entries (missing newline between
// items) by splitting on the "- [" bullet boundary rather than by line.
export function parseIndex(indexText) {
  const entries = [];
  const re = /-\s*\[([^\]]+)\]\(([^)]+)\):\s*([\s\S]*?)(?=\n-\s*\[|-\s*\[|\n##|\n$|$)/g;
  let m;
  while ((m = re.exec(indexText)) !== null) {
    entries.push({ label: m[1].trim(), link: m[2].trim(), summary: m[3].trim() });
  }
  return entries;
}

export function scoreEntry(entry, terms) {
  const hay = (entry.link + " " + entry.label + " " + entry.summary).toLowerCase();
  let distinct = 0;
  let total = 0;
  for (const t of terms) {
    const hits = hay.split(t).length - 1;
    if (hits > 0) {
      distinct += 1;
      total += hits;
    }
  }
  return { distinct, total };
}

// Optional fuzzy fallback, delegated to fzf (https://github.com/junegunn/fzf)
// rather than a hand-rolled matcher. Used only when exact matching returns
// nothing. If fzf is not installed, the fallback is skipped silently.
export function fzfAvailable() {
  return spawnSync("fzf", ["--version"], { stdio: "ignore" }).status === 0;
}

function fzfFilter(topic, entries) {
  const input = entries
    .map((e, i) => `${i}\t${e.entry.link} ${e.entry.summary}`)
    .join("\n");
  const res = spawnSync("fzf", [`--filter=${topic}`], { input, encoding: "utf8" });
  if (res.status !== 0 || !res.stdout) return [];
  return res.stdout
    .trim()
    .split("\n")
    .map((line) => entries[parseInt(line.split("\t")[0], 10)])
    .filter(Boolean);
}

export function extractTldr(noteAbsPath) {
  try {
    const text = fs.readFileSync(noteAbsPath, "utf8");
    const m = text.match(/##\s*TL;DR\s*\n([\s\S]*?)(?=\n##\s|\n#\s|$)/i);
    return m ? m[1].trim() : null;
  } catch {
    return null;
  }
}

function toResult(hub, entry, { score, matchType, occurrences }) {
  const isDir = entry.link.endsWith("/");
  const notePath = path.join(hub, entry.link);
  return {
    hub: path.basename(hub),
    file: entry.link,
    path: notePath,
    summary: entry.summary,
    score,
    matchType,
    occurrences,
    tldr: isDir ? null : extractTldr(notePath),
  };
}

export function match(topic, { hubs = defaultHubs(), limit = 3 } = {}) {
  const terms = tokenize(topic);
  const results = [];
  const allEntries = [];
  for (const hub of hubs) {
    const indexPath = path.join(hub, "INDEX.md");
    let indexText;
    try {
      indexText = fs.readFileSync(indexPath, "utf8");
    } catch {
      continue; // hub missing or no INDEX, skip
    }
    for (const entry of parseIndex(indexText)) {
      allEntries.push({ hub, entry });
      const { distinct, total } = scoreEntry(entry, terms);
      if (distinct === 0) continue;
      results.push(toResult(hub, entry, { score: distinct, matchType: "exact", occurrences: total }));
    }
  }
  results.sort((a, b) => b.score - a.score || b.occurrences - a.occurrences);
  if (results.length > 0) return results.slice(0, limit);

  // Exact matching found nothing: optional fzf fallback (skipped if no fzf).
  if (allEntries.length > 0 && fzfAvailable()) {
    return fzfFilter(topic, allEntries)
      .slice(0, limit)
      .map(({ hub, entry }) => toResult(hub, entry, { score: 0, matchType: "fuzzy", occurrences: 0 }));
  }
  return [];
}

function main() {
  const args = process.argv.slice(2);
  const json = args.includes("--json");
  let limit = 3;
  const li = args.indexOf("--limit");
  if (li !== -1 && args[li + 1]) limit = parseInt(args[li + 1], 10);
  const topic = args.filter((a, i) => !a.startsWith("--") && !(i > 0 && args[i - 1] === "--limit")).join(" ");

  if (!topic) {
    console.error('Usage: node match.mjs "<topic>" [--limit N] [--json]');
    process.exit(2);
  }

  const hits = match(topic, { limit });
  if (json) {
    console.log(JSON.stringify(hits, null, 2));
    return;
  }
  if (hits.length === 0) {
    console.log(`No hub notes matched "${topic}". Run with a broader term, or check INDEX.md topics.`);
    return;
  }
  for (const h of hits) {
    console.log(`\n## ${h.file}  (${h.hub}, score ${h.score}${h.matchType === "fuzzy" ? ", fuzzy: did you mean this?" : ""})`);
    console.log(h.summary);
    if (h.tldr) console.log(`\nTL;DR:\n${h.tldr}`);
    console.log(`→ dive: ${h.path}`);
  }
}

import { realpathSync } from "node:fs";
import { pathToFileURL } from "node:url";
const invokedAsCli = process.argv[1] &&
  import.meta.url === pathToFileURL(realpathSync(process.argv[1])).href;
if (invokedAsCli) main();
