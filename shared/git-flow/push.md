# git-flow stage 3 — Push

Read alongside `core.md`, which holds preflight, `<remote>` / `<base>` resolution, the guardrails
and the report format.

Fetch first, then compare both directions before deciding what to do:

```bash
git fetch "<remote>" --quiet
git rev-list --left-right --count "<remote>/<branch>...HEAD"
git push --quiet --set-upstream "<remote>" HEAD
```

- Always name `<remote>` explicitly. A plain `git push` can follow a pre-existing upstream on a
  different remote, violating the remote selected in stage 0. `--set-upstream` is harmless when the
  current upstream already matches and corrects it after an explicitly approved remote change.
- `--quiet` drops git's own transfer progress and the `To <url>` / `* [new branch]` summary.
  It does **not** stop the host's post-push banner — GitHub's "Create a pull request for …" block
  arrives over the side-band as `remote:` lines, and no client-side flag suppresses it. Redirecting
  stderr would take the rejections and hook failures with it, so don't. Those, and errors, are the
  output here actually worth reading.
- **Nothing to push** — the refreshed remote ref exists and the left/right counts are `0 0`. Skip
  the push, report `push      skipped: already up to date`, and carry on. Left greater than zero and
  right zero means local is behind; both greater than zero means it diverged. Stop for either rather
  than calling it current. A missing remote branch is a first push, not an error.
- **Uncommitted changes, for a skill that skips stage 2** (`push`, `push-pr`): a push carries commits, not
  working-tree state. Name the dirty paths, say plainly that they stay local and appear in neither
  the push nor the PR, then continue. Offer the matching `commit-*` skill if the user wanted them
  included.
- **Rejected as non-fast-forward:** stop. Fetch and report the two sides of the divergence. Offer
  merge or rebase only as choices for explicit approval; do not force-push or rewrite anything.
- Currently on the default/protected branch (possible for any skill that skips stage 1): warn
  clearly that this pushes straight to `<base>` and get explicit confirmation before pushing.
