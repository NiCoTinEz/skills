## Stage 1 — Branch

Name format **`<type>/<short-slug>`**. `<type>` comes from `feat` `fix` `chore` `refactor` `perf`
`docs` `test` `build` `ci` `style` `revert` and must match the commit's type. `<slug>` is lowercase
kebab-case describing what the change does — 2-4 words, 40 chars or fewer in total, no ticket
numbers unless the user gives one, no dates, no author name. Examples: `feat/add-cache-retry`,
`fix/null-ref-login`, `chore/bump-serilog`.

Preflight's two stats name the change in almost every case. Where they don't, read the one path that
matters with `git diff -- <path>` — never the whole tree. **A clean tree has no diff to name a
branch from**: take the name the user passed, and if there is none, ask for one rather than
inventing a slug for work that doesn't exist yet.

One call — preflight already fetched, so this creates and nothing else:

```bash
git switch --create <type>/<slug> <remote>/<base>
```

- **A dirty tree branches off HEAD instead**, so the pending work comes along:
  `git switch --create <type>/<slug>`. That case spends one call first, because branching off a HEAD
  that already carries commits the base lacks would pull them silently into the new branch and a
  later pull request — `git rev-list --left-right --count <remote>/<base>...HEAD`, and if the right
  side isn't `0`, stop and ask rather than creating. Say which of the two forms you used.
- **The name is already taken** — the create fails and says so. Append `-2`, `-3`, … or pick a
  better slug in one more call. Don't probe for collisions first: the create *is* the probe.
- Already on a feature branch that holds this work → **reuse it** instead of stacking a second one,
  and report its upstream and its commits relative to `<base>`. That is a call to make, not a
  question to ask.
