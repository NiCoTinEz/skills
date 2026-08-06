---
name: commit-push
description: >
  Commit on the current branch with a Conventional Commits message and push it — no new branch, no
  pull request. Works on GitHub and Azure DevOps repos. Use when the user says "commit push",
  "commit and push", "push this up", or invokes /commit-push.
allowed-tools: Bash, PowerShell, Read, Glob, Grep
---

Run stages **0 → 2 → 3 → 5** of the shared workflow. **Skip stage 1** (never create or switch
branches) and **do not create a pull request**.

**Read `references/workflow.md` — the file next to this one inside this skill's own folder —
before doing anything else.** It holds the guardrails, commit format, and push handling.
Do not improvise these from memory.

Stage summary for this skill:

0. **Preflight** — repo state, `<remote>`, `<base>`, guardrails. No CLI check needed. `<base>` is
   needed even here: the default-branch warning below compares against it.
2. **Commit** — stage deliberately, Conventional Commits, no AI attribution. Several unrelated
   logical changes → several commits, all pushed together.
3. **Push** — `git push --set-upstream <remote> HEAD`, using the remote resolved in stage 0.
   Non-fast-forward → stop and report; never force-push or rebase without approval.
5. **Report** — commit and push lines.

**Pushing to the default branch.** Resolve `<base>` as stage 0 describes and compare the current
branch against it — a guessed list like `main`/`master`/`develop` misses the `development`, `DEV`
and `v1/development` defaults real repos use, and a missed match means pushing to a protected branch
with no warning at all. If the current branch **is** `<base>`, warn plainly that this pushes
straight to it and get explicit confirmation before the push. The commit may be made first; the push
must wait for the answer.

Arguments the user may pass: a commit subject. Honour it over the derived default.
