## Stage 3 — Push

One call. Preflight already fetched, and force-pushing is banned, so git itself refuses anything
that isn't a fast-forward — probing before the push only spends a round trip to learn what the push
would have told you. The counts come *after* the push, not before: on a first push the remote branch
doesn't exist yet, and asking about it first answers `ambiguous argument` instead of pushing.

```bash
git push --quiet --set-upstream "<remote>" HEAD
git rev-list --left-right --count "<remote>/<branch>...HEAD"
```

- **Always name `<remote>` explicitly.** A bare `git push` can follow a pre-existing upstream on a
  different remote than the one stage 0 resolved. `--set-upstream` is harmless when the upstream
  already matches, and corrects it after an explicitly approved remote change.
- `--quiet` drops the transfer progress and the `To <url>` summary. It does **not** stop the host's
  post-push banner — GitHub's "Create a pull request" block arrives over the side-band as `remote:`
  lines and no client-side flag suppresses it. Don't redirect stderr either: that would take the
  rejections and hook failures with it, and those are the output actually worth reading.
- **Counts `0 0` and a silent push** — either it succeeded or there was nothing to push; the
  `git status` header from preflight tells you which, and if nothing moved, report
  `push      skipped: already up to date`. A rejected push says so on its own line, and then the
  counts name the shape: left non-zero with right zero is behind, both non-zero is diverged. Report
  the two sides and stop — never force, never rebase to make it fit.
- **Uncommitted changes, for a skill that skips stage 2** (`push`, `push-pr`): a push carries
  commits, not working-tree state. Name the dirty paths, say plainly that they stay local and appear
  in neither the push nor the pull request, then continue. Offer the matching commit skill.
- On the default or a protected branch — possible for any skill that skips stage 1 — warn plainly
  that this goes straight to `<base>`, and get explicit confirmation before pushing.
