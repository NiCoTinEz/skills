---
name: branch-commit-push-pr
description: >
  Full ship flow: create a type/short-slug branch, write a Conventional Commits commit, push with
  upstream, and open a pull request. Use for "branch commit push pr", "ship this", "make a branch
  and PR".
allowed-tools: Bash, PowerShell, Read, Glob, Grep
---

Run stages **0 → 1 → 2 → 3 → 4 → 5** — the whole procedure.

**Read `references/core.md`, `references/branch.md`, `references/commit.md`, `references/push.md`
and `references/pr.md` — all next to this file, inside this skill's own folder — before doing
anything else.** They hold the platform detection, base-branch resolution, guardrails,
branch/commit format, and the exact `gh` / `az repos pr` invocations. Do not improvise these from
memory.

Stage summary for this skill:

0. **Preflight** (`core.md`) — repo state, platform, base branch, guardrails, plus the `gh`/`az`
   tool check from the top of `pr.md`.
1. **Branch** (`branch.md`) — `<type>/<short-slug>` off an up-to-date base (off HEAD if the tree is dirty).
2. **Commit** (`commit.md`) — stage deliberately, Conventional Commits, no AI attribution. Several
   unrelated logical changes → several commits, and the PR gets one summarising title.
3. **Push** (`push.md`) — `git push --set-upstream <remote> HEAD`, using the remote resolved in stage 0.
4. **PR** (`pr.md`) — `gh pr create` or `az repos pr create`, body = Summary + Test plan.
5. **Report** (`core.md`) — the compact platform/branch/commit/push/pr block.

If a CLI or the `azure-devops` extension is missing, **ask the user to install it with the exact
command and stop there** — never install it yourself. Report which stages already completed.

Arguments the user may pass: a base branch, a branch name, a commit subject, `--draft`, a
work-item / issue ID, reviewers. Honour them over the derived defaults.
