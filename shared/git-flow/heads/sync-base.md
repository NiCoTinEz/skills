---
name: sync-base
description: >
  Switch back to the repository's base branch — main, master, development, whatever this repo
  actually uses — and fast-forward it to the remote. A dirty tree stops it. Use for "sync base",
  "back to base", "go back to main and pull".
allowed-tools: Bash, PowerShell, Read, Glob, Grep
---

Run stage **0**, then the procedure below, then stage **5**. **Do not run
stages 1-4** — never create a branch, never commit, never push, never open a pull request. Stage 0
skips the `gh` / `az` check, and **resolving `<base>` correctly is the entire point of this skill**:
follow the order below, because a hardcoded `main` / `master` guess lands the user on the wrong
branch or on none at all. Three tool calls: preflight, switch, pull.

Arguments the user may pass: a branch to treat as `<base>`, or a remote name. Honour them, and never
"normalise" the casing of a name you were given.
