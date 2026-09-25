---
name: commit-push-pr
description: >
  Commit on the current branch, push it, and open a pull request — no new branch created. Use for
  "commit push pr", "PR this branch", "commit and raise a PR".
allowed-tools: >-
  Bash(git rev-parse *) Bash(git status --porcelain=v1 --branch)
  Bash(git symbolic-ref --quiet --short HEAD) Bash(git log --oneline -5) Bash(git diff --shortstat)
  Bash(git diff --staged --shortstat) Bash(git diff -- *) Bash(git diff --cached -- *)
  Bash(git remote get-url *) Bash(git symbolic-ref --quiet refs/remotes/*/HEAD)
  Bash(git fetch origin --no-prune --quiet) Bash(git remote set-head *) Bash(git rev-list *)
  Bash(grep -nisE *) Bash(git add -- *) Bash(git commit --quiet -F *)
  Bash(git show --shortstat --format=%h HEAD) Bash(gh auth status) Bash(gh repo view *)
  Bash(gh pr list *) Bash(az version *) Bash(az extension show *) Bash(az repos show *)
  Bash(az repos list *) Bash(az repos pr list *)
---

Run stages **0 → 2 → 3 → 4 → 5**, all of them below. **Skip stage 1** — commit on the branch
already checked out; never create or switch branches.

**On the default branch this skill is a trap.** Compare the current branch against the `<base>`
stage 0 resolved — never against a guessed list of names. If they match, a pull request cannot
target itself: stop before committing, say so, and offer `branch-commit-push-pr`. Only proceed if
the user explicitly names a different base.

On the remote-HEAD branch while `<base>` names another, the pull request is possible but the
push lands on a default branch: warn and get explicit confirmation first.

If a CLI or the `azure-devops` extension is missing, **ask the user to install it with the exact
command and stop there** — never install it yourself. Report which stages already completed.

Arguments the user may pass: a base branch, a commit subject, `--draft`, a work-item / issue ID,
reviewers. Honour them over the derived defaults.
