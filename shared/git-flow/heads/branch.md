---
name: branch
description: >
  Create a type/short-slug branch and switch to it — nothing else. No commit, no push, no pull
  request; the working tree is left exactly as it was. Use for "branch", "make a branch", "new
  branch for this".
allowed-tools: Bash, PowerShell, Read, Glob, Grep
---

Run stages **0 → 1 → 5**, all of them below. **Skip stages 2, 3 and 4** — never commit, never push,
never open a pull request. Uncommitted work stays uncommitted, on the new branch. Stage 0 still
resolves `<remote>` and `<base>`, and skips the `gh` / `az` check.

**The working tree is not touched** — staged stays staged, modified stays modified, and
`git switch --create` carries both onto the new branch. Say so, and offer `branch-commit` if the
user meant to commit as well.

Arguments the user may pass: a branch name, a type, a base branch. Honour them over the derived
defaults, and never "normalise" the casing of a name you were given.
