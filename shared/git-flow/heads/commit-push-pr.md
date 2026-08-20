---
name: commit-push-pr
description: >
  Commit on the current branch, push it, and open a pull request — no new branch created. Use for
  "commit push pr", "PR this branch", "commit and raise a PR".
allowed-tools: Bash, PowerShell, Read, Glob, Grep
---

Run stages **0 → 2 → 3 → 4 → 5**, all of them below. **Skip stage 1** — commit on the branch
already checked out; never create or switch branches.

**On the default branch this skill is a trap.** Compare the current branch against the `<base>`
stage 0 resolved — never against a guessed list of names. If they match, a pull request cannot
target itself: stop before committing, say so, and offer `branch-commit-push-pr`. Only proceed if
the user explicitly names a different base.

If a CLI or the `azure-devops` extension is missing, **ask the user to install it with the exact
command and stop there** — never install it yourself. Report which stages already completed.

Arguments the user may pass: a base branch, a commit subject, `--draft`, a work-item / issue ID,
reviewers. Honour them over the derived defaults.
