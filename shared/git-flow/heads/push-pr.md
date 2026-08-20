---
name: push-pr
description: >
  Push the current branch and open a pull request from the commits already on it — no new branch and
  no new commit. Use for "push pr", "push and open a PR", "PR the commits I already made".
allowed-tools: Bash, PowerShell, Read, Glob, Grep
---

Run stages **0 → 3 → 4 → 5**, all of them below. **Skip stages 1 and 2** — never create or switch
branches, and never commit. What ships is exactly what is already committed on this branch, so a
clean tree is the normal case, not the "nothing to commit" stop the `commit` skills apply. Stage 3
already pushed, so stage 4 can drop its two parity lines.

**Nothing to ship.** If no commits separate `<base>` from this branch, there is nothing to push and
no diff to open a pull request for. Stop and report — don't reach for a commit skill unasked.

**On the default branch this skill is a trap.** Compare the current branch against the `<base>`
stage 0 resolved — never against a guessed list of names. If they match, a pull request cannot
target itself *and* the push would go straight to the protected branch: stop before pushing and
report both. Moving the commits onto a branch first is the user's call.

If a CLI or the `azure-devops` extension is missing, **ask the user to install it with the exact
command and stop there** — never install it yourself. Report which stages already completed.

Arguments the user may pass: a base branch, a PR title, `--draft`, a work-item / issue ID,
reviewers. Honour them over the derived defaults.
