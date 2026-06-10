# 0004: The maintenance loop (local git + scheduled deterministic sweep)

Status: Accepted (2026-06-10)

## Context

Building the hub is not enough; it must stay clean and evaluated or it rots into confidently-wrong answers (the npm contradiction proved this happens fast). The question: cron job, or push to a git remote so CI (GitHub Actions) runs the checks? Researched docs-as-code practice (lint on change + scheduled stale/link checks via CI cron), Google's g3doc (owner + last-reviewed freshness metadata; review-based docs beat wikis; docs were the #1 productivity complaint), and the existing harness pattern on this machine (launchd jobs driving claude/scripts, tracked in `~/.claude/job-registry.yaml`, monitored by the job-dashboard).

## Decision

1. **Local git, no remote (for now).** `git init` done; licensed fonts gitignored. This reopens ADR 0001's deferral deliberately: maintenance wants change detection, snapshots, and undo, which the log alone cannot give. Git history now supersedes manual `log.md` discipline as the safety net (log.md stays, as the human-readable intent record).
2. **No GitHub Actions yet, and never on a personal remote.** Hub notes are Abridge-internal engineering knowledge; pushing to a personal GitHub repo is a data-governance problem, not a tooling choice. Actions become available the day the hub moves to an Abridge-org private repo; the sweep script is already CI-shaped (exit nonzero on BLOCK) so the migration is trivial.
3. **Weekly deterministic sweep via launchd** (`com.eyup.claude-hub-maintenance`, Mondays 09:15, mirroring the existing claude-* jobs): `scripts/hub-maintenance.sh` lints every sub-hub (0.35s), writes a report, auto-commits a git snapshot, notifies on any BLOCK or on WARN growth, and updates `job-registry.yaml` so the job-dashboard shows it. Deterministic per the CI-over-LLM rule; no tokens spent.
4. **LLM pass stays on-demand** (`/hub-lint`): contradictions, duplicates, hedged claims, buried findings. Run it monthly-ish or before trusting the hub for big work. Not scheduled, because nondeterministic output should land in front of a human, not a log file.
5. **No per-note freshness metadata** (g3doc's owner/last-reviewed). One-owner hub; git commit dates now provide last-touched for free; the LLM pass covers true staleness. Revisit only if the hub gains multiple writers.

## Alternatives considered

- **GitHub Actions now** (personal remote): rejected on data governance, not effort.
- **Claude-scheduled job (`claude -p`) for the weekly sweep**: rejected; the sweep is fully deterministic, so spending LLM turns on it violates the CI-over-LLM principle. The existing launchd+registry pattern fits without Claude in the loop.
- **cron(8) instead of launchd**: launchd is the macOS-native equivalent and already the established pattern on this machine.
- **Auto-scheduling the LLM lint**: rejected for now; propose-only output needs a human reading it.

## Consequences

- Hygiene runs without anyone remembering: weekly gate, notification only when something needs attention (BLOCK or warning growth), history accrues via auto-snapshots.
- WARN count becomes a tracked burn-down number (state file keeps last count; growth triggers a notification).
- The queue phase inherits a git repo, which it needed anyway for concurrent agent writes (worktrees).
- If the hub is ever shared, move to an Abridge-org private repo and add an Actions workflow calling the same `hub-maintenance.sh`.

## Sources

- Docs-as-code CI practice: https://www.netlify.com/blog/a-key-to-high-quality-documentation-docs-linting-in-ci-cd/ and https://konghq.com/blog/learning-center/what-is-docs-as-code
- g3doc (radical simplicity, freshness metadata): https://www.usenix.org/sites/default/files/conference/protected-files/srecon16europe_slides_macnamara.pdf
- Falconer freshness loop (ADR 0001 sources): a knowledge base without health checks is the worst input for an agent.

## Related

ADRs [0001](0001-hub-knowledge-management.md) (log-over-git, now partially superseded by local git), [0002](0002-claude-mem-boundary-and-session-lifecycle.md), [0003](0003-notes-vs-works.md).
