<!-- generated from shared/git-flow/branch.md — edit that file, then run: npm run build -->

# git-flow stage 1 — Branch

Read alongside `core.md`, which holds preflight, `<remote>` / `<base>` resolution, the guardrails
and the report format. Only for `branch` and the skills whose name starts with `branch-`.

Name format: **`<type>/<short-slug>`**

- `<type>` ∈ `feat` `fix` `chore` `refactor` `perf` `docs` `test` `build` `ci` `style` `revert`
  — same vocabulary as the commit type, and it must match the commit's type.
- `<slug>` lowercase kebab-case, derived from what the change actually does, 2–4 words,
  ≤ 40 chars total. No ticket numbers unless the user gives one, no dates, no author name.
- Examples: `feat/add-cache-retry`, `fix/null-ref-login`, `chore/bump-serilog`.

Procedure:

1. Read the change to pick type + slug — **stat first, never a bare `git diff`**:

```bash
git diff --stat
git diff --staged --stat
```

   A file list with line counts names the change in almost every case. Where it doesn't, read that
   one path (`git diff -- <path>`), not the whole tree. On a mid-size change `git diff` runs to tens
   of thousands of tokens against a few hundred for `--stat` — measured at 128× on a real tree — and
   a branch slug is 2–4 words either way.

   **A skill with no commit stage (`branch`) can meet a clean tree**, and then there is no diff to
   derive a name from. Take the name the user passed; if they passed none and the tree is clean,
   ask for one. Never invent a slug from nothing — a branch named for work that doesn't exist yet
   is worse than a question.
2. Fetch before checking the name. If the branch already exists locally or on `<remote>`, append
   `-2`, `-3`, … or pick a better slug.
3. Create from an up-to-date base:

```bash
git fetch <remote> --quiet
git switch --create <type>/<slug> <remote>/<base>
```

   **Exception — uncommitted work must come along.** If the tree is dirty, first inspect
   `<remote>/<base>...HEAD`. If HEAD contains commits not on the base, stop and ask: branching here
   would silently carry those commits into the new branch and a later PR. Otherwise branch off the
   current HEAD so the working tree is preserved:

```bash
git switch --create <type>/<slug>
```

   Say which of the two you used and why.
4. If the user already sits on a non-default feature branch with the pending work, show its
   upstream and commits relative to `<remote>/<base>`, then confirm before reusing it. Reuse can add
   work to an existing PR, so never make that choice silently.
