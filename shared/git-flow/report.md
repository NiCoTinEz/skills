## Stage 5 — Report

One compact block, no prose padding. Omit the lines for stages this skill doesn't run; a stage that
was skipped or failed keeps its line and carries the reason.

```
platform  GitHub | Azure DevOps
branch    feat/add-cache-retry  (from main)
commit    a1b2c3d  feat(cache): add retry on transient Redis failure
push      <remote>/feat/add-cache-retry
pr        https://github.com/owner/repo/pull/42
```

A commit-only skill may keep the `branch` line as context, naming where the commit landed. Stage 2
split the work into several commits, so one `commit` line each, oldest first:

```
branch    fix/tidy-cache-layer  (from main)
commit    a1b2c3d  fix(cache): guard against a null connection
commit    e4f5a6b  refactor(cache): extract the key builder
```
