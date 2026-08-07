---
name: commit-push-pr
description: >
  Commit on the current branch, push it, and open a pull request — no new branch created. Use for
  "commit push pr", "PR this branch", "commit and raise a PR".
allowed-tools: Bash, PowerShell, Read, Glob, Grep
---

Run stages **0 → 2 → 3 → 4 → 5**. **Skip stage 1** — commit on the branch already checked out;
never create or switch branches.

**Read `references/core.md`, `references/commit.md`, `references/push.md` and `references/pr.md` —
all next to this file, inside this skill's own folder — before doing anything else.** They hold the
platform detection, base-branch resolution, guardrails, commit format, and the exact `gh` /
`az repos pr` invocations. Do not improvise these from memory.

Stage summary for this skill:

0. **Preflight** (`core.md`) — repo state, platform, base branch, guardrails, plus the `gh`/`az`
   tool check from the top of `pr.md`.
2. **Commit** (`commit.md`) — stage deliberately, Conventional Commits, no AI attribution. Several
   unrelated logical changes → several commits, and the PR gets one summarising title.
3. **Push** (`push.md`) — `git push --set-upstream <remote> HEAD`, using the remote resolved in stage 0.
4. **PR** (`pr.md`) — `gh pr create` or `az repos pr create`. Existing PR for this branch → report
   its URL instead of creating a duplicate.
5. **Report** (`core.md`) — platform / commit / push / pr lines.

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
