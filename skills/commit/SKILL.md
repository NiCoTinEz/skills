---
name: commit
description: >
  Commit the current work on the branch already checked out, with a Conventional Commits message —
  no new branch, no push, no pull request. Works on GitHub and Azure DevOps repos. Use when the user
  says "commit", "commit this", "commit only", "just commit", "commit without pushing", or invokes
  /commit.
allowed-tools: Bash, PowerShell, Read, Glob, Grep
---

Run stages **0 → 2 → 5** of the shared workflow. **Skip stages 1, 3 and 4** — never create or switch
branches, never push, never open a pull request. The commit stays local.

**Read `references/workflow.md` — the file next to this one inside this skill's own folder —
before doing anything else.** It holds the guardrails and the commit format. Do not improvise
these from memory.

Stage summary for this skill:

0. **Preflight** — repo state and guardrails. No platform detection, no `<remote>`, no CLI check:
   this skill reaches no remote. Resolve `<base>` only from the local tracking ref, and only so the
   report can name it — never call the platform for it.
2. **Commit** — stage deliberately, Conventional Commits, no AI attribution.
5. **Report** — commit line only, plus the reminder that nothing was pushed.

**Say which branch the commit landed on.** Nothing is pushed, so committing onto the default branch
is recoverable and not worth stopping for — but name the branch in the report either way, and if it
is `<base>`, say so plainly rather than leaving the user to notice. Offer `branch-commit` if they
wanted the work isolated on its own branch instead.

Offer the follow-ups: `commit-push` to push this commit, `commit-push-pr` to push it and open a pull
request, `push-pr` if the commits are all in place and only the push and PR remain.

Arguments the user may pass: a commit subject, or specific paths to stage. Honour them over the
derived defaults.
