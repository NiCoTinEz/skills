## Stage 5 — Report

One compact block, no prose padding. Omit the lines for stages this skill doesn't run; a stage that
was skipped or failed keeps its line and carries the reason.

```
platform  GitHub | Azure DevOps
branch    feat/add-cache-retry  (from main)
commit    a1b2c3d  feat(cache): add retry on transient Redis failure
included  already staged: src/example.cs
push      <remote>/feat/add-cache-retry
pr        https://github.com/owner/repo/pull/42
```

Omit `included` when nothing was pre-staged. A commit-only skill may keep `branch` as context, minus
the `(from <base>)` suffix it never resolved.
For several commits, use one `commit` line each, oldest first:

```
branch    fix/tidy-cache-layer  (from main)
commit    a1b2c3d  fix(cache): guard against a null connection
commit    e4f5a6b  refactor(cache): extract the key builder
```
