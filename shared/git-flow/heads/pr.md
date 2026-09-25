---
name: pr
description: >
  Open a pull request for the commits already pushed on the current branch — no new branch, no
  commit, and no push. Use for "pr", "open a PR", "PR this branch".
allowed-tools: >-
  Bash(git rev-parse *) Bash(git status --porcelain=v1 --branch)
  Bash(git symbolic-ref --quiet --short HEAD) Bash(git log --oneline -5) Bash(git diff --shortstat)
  Bash(git diff --staged --shortstat) Bash(git diff -- *) Bash(git diff --cached -- *)
  Bash(git remote get-url *) Bash(git symbolic-ref --quiet refs/remotes/*/HEAD)
  Bash(git fetch origin --no-prune --quiet) Bash(git remote set-head *) Bash(git rev-list *)
  Bash(grep -nisE *) Bash(gh auth status) Bash(gh repo view *) Bash(gh pr list *) Bash(az version *)
  Bash(az extension show *) Bash(az repos show *) Bash(az repos list *) Bash(az repos pr list *)
---

Run stages **0 → 4 → 5**, all of them below. **Skip stages 1, 2 and 3** — never create or switch
branches, never commit, and **never push**. The pull request describes what the remote already has,
so stage 4 keeps its parity check: a clean tree is the normal case here. Three tool calls.

**Unpushed commits stop this skill; they do not trigger a push.** If `<remote>/<branch>` does not
exist, or local HEAD sits ahead of it, stop, say which of the two it is, and offer `push-pr`.

**Uncommitted changes are left alone**, and are in neither the commits nor the pull request. Name
the dirty paths so the user sees what it excludes, then continue. Offer `commit-push-pr` if they
meant to include them.

**On the default branch a pull request is impossible** — it cannot target itself. Compare the
current branch against the `<base>` stage 0 resolved; if they match, stop and report. Moving the
commits onto a branch is the user's call.

If a CLI or the `azure-devops` extension is missing, **ask the user to install it with the exact
command and stop there** — never install it yourself.

Arguments the user may pass: a base branch, a PR title, `--draft`, a work-item / issue ID,
reviewers. Honour them over the derived defaults.
