---
name: branch-commit
description: >
  Create a type/short-slug branch and commit the current work with a Conventional Commits message.
  Stays local — no push, no pull request. Use for "branch commit", "commit this on a new branch",
  "branch it locally".
allowed-tools: >-
  Bash(git rev-parse *) Bash(git status *) Bash(git symbolic-ref *) Bash(git log *)
  Bash(git diff *) Bash(git remote get-url *) Bash(git remote set-head *) Bash(git fetch *)
  Bash(git rev-list *) Bash(grep *) Bash(git switch *) Bash(git add *) Bash(git commit *)
  Bash(git show *)
---

Run stages **0 → 1 → 2 → 5**, all of them below. **Do not push and do not create a pull request** —
the commit stays local; offer `branch-commit-push` as the follow-up. Stage 0 still resolves
`<remote>` and `<base>`, because stage 1 branches off the base; it skips the `gh` / `az` check.

Arguments the user may pass: a base branch, a branch name, a commit subject. Honour them over the
derived defaults.
