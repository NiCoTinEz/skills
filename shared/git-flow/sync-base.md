## Procedure — two calls

Land on the base first:

```bash
git fetch <remote> --prune --quiet
git switch <base>
git rev-parse --short HEAD
```

Then, once that reports you are actually on `<base>`:

```bash
git pull --ff-only <remote> <base>
git log --oneline -1
```

**Why two, when one call is the rule everywhere else.** `git switch <base>` can fail — a base that
doesn't exist locally and is ambiguous across remotes, or a convention line naming a branch this
repo doesn't have. Batched, the pull would then run on the branch you are still standing on and
fast-forward *that* to the base; a just-merged feature branch is strictly behind its base, so it
would move without complaint. The two `HEAD` readings also give the report its range for free.

- **A dirty tree stops this skill before it touches anything**, so preflight decides whether the
  first block runs at all — it already listed the porcelain status, and a guard *inside* the block
  would be useless, since every line runs before you see any of the output. `git switch` carries
  uncommitted changes onto the target branch without a word. Anything modified, staged or untracked:
  name the paths and stop without running it.

```
dirty     src/Cache.cs, README.md
          switching would carry these onto 'development'
```

  Offer `commit` or `branch-commit` first. Stash only if the user asks in that turn, and then say
  where the stash landed: a `git stash pop` after the switch drops the changes on `<base>`, not on
  the branch they came from.
- **Already on `<base>`** — skip the switch, say so, still pull.
- **No local `<base>` branch yet** — `git switch <base>` creates a tracking branch by itself; if
  that fails, `git switch --track <remote>/<base>`.
- **`--ff-only` is deliberate.** Refused means the local base holds commits the remote does not:
  stop and report, never rebase, reset, force or merge past it.
- Detached HEAD, merge in progress and rebase in progress are stage 0 guardrails: stop and report.

## Stage 5 — Report

Name the branch it came from and the range pulled. One compact block, no prose padding:

```
branch    development  (was feat/add-cache-retry)
pull      <remote>/development  4 new commits  a1b2c3d..e4f5a6b
```

Already current → `pull      already up to date`. Already on `<base>` → say so on the `branch` line
instead of naming a previous branch. **Deleting the branch you left is not this skill's job**, even
when its pull request has merged.
