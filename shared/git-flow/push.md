# git-flow stage 3 — Push

Read alongside `core.md`, which holds preflight, `<remote>` / `<base>` resolution, the guardrails
and the report format.

```bash
git push --quiet --set-upstream <remote> HEAD
```

- Already has upstream → plain `git push --quiet`.
- `--quiet` drops git's own transfer progress and the `To <url>` / `* [new branch]` summary.
  It does **not** stop the host's post-push banner — GitHub's "Create a pull request for …" block
  arrives over the side-band as `remote:` lines, and no client-side flag suppresses it. Redirecting
  stderr would take the rejections and hook failures with it, so don't. Those, and errors, are the
  output here actually worth reading.
- **Nothing to push** — `git rev-list --count <remote>/<branch>..HEAD` returns `0`, i.e. the branch
  has an upstream and sits no commits ahead of it. Skip the push, report it as
  `push      skipped: already up to date`, and carry on to the next stage. This is **not** an error.
  Only a skill that skips stage 2 can reach it, since a fresh commit always leaves the branch ahead.
- **Uncommitted changes, for a skill that skips stage 2** (`push`, `push-pr`): a push carries commits, not
  working-tree state. Name the dirty paths, say plainly that they stay local and appear in neither
  the push nor the PR, then continue. Offer the matching `commit-*` skill if the user wanted them
  included.
- **Rejected as non-fast-forward:** stop. Report it and offer `git pull --rebase <remote> <branch>`
  as a *suggestion*. Do not force-push, do not rebase without approval.
- Currently on the default/protected branch (possible for any skill that skips stage 1): warn
  clearly that this pushes straight to `<base>` and get explicit confirmation before pushing.
