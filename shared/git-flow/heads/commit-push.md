---
name: commit-push
description: >
  Commit on the current branch with a Conventional Commits message and push it — no new branch, no
  pull request. Use for "commit push", "commit and push", "push this up".
allowed-tools: Bash, PowerShell, Read, Glob, Grep
---

Run stages **0 → 2 → 3 → 5**, all of them below. **Skip stage 1** (never create or switch branches)
and **do not create a pull request**. Stage 0 skips the `gh` / `az` check but still resolves
`<base>`, which the warning below compares against.

**Pushing to the default branch.** Compare the current branch against the `<base>` stage 0 resolved
— never against a guessed list of names, which misses the defaults real repos use and so misses the
warning entirely. If they match, say plainly that this pushes straight to the default branch and get
explicit confirmation first. The commit may be made before asking; the push waits for the answer.

Arguments the user may pass: a commit subject. Honour it over the derived default.
