---
name: push-pr
description: >
  Push the current branch and open a pull request from the commits already on it — no new branch and
  no new commit. Use for "push pr", "push and open a PR", "PR the commits I already made".
allowed-tools: >-
  Bash(git rev-parse *) Bash(git status --porcelain=v1 --branch)
  Bash(git symbolic-ref --quiet --short HEAD) Bash(git log --oneline -5) Bash(git diff --shortstat)
  Bash(git diff --staged --shortstat) Bash(git diff -- *) Bash(git diff --cached -- *)
  Bash(git remote get-url *) Bash(git symbolic-ref --quiet refs/remotes/*/HEAD)
  Bash(git fetch origin --no-prune --quiet) Bash(git remote set-head *) Bash(git rev-list *)
  Bash(grep -nisE *) Bash(gh auth status) Bash(gh repo view *) Bash(gh pr list *) Bash(az version *)
  Bash(az extension show *) Bash(az repos show *) Bash(az repos list *) Bash(az repos pr list *)
---

Run stages **0 → 3 → 4 → 5**, all of them below. **Skip stages 1 and 2** — never create or switch
branches, and never commit. What ships is exactly what is already committed on this branch, so a
clean tree is the normal case, not the "nothing to commit" stop the `commit` skills apply. Stage
4's call one runs **before** the push (stage 3 says so), so an empty branch never reaches the
remote. Four tool calls: preflight, that check, push, create.

**Nothing to ship.** If that check finds no commits between `<base>` and this branch, there is
nothing to push and no diff to open a pull request for. Stop before pushing and
report — don't reach for a commit skill unasked.

**On the default branch this skill is a trap.** Compare the current branch against the `<base>`
stage 0 resolved — never against a guessed list of names. If they match, a pull request cannot
target itself *and* the push would go straight to the protected branch: stop before pushing and
report both. Moving the commits onto a branch first is the user's call.

On the remote-HEAD branch while `<base>` names another, the pull request is possible but the
push lands on a default branch: warn and get explicit confirmation first.

If a CLI or the `azure-devops` extension is missing, **ask the user to install it with the exact
command and stop there** — never install it yourself. Report which stages already completed.

Arguments the user may pass: a base branch, a PR title, `--draft`, a work-item / issue ID,
reviewers. Honour them over the derived defaults.
