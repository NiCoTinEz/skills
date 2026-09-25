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
- **Counts `0 0` and a silent push** — it pushed if stage 2 just committed, or the preflight `##`
  header showed no `...<upstream>` (a first push) or `[ahead N]`. Otherwise nothing moved: report
  `push      skipped: already up to date`. A rejected push says so on its own line, and then the
  counts name the shape: left non-zero with right zero is behind, both non-zero is diverged. Report
  the two sides and stop — never force, never rebase to make it fit.
- **A skill that opens a pull request runs stage 4's call one before this push**, without its two
  parity lines: a `0` ahead-of-base count, or a failed `gh` / `az` call, stops before anything is
  pushed. An open PR does not stop the push — the push updates it; report its URL and skip call two.
- **Uncommitted changes, for a skill that skips stage 2** (`push`, `push-pr`): a push carries
  commits, not working-tree state. Name the dirty paths, say plainly that they stay local and appear
  in neither the push nor the pull request, then continue. Offer the matching commit skill.
- On the default branch (stage 0's definition) or a protected one — possible for any skill that
  skips stage 1 — warn plainly that this pushes straight to it, and get explicit confirmation first.
