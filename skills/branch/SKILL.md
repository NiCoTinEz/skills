---
name: branch
description: >
  Create a type/short-slug branch and switch to it — nothing else. No commit, no push, no pull
  request; the working tree is left exactly as it was. Use for "branch", "make a branch", "new
  branch for this".
allowed-tools: Bash, PowerShell, Read, Glob, Grep
---

Run stages **0 → 1 → 5**. **Skip stages 2, 3 and 4** — never commit, never push, never open a pull
request. Uncommitted work stays uncommitted, on the new branch.

**Read `references/core.md` and `references/branch.md` — both next to this file, inside this skill's
own folder — before doing anything else.** They hold base-branch resolution, the guardrails and the
branch name format. Do not improvise these from memory.

Stage summary for this skill:

0. **Preflight** (`core.md`) — repo state, `<remote>`, `<base>`, guardrails. No `gh`/`az` check:
   this skill never reaches a pull request. `<remote>` is still needed — stage 1 fetches from it.
1. **Branch** (`branch.md`) — off `<remote>/<base>` when the tree is clean, off HEAD when it is
   dirty so pending work comes along. Say which of the two you used.
5. **Report** (`core.md`) — branch line only, naming the base it came from, plus the reminder that
   nothing was committed.

**A clean tree has no diff to name the branch from**, and this skill can run before any work exists.
Take the name the user passed; if they passed none and the tree is clean, ask rather than invent one.

**The working tree is not touched** — staged stays staged, modified stays modified, and
`git switch --create` carries both onto the new branch. Say so, and offer `branch-commit` if the
user meant to commit as well.

**Already on a feature branch?** If it already holds the pending work, say so and confirm before
creating a second one.

Arguments the user may pass: a branch name, a type, a base branch. Honour them over the derived
defaults, and never "normalise" the casing of a name you were given.
