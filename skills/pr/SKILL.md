---
name: pr
description: >
  Open a pull request for the commits already pushed on the current branch — no new branch, no
  commit, and no push. Use for "pr", "open a PR", "PR this branch".
allowed-tools: Bash, PowerShell, Read, Glob, Grep
---

Run stages **0 → 4 → 5**. **Skip stages 1, 2 and 3** — never create or switch branches, never
commit, and **never push**. The pull request describes what the remote already has.

**Read `references/core.md` and `references/pr.md` — both next to this file, inside this skill's own
folder — before doing anything else.** They hold platform detection, base-branch resolution, the
guardrails and the exact `gh` / `az repos pr` invocations. Do not improvise these from memory.

Stage summary for this skill:

0. **Preflight** (`core.md`) — repo state, `<remote>`, `<base>`, guardrails, plus the `gh`/`az` tool
   check from the top of `pr.md`. A clean tree is the normal case here.
4. **PR** (`pr.md`) — verify the branch is on `<remote>` and HEAD is not ahead of it, then
   `gh pr create` or `az repos pr create`. Existing PR → report its URL, don't duplicate.
5. **Report** (`core.md`) — platform and pr lines. No commit line, no push line.

**Unpushed commits stop this skill; they do not trigger a push.** If `<remote>/<branch>` does not
exist, or local HEAD sits ahead of it, stop, say which of the two it is, and offer `push-pr`. Do not
push on the user's behalf — that is stage 3.

**Uncommitted changes are left alone**, and are in neither the commits nor the PR. Name the dirty
paths so the user sees what the PR excludes, then continue. Offer `commit-push-pr` if they meant to
include them.

**On the default branch a PR is impossible** — it cannot target itself. Compare the current branch
against the `<base>` resolved in stage 0; if they match, stop and report. Moving the commits onto a
branch is the user's call.

If a CLI or the `azure-devops` extension is missing, **ask the user to install it with the exact
command and stop there** — never install it yourself.

Arguments the user may pass: a base branch, a PR title, `--draft`, a work-item / issue ID,
reviewers. Honour them over the derived defaults.
