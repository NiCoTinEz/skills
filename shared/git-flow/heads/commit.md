---
name: commit
description: >
  Commit the current work on the branch already checked out, with a Conventional Commits message —
  no new branch, no push, no pull request. Use for "commit", "commit only", "commit without
  pushing".
allowed-tools: Bash, PowerShell, Read, Glob, Grep
---

Run stages **0 → 2 → 5**, all of them below. **Skip stages 1, 3 and 4** — never create or switch
branches, never push, never open a pull request. The commit stays local, so stage 0 has no remote
half at all: no `<remote>`, no `<base>`, no fetch, no CLI check, and the report names the current
branch directly. Two tool calls for one commit.

**This is the best skill in the set for splitting a mixed tree.** Nothing is pushed, so a wrong
grouping costs only a local reset the user can ask for. Split by logical change as stage 2
describes, order the commits so each stands on its own, and list them all in the report.

**Say which branch the commit landed on.** This skill doesn't resolve a base or stop based on the
branch name; it names the current branch in the report. Offer `branch-commit` if the user wanted the
work isolated on its own branch instead.

Offer the follow-ups: `commit-push` to push this commit, `commit-push-pr` to push it and open a pull
request, `push-pr` if the commits are all in place and only the push and PR remain.

Arguments the user may pass: a commit subject, or specific paths to stage. Honour them over the
derived defaults.
