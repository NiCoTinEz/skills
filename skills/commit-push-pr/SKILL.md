---
name: commit-push-pr
description: >
  Commit on the current branch, push it, and open a pull request — no new branch created. Platform
  detected from the origin remote (gh for github.com, az repos for dev.azure.com). Use when the
  user says "commit push pr", "PR this branch", "open a PR from here", "commit and raise a PR", or
  invokes /commit-push-pr.
allowed-tools: Bash, PowerShell, Read, Glob, Grep
---

Run stages **0 → 2 → 3 → 4 → 5** of the shared workflow. **Skip stage 1** — commit on the branch
already checked out; never create or switch branches.

**Read `references/workflow.md` — the file next to this one inside this skill's own folder —
before doing anything else.** It holds the platform detection, base-branch resolution,
guardrails, commit format, and the exact `gh` / `az repos pr` invocations. Do not improvise these
from memory.

Stage summary for this skill:

0. **Preflight** — repo state, platform, base branch, guardrails, `gh`/`az` tool check.
2. **Commit** — stage deliberately, Conventional Commits, no AI attribution.
3. **Push** — `git push --set-upstream <remote> HEAD`, using the remote resolved in stage 0.
4. **PR** — `gh pr create` or `az repos pr create`. Existing PR for this branch → report its URL
   instead of creating a duplicate.
5. **Report** — platform / commit / push / pr lines.

**On the default branch this skill is a trap.** Resolve `<base>` as stage 0 describes, then compare
the current branch against it — do not test against a guessed list of names like
`main`/`master`/`develop`, which misses the `development`, `DEV` and `v1/development` defaults real
repos use. If the current branch **is** `<base>`, a PR cannot target itself: stop before committing,
say so, and offer `branch-commit-push-pr` instead. Only proceed if the user explicitly insists on a
different base.

If a CLI or the `azure-devops` extension is missing, **ask the user to install it with the exact
command and stop there** — never install it yourself. Report which stages already completed.

Arguments the user may pass: a base branch, a commit subject, `--draft`, a work-item / issue ID,
reviewers. Honour them over the derived defaults.
