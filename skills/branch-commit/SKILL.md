---
name: branch-commit
description: >
  Create a type/short-slug branch and commit the current work with a Conventional Commits message.
  Stays local — no push, no pull request. Use for "branch commit", "commit this on a new branch",
  "branch it locally".
allowed-tools: Bash, PowerShell, Read, Glob, Grep
---

Run stages **0 → 1 → 2 → 5**. **Do not push and do not create a pull request** — the commit stays
local. Offer `branch-commit-push` as the follow-up.

**Read `references/core.md`, `references/branch.md` and `references/commit.md` — all next to this
file, inside this skill's own folder — before doing anything else.** They hold base-branch
resolution, guardrails, and the branch/commit format. Do not improvise these from memory.

Stage summary for this skill:

0. **Preflight** (`core.md`) — repo state, base branch, guardrails. No CLI check needed.
1. **Branch** (`branch.md`) — `<type>/<short-slug>` off an up-to-date base (off HEAD if the tree is dirty).
2. **Commit** (`commit.md`) — stage deliberately, Conventional Commits, no AI attribution. Several
   unrelated logical changes → several commits on the new branch.
5. **Report** (`core.md`) — branch and commit lines only, plus the reminder that nothing was pushed.

Arguments the user may pass: a base branch, a branch name, a commit subject. Honour them over the
derived defaults.
