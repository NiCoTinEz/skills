---
name: push
description: >
  Push the commits already on the current branch, setting upstream on the first push — no new
  branch, no commit, no pull request. Use for "push", "push only", "push without a PR".
allowed-tools: Bash, PowerShell, Read, Glob, Grep
---

Run stages **0 → 3 → 5**. **Skip stages 1, 2 and 4** — never create or switch branches, never
commit, never open a pull request. What ships is exactly what is already committed.

**Read `references/core.md` and `references/push.md` — both next to this file, inside this skill's
own folder — before doing anything else.** They hold platform detection, base-branch resolution,
the guardrails and the push handling. Do not improvise these from memory.

Stage summary for this skill:

0. **Preflight** (`core.md`) — repo state, `<remote>`, `<base>`, guardrails. No `gh`/`az` check:
   this skill never reaches a pull request. A clean tree is the normal case here, not the "nothing
   to commit" stop the `commit-*` skills apply.
3. **Push** (`push.md`) — `git push --set-upstream <remote> HEAD`. Already up to date → report
   `push      skipped: already up to date` and stop; that is not an error. Non-fast-forward → stop
   and report; never force-push or rebase without approval.
5. **Report** (`core.md`) — push line only. No commit line, no pr line.

**Uncommitted changes are left alone.** Stage 2 doesn't run, so the push carries commits only. Name
the dirty paths, say they stay local, then continue. Offer `commit-push` if the user meant to
include them.

**Pushing to the default branch.** Resolve `<base>` as `core.md` describes and compare the current
branch against it. If they are the same, warn plainly and get explicit confirmation before pushing.

Offer the follow-up: `push-pr` if a pull request should follow, `commit-push` if work still needed
committing first.

Arguments the user may pass: a remote name. Honour it, and use that same name for every command.
