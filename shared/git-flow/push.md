## Stage 3 — Push

One call. Force-pushing is banned, so git itself refuses a non-fast-forward; don't probe first. The
counts come *after* the push: before a first push the remote branch doesn't exist yet.

```bash
git push --quiet --set-upstream "<remote>" HEAD
git rev-list --left-right --count "<remote>/<branch>...HEAD"
```

- **Always name `<remote>` explicitly.** A bare `git push` can follow a pre-existing upstream on a
  different remote than the one stage 0 resolved. `--set-upstream` is harmless when the upstream
  already matches, and corrects it after an explicitly approved remote change.
- `--quiet` drops progress and the `To <url>` line, not the host's `remote:` banner. Never redirect
  stderr to hide that: rejections and hook failures arrive there too.
- **Counts `0 0` and a silent push** — either it succeeded or there was nothing to push; the
  `git status` header from preflight tells you which, and if nothing moved, report
  `push      skipped: already up to date`. A rejected push says so on its own line, and then the
  counts name the shape: left non-zero with right zero is behind, both non-zero is diverged. Report
  the two sides and stop — never force, never rebase to make it fit.
- **`push-pr` runs stage 4's call one first**, without its two parity lines: a `0` ahead-of-base
  count stops before anything is pushed. An open PR does not stop the push — the push updates it.
- **Uncommitted changes, for a skill that skips stage 2** (`push`, `push-pr`): a push carries
  commits, not working-tree state. Name the dirty paths, say plainly that they stay local and appear
  in neither the push nor the pull request, then continue. Offer the matching commit skill.
- On the default or a protected branch — possible for any skill that skips stage 1 — warn plainly
  that this goes straight to `<base>`, and get explicit confirmation before pushing.
