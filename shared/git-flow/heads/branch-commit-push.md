---
name: branch-commit-push
description: >
  Create a type/short-slug branch, write a Conventional Commits commit, and push it with upstream
  tracking — no pull request. Use for "branch commit push", "push this on a new branch", "branch
  and push without a PR".
allowed-tools: >-
  Bash(git rev-parse *) Bash(git status *) Bash(git symbolic-ref *) Bash(git log *)
  Bash(git diff *) Bash(git remote get-url *) Bash(git remote set-head *) Bash(git fetch *)
  Bash(git rev-list *) Bash(grep *) Bash(git switch *) Bash(git add *) Bash(git commit *)
  Bash(git show *)
---

Run stages **0 → 1 → 2 → 3 → 5**, all of them below. **Do not create a pull request** — stop after
the push, even if a PR looks like the obvious next step, and offer `branch-commit-push-pr` as the
follow-up. Stage 0 skips the `gh` / `az` check: this skill never reaches a pull request.

Arguments the user may pass: a base branch, a branch name, a commit subject. Honour them over the
derived defaults.
