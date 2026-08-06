---
name: branch-commit-push
description: >
  Create a type/short-slug branch, write a Conventional Commits commit, and push it with upstream
  tracking — no pull request. Works on GitHub and Azure DevOps repos. Use when the user says
  "branch commit push", "push this on a new branch", "branch and push without a PR", or invokes
  /branch-commit-push.
allowed-tools: Bash, PowerShell, Read, Glob, Grep
---

Run stages **0 → 1 → 2 → 3 → 5** of the shared workflow. **Do not create a pull request** — stop
after the push, even if a PR looks like the obvious next step. Offer `branch-commit-push-pr` as
the follow-up instead.

**Read `references/workflow.md` — the file next to this one inside this skill's own folder —
before doing anything else.** It holds the platform detection, base-branch resolution,
guardrails, branch/commit format, and push handling. Do not improvise these from memory.

Stage summary for this skill:

0. **Preflight** — repo state, platform, base branch, guardrails. No `gh`/`az` check needed.
1. **Branch** — `<type>/<short-slug>` off an up-to-date base (off HEAD if the tree is dirty).
2. **Commit** — stage deliberately, Conventional Commits, no AI attribution. Several unrelated
   logical changes → several commits on the new branch.
3. **Push** — `git push --set-upstream <remote> HEAD`, using the remote resolved in stage 0.
   Non-fast-forward → stop and report.
5. **Report** — platform / branch / commit / push lines only.

Arguments the user may pass: a base branch, a branch name, a commit subject. Honour them over the
derived defaults.
