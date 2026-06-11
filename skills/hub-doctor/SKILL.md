---
name: hub-doctor
description: Diagnose and repair the knowledge-hub installation itself. Use when hub retrieval returns wrong or missing notes, a hub skill seems absent or stale, store-to-hub writes land in the wrong place, results mention an unexpected hub name, or the user says "hub is broken", "wrong hub", "hub-doctor", "/hub-doctor". Runs a deterministic diagnosis first (env vars, symlinks, matcher resolution, machinery), then fixes safe issues on confirmation or proposes exact commands for the rest.
---

# hub-doctor

When the hub misbehaves, the cause is usually mechanical (a stale env var, a hijacked symlink, an unbuilt step), not conceptual. **The deterministic diagnosis is the skill**; do not reason about symptoms before running it. This skill exists because a real bug (a stale `HUB_ROOT` in `.zshrc` silently re-routing all retrieval to another repo) was once mis-diagnosed by pure reasoning while a one-second env check would have caught it.

## Procedure

1. **Run the doctor first, always:**

   ```bash
   "${HUB_ROOT:-$HOME/workspace/agent-knowledge-hub}"/scripts/checks/doctor.sh
   ```

   It checks, in order: `HUB_ROOT` env sanity (set, exists, matches the repo), `.zshrc`-vs-process drift (stale long-lived sessions), skill symlinks per harness (broken, missing, or pointing at a different hub), matcher resolution (does retrieval actually read this repo), and machinery health (executables, git, fzf). Output is `OK/WARN/FAIL` lines, each WARN/FAIL with the exact fix command.

2. **Fix or propose, by class:**
   - **Safe mechanical fixes** (relink, chmod): offer to run `doctor.sh --fix` (it re-runs `install.sh`). Apply on confirmation.
   - **Environment fixes** (`HUB_ROOT` wrong in `~/.zshrc`, stale session env): NEVER edit shell config silently. Show the exact line change, apply only on explicit confirmation, and tell the user that running sessions keep the old env until restarted.
   - **Anything the doctor reports OK but symptoms persist:** only now reason beyond the script. Read the relevant SKILL.md / matcher / INDEX directly and propose; do not guess. If you find a new mechanical failure class, the fix belongs in `doctor.sh` (extend it), not in a one-off workaround.

3. **Report**: what was wrong, what was fixed, what remains for the user (e.g. restart sessions carrying stale env). If another agent session reported the symptom, state explicitly which diagnosis was confirmed or refuted so wrong to-dos get dropped.

## Notes

- Deterministic checks live in `scripts/checks/doctor.sh`; this skill is the judgment wrapper. Extend the script, not the prose, when new failure modes appear.
- The doctor is also the post-install verification: run it after any `install.sh`, machine migration, or when adopting a second hub repo.
