---
name: branch-commit-push
description: >
  Create a type/short-slug branch, write a Conventional Commits commit, and push it with upstream
  tracking — no pull request. Use for "branch commit push", "push this on a new branch", "branch
  and push without a PR".
allowed-tools: Bash, PowerShell, Read, Glob, Grep
---

Run stages **0 → 1 → 2 → 3 → 5**. **Do not create a pull request** — stop after the push, even if a
PR looks like the obvious next step. Offer `branch-commit-push-pr` as the follow-up instead.

**Read `references/core.md`, `references/branch.md`, `references/commit.md` and
`references/push.md` — all next to this file, inside this skill's own folder — before doing
anything else.** They hold the platform detection, base-branch resolution, guardrails,
branch/commit format, and push handling. Do not improvise these from memory.

Stage summary for this skill:

0. **Preflight** (`core.md`) — repo state, platform, base branch, guardrails. No `gh`/`az` check needed.
1. **Branch** (`branch.md`) — `<type>/<short-slug>` off an up-to-date base (off HEAD if the tree is dirty).
2. **Commit** (`commit.md`) — stage deliberately, Conventional Commits, no AI attribution. Several
   unrelated logical changes → several commits on the new branch.
3. **Push** (`push.md`) — `git push --set-upstream <remote> HEAD`, using the remote resolved in
   stage 0. Non-fast-forward → stop and report.
5. **Report** (`core.md`) — platform / branch / commit / push lines only.

Arguments the user may pass: a base branch, a branch name, a commit subject. Honour them over the
derived defaults.
