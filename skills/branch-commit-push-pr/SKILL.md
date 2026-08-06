---
name: branch-commit-push-pr
description: >
  Full ship flow on GitHub or Azure DevOps: create a type/short-slug branch, write a Conventional
  Commits commit, push with upstream, and open a pull request. Platform detected from the origin
  remote (gh for github.com, az repos for dev.azure.com). Use when the user says "branch commit
  push pr", "ship this", "open a PR for this", "make a branch and PR", or invokes
  /branch-commit-push-pr.
allowed-tools: Bash, PowerShell, Read, Glob, Grep
---

Run stages **0 → 1 → 2 → 3 → 4 → 5** of the shared workflow.

**Read `references/workflow.md` — the file next to this one inside this skill's own folder —
before doing anything else.** It holds the platform detection, base-branch resolution,
guardrails, branch/commit format, and the exact `gh` / `az repos pr` invocations. Do not
improvise these from memory.

Stage summary for this skill:

0. **Preflight** — repo state, platform, base branch, guardrails, `gh`/`az` tool check.
1. **Branch** — `<type>/<short-slug>` off an up-to-date base (off HEAD if the tree is dirty).
2. **Commit** — stage deliberately, Conventional Commits, no AI attribution. Several unrelated
   logical changes → several commits, and the PR gets one summarising title.
3. **Push** — `git push --set-upstream <remote> HEAD`, using the remote resolved in stage 0.
4. **PR** — `gh pr create` or `az repos pr create`, body = Summary + Test plan.
5. **Report** — the compact platform/branch/commit/push/pr block.

If a CLI or the `azure-devops` extension is missing, **ask the user to install it with the exact
command and stop there** — never install it yourself. Report which stages already completed.

Arguments the user may pass: a base branch, a branch name, a commit subject, `--draft`, a
work-item / issue ID, reviewers. Honour them over the derived defaults.
