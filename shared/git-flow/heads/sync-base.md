---
name: sync-base
description: >
  Switch back to the repository's base branch — main, master, development, whatever this repo
  actually uses — and fast-forward it to the remote, asking first, when eligible, whether to prune
  stale remote-tracking refs and reporting which local branches are now merged. In a folder that is
  not a repo but holds repos, it asks which of them to sync. A dirty tree stops it. Use for "sync
  base", "back to base", "go back to main and pull".
allowed-tools: >-
  Bash(git rev-parse *) Bash(git status --porcelain=v1 --branch)
  Bash(git symbolic-ref --quiet --short HEAD) Bash(git log --oneline -5) Bash(git diff --shortstat)
  Bash(git diff --staged --shortstat) Bash(git diff -- *) Bash(git diff --cached -- *)
  Bash(git remote get-url *) Bash(git symbolic-ref --quiet refs/remotes/*/HEAD)
  Bash(git fetch origin --no-prune --quiet) Bash(git remote set-head *) Bash(git rev-list *)
  Bash(grep -nisE *) Bash(git for-each-ref *) Bash(git ls-remote *)
  Bash(git diff --ignore-cr-at-eol --name-only)
  Bash(git diff --cached --ignore-cr-at-eol --name-only)
  Bash(find . -mindepth 2 -maxdepth 2 -name .git) Bash(find . -mindepth 3 -maxdepth 3 -name .git)
  Bash(git pull --ff-only --no-prune *) Bash(git log --oneline -1) Bash(git branch --merged *)
---

Run stage **0**, then the procedure below, then stage **5**. **Do not run
stages 1-4** — never create a branch, never commit, never push, never open a pull request. Stage 0
skips the `gh` / `az` check, and **resolving `<base>` correctly is the entire point of this skill**:
follow the order below, because a hardcoded `main` / `master` guess lands the user on the wrong
branch or on none at all. Eligible runs use three calls: preflight, switch, pull, with one prune
question between the first two. Ineligible repos are excluded before it. Folder mode normally
runs four, batching the per-repo probe, and asks which repos to sync first. Missing remote/base
information uses the shared fallback probes, batched across unresolved repos before proceeding.

Arguments the user may pass: a branch to treat as `<base>`, or a remote name. Honour them, and never
"normalise" the casing of a name you were given.
