# git-flow core reference

Shared preflight, guardrails and report format for every skill in this set. Each skill runs a
contiguous subset of the stages below, in order, and stops at the last one. The stages between
preflight and report live in their own files, and a skill only carries the ones it runs:
`branch.md` (stage 1), `commit.md` (stage 2), `push.md` (stage 3), `pr.md` (stage 4). Read the
ones your skill names alongside this file.

Stages: **0 preflight → 1 branch → 2 commit → 3 push → 4 pull request → 5 report**

A skill outside that chain may instead run stage 0 and stage 5 alone, with its own procedure between
them — it still resolves `<remote>` and `<base>` here, and still reports in stage 5's format.

---

## Stage 0 — Preflight (always)

Run these first, in one batch:

```bash
git rev-parse --show-toplevel
git status --porcelain=v1 --branch
git remote get-url origin
git log --oneline -5
```

Derive:

| Fact | How |
|---|---|
| repo root | `git rev-parse --show-toplevel` |
| current branch | `## <branch>...` line of `git status --branch` |
| dirty? | any porcelain lines |
| staged? | porcelain lines whose **first** column is not space/`?` |
| `<remote>` | see *Platform detection* |
| platform | see *Platform detection* |
| base branch | see *Base branch* |

### Command discipline

Every command in these files is written to print the answer and nothing else, because everything it
prints is paid for. Two rules, both load-bearing:

**Keep output scoped.** Prefer `--stat`, `--query … -o tsv`, `--quiet`, `--porcelain` over a full
dump, and never run a command whose complete output you won't use. `git diff` on a mid-size change is
tens of thousands of tokens where `git diff --stat` is a few hundred, and `az --version` is 22 lines
where `az version -o tsv` is one.

**Write commands that run in both Bash and PowerShell.** Agents are configured with either, and both
of these fail silently or loudly on the wrong one:

- **One command per line — no `\` continuation, and no backtick.** `\` is a PowerShell parse error
  (`Missing expression after unary operator '--'`), backtick breaks Bash. A long single line runs
  everywhere; that is worth more than the wrapping.
- **No nested quotes inside `--query`.** `--query '"azure-cli"'` returns `2.86.0` in Bash and
  `ERROR: argument --query: invalid jmespath_type value` in PowerShell, which strips the inner
  quotes. Any JMESPath key needing `"…"` — every hyphenated key — cannot be written portably, so
  pick a query that doesn't need one. `--query name`, `--query "[0].id"` and
  `--query "{a:x.y,b:z}"` are all fine in both.

Where a command genuinely has no portable form, give both variants explicitly — the commit in
`commit.md` does this with a Bash heredoc and a PowerShell here-string.

Everything below writes `<remote>` where a remote name is needed. **It is usually `origin`, but
resolve it once here and then substitute the name you resolved into every later command** — base
resolution, branch creation, push and PR all have to agree on one remote. Never hardcode `origin`
after this point.

A skill that reaches no remote stage (`commit`) needs neither `<remote>` nor platform detection.
Resolve `<base>` for it from the local tracking ref only, and only because the report names the
branch — never spend a platform round trip on it.

A skill that reaches stage 4 has one more preflight step: the `gh` / `az` tool check at the top of
`pr.md`. Run it here, in this batch, not when you get to stage 4.

### Platform detection

Match the URL of `origin`, i.e. `git remote get-url origin`:

| URL contains | Platform | PR tool |
|---|---|---|
| `github.com` | GitHub | `gh` |
| `dev.azure.com`, `.visualstudio.com`, `ssh.dev.azure.com` | Azure DevOps | `az repos` |
| neither | unknown | see below |

`<remote>` is `origin` when it matched.

Only when `git remote get-url origin` fails or its URL matches nothing is the full remote list worth
printing — that is the one case that needs every remote, so spend `git remote -v` there and nowhere
else.

Unknown or absent `origin`: look through `git remote -v` for a remote whose URL does match. If
exactly one does, set `<remote>` to **that remote's name** and say which one you chose and why —
and remember that `git push`, the `<remote>/HEAD` lookup and the PR's source branch must all use
that name. If several match, ask which to use. If none match, complete every stage except the PR
against `<remote>`, and tell the user the host is unsupported for automated PR creation.

### Base branch

**Never guess this from a hardcoded list.** Real orgs have default branches like `development`,
`developer`, `devoloper`, `DEV`, `Development`, even `v1/development` — a `main`/`master`/`develop`
ladder is wrong more often than it's right, and targeting the wrong base silently opens a PR with
the wrong diff.

Resolve in this order, stopping at the first that answers:

1. **Repo convention — check this first, not last.** If `CLAUDE.md`, `AGENTS.md` or
   `CONTRIBUTING.md` names the branch PRs must target, that is the answer, and the platform default
   does **not** override it. Plenty of repos default to `main` on the server while requiring PRs
   into an integration branch, so a lookup below that "succeeds" would quietly hide the real
   convention. If a convention names a base, stop here.
2. **Local tracking ref** — `git symbolic-ref --quiet refs/remotes/<remote>/HEAD`, then strip
   `refs/remotes/<remote>/`. Set in most clones; use it.
3. **Ask the platform.** Authoritative, and worth the round trip:

```bash
# GitHub
gh repo view --json defaultBranchRef --jq .defaultBranchRef.name

# Azure DevOps — strip the refs/heads/ prefix from the answer. One line: see Command discipline.
az repos show --organization "https://dev.azure.com/<org>" --project "<project>" --repository "<repo>" --query defaultBranch -o tsv
```

   Cache it locally so later runs skip the call: `git remote set-head <remote> <branch>`.
4. Only if all of the above fail: check which of `<remote>/main`, `<remote>/master`,
   `<remote>/development`, `<remote>/develop` exists — and say which one you picked and why.

Call the result `<base>`. Every later stage uses `<base>`, never a literal branch name.

Branch names are case-sensitive and may contain `/`. Quote them, and never "normalise" the casing
of one you were told. If two candidates exist and nothing above disambiguates, ask.

### Hard guardrails

Refuse and explain rather than working around any of these:

- **Nothing to commit** — for a skill that runs stage 2: no staged and no unstaged changes, so stop
  and report a clean tree. A skill that does **not** commit (`push`, `pr`, `push-pr`) treats a clean
  tree as the normal case; its equivalent check is *Nothing to ship*, in stage 4.
- **No `--force`, no `--force-with-lease`, no `--no-verify`, no `git push` to a protected/default
  branch** without the user explicitly asking in this turn.
- **No amend, no rebase, no reset** of existing commits. New commits only.
- **No `git add .` / `git add -A` without inspecting `git status --porcelain` first.** Stage
  named paths. Never stage a path matching: `.env*`, `*.pem`, `*.key`, `*.pfx`, `id_rsa*`,
  `*.p12`, `secrets.*`, `appsettings.*.local.json`, `*.publishsettings`, credential or token
  files, or anything containing an obvious live secret in the diff. Flag such a file and leave
  it unstaged.
- **Merge in progress / rebase in progress / detached HEAD** — stop, report state, let the user
  resolve.
- **Pre-existing staged changes you did not intend to include** — list them and confirm before
  committing.

---

## Stage 5 — Report

One compact block. No prose padding:

```
platform  GitHub | Azure DevOps
branch    feat/add-cache-retry  (from main)
commit    a1b2c3d  feat(cache): add retry on transient Redis failure
push      <remote>/feat/add-cache-retry
pr        https://github.com/owner/repo/pull/42
```

Omit lines for stages your skill doesn't run. If a stage was skipped or failed, say so on that
line with the reason.

Stage 2 split the work into several commits → one `commit` line each, oldest first:

```
branch    fix/tidy-cache-layer  (from main)
commit    a1b2c3d  fix(cache): guard against a null connection
commit    e4f5a6b  refactor(cache): extract the key builder
commit    9c8d7e6  docs(cache): document the retry budget
```
