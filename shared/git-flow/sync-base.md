## Stage 0 addition — what a prune would remove

Two extra lines, in the **same call** as stage 0, after its fetch:

```bash
git for-each-ref --format='%(refname:short)' --exclude 'refs/remotes/<remote>/HEAD' 'refs/remotes/<remote>/**'
git ls-remote --heads --refs "<remote>"
```

The first lists the remote-tracking refs this clone holds, the second the branches the remote
actually has. **A name in the first that is missing from the second is what a prune would delete** —
usually the branch of a merged pull request the platform already deleted upstream. Nothing missing
means nothing is stale.

Two lines rather than the one obvious one, for two reasons. `git fetch --prune --dry-run` and
`git remote prune --dry-run` both print the remote URL — the second labels it `URL:` — and either can
carry a password or PAT. And `--dry-run --porcelain`, which does print a clean list and nothing else,
is a *fetch*: wrappers that condense fetch output swallow the list and leave you concluding nothing
is stale when refs are. The pair above prints only ref names, and nothing condenses it. Don't pipe
either through `sed` or `awk` to tidy the output — see *Command discipline*; the extra column is
cheaper than a line that only runs in one shell. If the git in use rejects `--exclude`, drop that
flag and ignore the bare `<remote>` entry it then prints, which is `HEAD`.

**Keep both quotes exactly as written.** Unquoted, `%(refname:short)` and `refs/remotes/<remote>/**`
are glob patterns to zsh, which fails the whole line with `no matches found` before git ever runs,
and `(…)` is a subexpression to PowerShell. This is the one line in the set where dropping a quote
breaks it in the *user's* shell rather than the other one.

## Stage 0 addition — this folder may not be the repo

One more line in the **same call** as stage 0. In a normal repo you ignore it, and it costs nothing
because the depth limit stops the walk. When stage 0's line 1 came back `not a git repository`, it is
the whole answer:

```bash
find . -mindepth 2 -maxdepth 2 -name .git
```

PowerShell:

```powershell
Get-ChildItem -Directory | Where-Object { Test-Path (Join-Path $_.FullName .git) } | Select-Object -ExpandProperty Name
```

Each hit is a repo sitting directly inside this folder. `-mindepth 2` is what keeps it quiet in a
normal repo: without it the line matches the repo's own `.git` and reads as though it had found a
child. See *Not a git repository* below.

## Not a git repository — a folder of repos

Stage 0 failed on every git line and the detection line listed `.git` entries: this is a folder *of*
repos, so there is no single base to land on. **Ask what to do, and touch nothing until the answer
arrives:**

- **Sync all** — say how many, because "all" means that many fetches. Past roughly twenty, say so
  plainly and offer narrowing instead; still do it if the user says all anyway.
- **Select some** — list the repo names in the order detection printed them, and take the ones named.
- **Nothing** — stop, saying the folder itself is not a repo, so no base was touched.

Detection came back empty → the folder holds no repos at all. Report that and stop; there is nothing
to ask. Empty at this depth but the folder plainly holds project groups (a `Code/` of `Library/` and
`Product/`) → one call for the deeper sweep before asking, because those repos sit a level further
down:

```bash
find . -mindepth 3 -maxdepth 3 -name .git
```

### The fan-out — three calls, whatever the count

Three after stage 0, so four in total, and four whether the answer was one repo or thirty. The shape
is the one stage 0 already set: probe, land, pull. Every line carries
`git -C <dir>` so nothing depends on the working directory, and the prune question is asked **once**
for the whole run.

Probe every selected repo, two lines each:

```bash
git -C <dir> status --porcelain=v1 --branch
git -C <dir> symbolic-ref --quiet refs/remotes/origin/HEAD
```

Each repo brings its own `<base>` and its own dirty state — they are separate repos and share
neither. **A dirty repo is dropped from the run**, named in the report, and never switched.

Land the clean ones, one line each. Drop `--prune` where pruning was declined:

```bash
git -C <dir> fetch origin --prune --quiet
git -C <dir> switch <base>
```

Then pull only the repos that reported landing on their base:

```bash
git -C <dir> pull --ff-only origin <base>
```

**Why the pull still waits for its own call**, and why it matters more here than with one repo: a
switch that fails leaves that repo on the branch it was already on, and a pull batched behind it
fast-forwards *that* branch instead. With many repos in one call you cannot tell which failed until
every line has already run, so one repo's failed switch would quietly move one repo's wrong branch.

## Always ask before pruning

**This skill never prunes on its own and never skips the question** — a deliberate exception to
*Act, don't ask* above, because pruning deletes refs. Ask every run, even when the preview came back
empty, and put in the question:

- what would go — the refs the preview named, or that nothing is stale;
- what it touches — **remote-tracking** refs only, for branches already gone from `<remote>`. It
  never deletes a local branch and never changes anything on the remote;
- that declining still syncs the base; prune is the only thing being decided.

Until the answer arrives, neither block below has run.

## Procedure — two calls

Land on the base first. Pruning approved:

```bash
git fetch <remote> --prune --quiet
git switch <base>
git rev-parse --short HEAD
```

Pruning declined — stage 0 already fetched, so there is nothing to fetch again:

```bash
git switch <base>
git rev-parse --short HEAD
```

Then, once that reports you are actually on `<base>`:

```bash
git pull --ff-only <remote> <base>
git log --oneline -1
```

**Why two, when one call is the rule everywhere else.** `git switch <base>` can fail — a base that
doesn't exist locally and is ambiguous across remotes, or a convention line naming a branch this
repo doesn't have. Batched, the pull would then run on the branch you are still standing on and
fast-forward *that* to the base; a just-merged feature branch is strictly behind its base, so it
would move without complaint. The two `HEAD` readings also give the report its range for free.

- **A dirty tree stops this skill before it touches anything**, so preflight decides whether the
  first block runs at all — it already listed the porcelain status, and a guard *inside* the block
  would be useless, since every line runs before you see any of the output. `git switch` carries
  uncommitted changes onto the target branch without a word. Anything modified, staged or untracked:
  name the paths and stop without running it.

```
dirty     src/Cache.cs, README.md
          switching would carry these onto 'development'
```

  Offer `commit` or `branch-commit` first. Stash only if the user asks in that turn, and then say
  where the stash landed: a `git stash pop` after the switch drops the changes on `<base>`, not on
  the branch they came from.
- **Already on `<base>`** — skip the switch, say so, still pull.
- **No local `<base>` branch yet** — `git switch <base>` creates a tracking branch by itself; if
  that fails, `git switch --track <remote>/<base>`.
- **`--ff-only` is deliberate.** Refused means the local base holds commits the remote does not:
  stop and report, never rebase, reset, force or merge past it.
- Detached HEAD, merge in progress and rebase in progress are stage 0 guardrails: stop and report.

## Stage 5 — Report

Name the branch it came from and the range pulled. One compact block, no prose padding:

```
branch    development  (was feat/add-cache-retry)
prune     <remote>  2 stale refs removed  feat/add-cache-retry, fix/null-ref-login
pull      <remote>/development  4 new commits  a1b2c3d..e4f5a6b
```

The `prune` line always appears: `declined`, `nothing stale`, or the refs that went.

A folder of repos reports a header and one line per repo, dirty ones included so the skips are
visible:

```
folder    Library  18 repos  15 synced, 2 dirty, 1 failed
prune     declined
repo      Net_Framework.Result  main  4 new commits  a1b2c3d..e4f5a6b
repo      Net_Framework.Cache   main  already up to date
dirty     Net_Model.Table       src/Table.cs — not switched, not pulled
failed    Net_Repository.Sql    switch refused: local base holds commits the remote does not
```

Already current → `pull      already up to date`. Already on `<base>` → say so on the `branch` line
instead of naming a previous branch. **Deleting the branch you left is not this skill's job**, even
when its pull request has merged.
