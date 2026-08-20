---
name: branch-commit-push-pr
description: >
  Full ship flow: create a type/short-slug branch, write a Conventional Commits commit, push with
  upstream, and open a pull request. Use for "branch commit push pr", "ship this", "make a branch
  and PR".
allowed-tools: Bash, PowerShell, Read, Glob, Grep
---

Run stages **0 → 1 → 2 → 3 → 4 → 5** — the whole procedure, all of it below. Roughly six tool
calls: one preflight, one branch, one per commit, one push, two for the pull request. Don't improvise
the commands from memory; the blocks below are written to be run as they stand.

If a CLI or the `azure-devops` extension is missing, **ask the user to install it with the exact
command and stop there** — never install it yourself. Report which stages already completed.

Arguments the user may pass: a base branch, a branch name, a commit subject, `--draft`, a
work-item / issue ID, reviewers. Honour them over the derived defaults.
