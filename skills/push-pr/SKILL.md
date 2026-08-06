---
name: push-pr
description: >
  Push the current branch and open a pull request from the commits already on it — no new branch and
  no new commit. Platform detected from the origin remote (gh for github.com, az repos for
  dev.azure.com). Use when the user says "push pr", "push and open a PR", "PR the commits I already
  made", "open a PR without committing anything", or invokes /push-pr.
allowed-tools: Bash, PowerShell, Read, Glob, Grep
---

Run stages **0 → 3 → 4 → 5** of the shared workflow. **Skip stages 1 and 2** — never create or
switch branches, and never commit. What ships is exactly what is already committed on this branch.

**Read `references/workflow.md` — the file next to this one inside this skill's own folder —
before doing anything else.** It holds the platform detection, base-branch resolution, guardrails,
push handling, and the exact `gh` / `az repos pr` invocations. Do not improvise these from memory.

Stage summary for this skill:

0. **Preflight** — repo state, `<remote>`, `<base>`, guardrails, `gh`/`az` tool check. A clean tree
   is the normal case here, not the "nothing to commit" stop the `commit-*` skills apply.
3. **Push** — `git push --set-upstream <remote> HEAD`, using the remote resolved in stage 0.
   Already up to date → skip the push, say so, and still open the PR.
4. **PR** — `gh pr create` or `az repos pr create`. Existing PR for this branch → report its URL
   instead of creating a duplicate.
5. **Report** — platform / push / pr lines. No commit line: this skill makes none.

**Uncommitted changes are left alone.** Stage 2 doesn't run, so a push carries commits only. If the
tree is dirty, name the paths, state plainly that they stay local and are in neither the push nor
the PR, then continue. Offer `commit-push-pr` if the user meant to include them.

**Nothing to ship.** If no commits separate `<base>` from this branch, there is nothing to push and
no diff to open a PR for. Stop and report — don't reach for a `commit-*` skill on the user's behalf.

**On the default branch this skill is a trap.** Resolve `<base>` as stage 0 describes, then compare
the current branch against it — do not test against a guessed list like `main`/`master`/`develop`,
which misses the `development`, `DEV` and `v1/development` defaults real repos use. If the current
branch **is** `<base>`, a PR cannot target itself, and pushing would go straight to the protected
branch. Stop before pushing and report both facts. The fix is to move the commits onto a branch
first — `git switch --create <type>/<slug>`, then run this skill again — but that is the user's
call, not something to do unasked.

If a CLI or the `azure-devops` extension is missing, **ask the user to install it with the exact
command and stop there** — never install it yourself. Report which stages already completed.

Arguments the user may pass: a base branch, a PR title, `--draft`, a work-item / issue ID,
reviewers. Honour them over the derived defaults.
