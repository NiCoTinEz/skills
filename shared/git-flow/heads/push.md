---
name: push
description: >
  Push the commits already on the current branch, setting upstream on the first push — no new
  branch, no commit, no pull request. Use for "push", "push only", "push without a PR".
allowed-tools: Bash, PowerShell, Read, Glob, Grep
---

Run stages **0 → 3 → 5**, all of them below. **Skip stages 1, 2 and 4** — never create or switch
branches, never commit, never open a pull request. What ships is exactly what is already committed,
so a clean tree is the normal case here. Stage 0 skips the `gh` / `az` check. Two tool calls.

**Pushing to the default branch.** Compare the current branch against the `<base>` stage 0 resolved;
if they match, warn plainly and get explicit confirmation before pushing.

Offer the follow-up: `push-pr` if a pull request should follow, `commit-push` if work still needed
committing first.

Arguments the user may pass: a remote name. Honour it, and use that same name for every command.
