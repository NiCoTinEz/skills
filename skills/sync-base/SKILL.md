---
name: sync-base
description: >
  Switch back to the repository's base branch — main, master, development, whatever this repo
  actually uses — and fast-forward it to the remote. A dirty tree stops it. Use for "sync base",
  "back to base", "go back to main and pull".
allowed-tools: Bash, PowerShell, Read, Glob, Grep
---

Run stage **0** and stage **5**, with the procedure below in between. **Do not run stages 1–4** —
never create a branch, never commit, never push, never open a pull request.

**Read `references/core.md` — the file next to this one inside this skill's own folder — before
doing anything else.** It holds `<remote>` resolution, the base-branch resolution order, the
guardrails and the report format. Do not improvise these from memory.

0. **Preflight** — repo state, `<remote>`, `<base>`, guardrails. No `gh`/`az` check: this skill
   never reaches a pull request. **Resolving `<base>` correctly is the entire point of the skill** —
   follow the four-step order in `core.md`. A hardcoded `main`/`master` guess lands the user on the
   wrong branch, or on none at all.
5. **Report** — `branch` and `pull` lines, in the shape below.

## Procedure

```bash
git fetch <remote> --prune --quiet
git switch <base>
git pull --ff-only <remote> <base>
```

- **Already on `<base>`** — skip the switch, say so, still pull.
- **No local `<base>` branch yet** — `git switch <base>` creates a tracking branch by itself; if
  that fails, `git switch --track <remote>/<base>`.
- **`--ff-only` is deliberate.** Refused means the local base holds commits the remote does not.
  Stop and report; never rebase, reset, force or merge past it.
- Capture HEAD before and after the pull, so the report can distinguish "already up to date" from
  what was actually brought in.

## Stops

**A dirty tree stops this skill before it touches anything.** `git switch` carries uncommitted
changes onto the target branch without a word. Check `git status --porcelain` first; if anything is
modified, staged or untracked, name the paths and stop:

```
dirty     src/Cache.cs, README.md
          switching would carry these onto 'development'
```

Offer `commit` or `branch-commit` first. Stash only if the user asks in that turn, and then say
where the stash landed — a `git stash pop` after the switch lands the changes on `<base>`, not on
the branch they came from.

Detached HEAD, merge in progress and rebase in progress are `core.md` guardrails: stop and report.

## Report

Name the branch it came from, and the range pulled:

```
branch    development  (was feat/add-cache-retry)
pull      <remote>/development  4 new commits  a1b2c3d..e4f5a6b
```

Already current → `pull      already up to date`. Already on `<base>` → say so on the `branch` line
instead of naming a previous branch.

**Deleting the branch you left is not this skill's job**, even when its pull request has merged.

Arguments the user may pass: a branch to treat as `<base>`, or a remote name. Honour them, and never
"normalise" the casing of a name you were given.
