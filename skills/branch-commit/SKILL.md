---
name: branch-commit
description: >
  Create a type/short-slug branch and commit the current work with a Conventional Commits message.
  Stays local — no push, no pull request. Works on GitHub and Azure DevOps repos. Use when the
  user says "branch commit", "commit this on a new branch", "branch it locally", or invokes
  /branch-commit.
allowed-tools: Bash, Read, Glob, Grep
---

Run stages **0 → 1 → 2 → 5** of the shared workflow. **Do not push and do not create a pull
request** — the commit stays local. Offer `branch-commit-push` as the follow-up.

**Read `references/workflow.md` — the file next to this one inside this skill's own folder —
before doing anything else.** It holds base-branch resolution, guardrails, and the
branch/commit format. Do not improvise these from memory.

Stage summary for this skill:

0. **Preflight** — repo state, base branch, guardrails. No CLI check needed.
1. **Branch** — `<type>/<short-slug>` off an up-to-date base (off HEAD if the tree is dirty).
2. **Commit** — stage deliberately, Conventional Commits, no AI attribution.
5. **Report** — branch and commit lines only, plus the reminder that nothing was pushed.

Arguments the user may pass: a base branch, a branch name, a commit subject. Honour them over the
derived defaults.
