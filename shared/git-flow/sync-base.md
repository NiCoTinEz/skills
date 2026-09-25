## Stage 0 addition — what a prune would remove

Two extra lines in stage 0's **same call**, after its non-pruning fetch, using the resolved remote:

```bash
git for-each-ref --format='%(refname)' 'refs/remotes/<remote>/'
git ls-remote --heads --refs "<remote>"
```

A convention-named `<base>` absent from the `ls-remote` output is not on `<remote>` — a leftover
tracking ref doesn't count: drop to the next rung of the base ladder before switching.

Compare **bare branch names**, preserving case and slashes: from the first output, discard
`refs/remotes/<remote>/HEAD` and strip the exact `refs/remotes/<remote>/` prefix. From the second,
ignore the object-ID column and strip `refs/heads/` from the ref column. Only names present locally
but absent remotely are stale. Both commands must succeed; failed or unavailable output is **not**
an empty remote or proof that nothing is stale. Resolve failures before asking or mutating refs.

Avoid `fetch --prune --dry-run` and `remote prune --dry-run`: their output can expose credentialed
URLs. Fetch wrappers can also swallow a `--dry-run --porcelain` preview. These two read commands
return full ref names and, for `ls-remote`, object IDs. Interpret the columns without shell-specific
`sed` / `awk` pipelines. Full ref names also avoid ambiguous shortened names and `--exclude` support.

Keep `'%(refname)'` quoted so the shell passes Git's format literally. Replace `<remote>` before
running the command and keep the ref prefix quoted as one argument.

## Stage 0 addition — changes that are only line endings

Two more lines in the **same call**. A base branch whose committed blobs disagree with its own
`.gitattributes` shows files modified forever, and no checkout clears them:

```bash
git diff --ignore-cr-at-eol --name-only
git diff --cached --ignore-cr-at-eol --name-only
```

A modified path that porcelain lists but neither line does is **eol-only**: it does not make the
repo dirty. Report it as `eol-only <paths>` and continue; if the switch or pull then refuses over
it, report that failure as it stands. Untracked files still count as dirty.

## Stage 0 addition — this folder may not be the repo

One more line in the **same call** as stage 0. In a normal repo you ignore it, and it costs nothing
because the depth limit stops the walk. When stage 0's line 1 came back `not a git repository`, it is
the whole answer:

```bash
find . -mindepth 2 -maxdepth 2 -name .git
```

PowerShell — a bare `find` there is Windows' text search, not this:

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

- **Sync all** — say how many, because "all" means up to twice that many fetches: one probe each, plus
  one more each if pruning is approved. Past roughly twenty, say so plainly and offer narrowing
  instead; still do it if the user says all anyway.
- **Select some** — list the repo names in the order detection printed them, and take the ones named.
- **Nothing** — stop, saying the folder itself is not a repo, so no base was touched.

Detection came back empty → the folder holds no repos at all. Report that and stop; there is nothing
to ask. Empty at this depth but the folder plainly holds project groups (a `workspace/` of `apps/` and
`packages/`) → one call for the deeper sweep before asking, because those repos sit a level further
down:

```bash
find . -mindepth 3 -maxdepth 3 -name .git
```

```powershell
Get-ChildItem -Directory | Get-ChildItem -Directory | Where-Object { Test-Path (Join-Path $_.FullName .git) } | ForEach-Object { Join-Path $_.Parent.Name $_.Name }
```

### The fan-out — batch each phase across the selected repos

Normally three calls after detection: probe, land, pull, regardless of repo count. Batch any shared
remote/base fallback probes across all unresolved repos before landing; the four-call budget is
not a reason to guess. Ask the prune question **once**, after all eligible repos have a preview.

Probe every selected repo with **the full stage 0**, including its remote half, the two preview
lines and the two eol lines above. Prefix every Git command with `git -C "<dir>"`; convention files are read from each
repo's own root, so `repo_root` comes from `git -C "<dir>" rev-parse --show-toplevel` before the
grep or PowerShell `Select-String` runs. Do not repeat folder detection or CLI checks.
Use a supplied remote, otherwise initially probe `origin`, then apply the shared remote resolver.
The additional preview lines for each resolved repo are:

```bash
git -C "<dir>" for-each-ref --format='%(refname)' 'refs/remotes/<remote>/'
git -C "<dir>" ls-remote --heads --refs "<remote>"
```

Resolve each repo's `<remote>` with the shared resolver. For `<base>`, use explicit user values,
then repo convention, remote HEAD, platform API, ranked candidates. Scope API queries
to that repo's resolved remote. Missing remote HEAD does not skip the other rungs. If the initial
remote probe failed, batch its redacted URL, HEAD, non-pruning fetch and preview with the corrected
remote before proceeding; never reuse another repo's preview.
After fallbacks, drop dirty repos and any repo with a guardrail, unresolved base/remote, or a fetch
or preview still failing. Report each skip; never switch or pull it. If none remain, stop without asking.

Land eligible repos using the single-repo landing block below, with `git -C "<dir>"` on each line
and that repo's resolved values. The probe already fetched; declining pruning needs no second fetch.
Then pull only repos whose landing commands succeeded and whose current branch is their base:

```bash
git -C "<dir>" pull --ff-only --no-prune "<remote>" "<base>"
git -C "<dir>" log --oneline -1
git -C "<dir>" rev-list --left-right --count "<remote>/<base>...HEAD"
git -C "<dir>" branch --merged "<base>"
```

Never batch pull behind an unchecked switch: a failed switch would leave pull targeting the old
branch. A failed pull is reported as failed; do not describe its merged-branch list as refreshed.

## Eligibility — before the prune question

Apply preflight's dirty-tree and other guardrails **before asking about pruning**. Anything
modified, staged or untracked — eol-only paths excepted — makes that repo ineligible: name the paths and skip pruning,
switching and pulling. In a single repo, stop; in folder mode, continue only with eligible repos.
If none remain, stop without the prune question, reporting the `prune` line as `skipped: <reason>`
(Stage 5 gives its exact shape).

```
dirty     src/example.cs, README.md
prune     <remote>  skipped: dirty tree
```

Offer `commit` or `branch-commit` for dirty work. Stash only if the user asks in that turn; explain
that popping after the switch applies the changes to the base branch, not the branch they came from.

## Ask once for eligible repos before pruning

**Never prune without approval.** Once at least one repo is eligible and its preview succeeded,
ask once for that eligible set, even when nothing is stale. This is the exception to *Act, don't
ask*. Repos dropped during preflight are excluded. Put in the question:

- what would go — the preview's refs grouped by repo and remote, or that nothing is stale;
- what it touches — **remote-tracking** refs only, for branches already gone from `<remote>`. It
  never deletes a local branch and never changes anything on the remote;
- that declining still syncs the base; prune is the only thing being decided.

Until the answer arrives, neither block below has run.

## Procedure — two calls

Land on the base first. Pruning approved:

```bash
git fetch --prune --no-prune-tags --refmap= --quiet "<remote>" '+refs/heads/*:refs/remotes/<remote>/*'
git for-each-ref --format='%(refname)' 'refs/remotes/<remote>/'
git switch "<base>"
git symbolic-ref --quiet --short HEAD
git rev-parse --short HEAD
```

The explicit branch refspec and empty refmap restrict pruning to this remote's tracking branches;
`--no-prune-tags` overrides tag-pruning configuration. Compare before/after refs to report actual
removals. This fetch refreshes after approval; `git remote prune` would still contact the remote
and can print its credentialed URL, so it is not a network-free replacement.

Pruning declined — stage 0 already fetched:

```bash
git switch "<base>"
git symbolic-ref --quiet --short HEAD
git rev-parse --short HEAD
```

Continue only if landing succeeded and the reported branch is `<base>`. Then:

```bash
git pull --ff-only --no-prune "<remote>" "<base>"
git log --oneline -1
git rev-list --left-right --count "<remote>/<base>...HEAD"
git branch --merged "<base>"
```

**List merged branches only after a successful pull**, in both flows. If pull fails, ignore the
listing and report failure. `--no-prune` also prevents pull's internal fetch from deleting refs,
even when pruning was declined or Git configuration enables it.

**Why two, when one call is the rule everywhere else.** `git switch <base>` can fail — a base that
doesn't exist locally and is ambiguous across remotes, or a convention line naming a branch this
repo doesn't have. Batched, the pull would then run on the branch you are still standing on and
fast-forward *that* to the base; a just-merged feature branch is strictly behind its base, so it
would move without complaint. The two `HEAD` readings also give the report its range for free.

- **Already on `<base>`** — skip the switch, say so, still pull.
- **No local `<base>` branch yet** — `git switch <base>` creates a tracking branch by itself; if
  that fails, `git switch --track <remote>/<base>`.
- **`--ff-only` is deliberate.** A non-fast-forward refusal means the local and remote histories
  have diverged: stop, never rebase, reset, force or merge past it. A local-only lead succeeds and
  stays intact; the `rev-list` count names the local commits still ahead, without claiming
  local/remote parity. For other pull failures, report the actual error instead of diagnosing
  divergence.
- Detached HEAD, merge in progress and rebase in progress are stage 0 guardrails: stop and report.

## Merged local branches — report, never delete

The listing above names local branches already merged into `<base>`, the branch just left usually
among them. **This skill does not delete them and does not ask to.** It already spends the run's one
delete question on the prune, and that question's answer was given on the promise that no local
branch goes with it; a second delete in the same run turns both into a reflex yes. Report them and
hand over the command instead:

- `git branch -d` and never `-D` — `-d` refuses a branch that is not actually merged, so the command
  handed over carries its own guard even if the listing is stale by the time it runs.
- Squash-merged pull requests leave the branch a non-ancestor of `<base>`, so `--merged` never lists
  them. The line under-reports rather than over-reports; treat it as a hint, not an inventory, and
  never present it as the full set of finished branches.
- `<base>` itself always lists as merged into itself. Drop it, and drop the `*` the current branch
  carries, before reporting a count.
- Nothing merged, or nothing beyond `<base>`, means no line at all — an empty `stale` line is noise.

## Stage 5 — Report

Name the branch it came from and the range pulled. One compact block, no prose padding:

```
branch    development  (was feat/add-cache-retry)
prune     <remote>  2 stale refs removed  feat/add-cache-retry, fix/null-ref-login
pull      <remote>/development  4 new commits  a1b2c3d..e4f5a6b
stale     2 local branches merged into development
          feat/add-cache-retry, fix/null-ref-login
          delete: git branch -d feat/add-cache-retry fix/null-ref-login
```

The `prune` line always appears. A single repo shows `prune <remote> <result>`; folder mode shows one
global `prune <result>` unless removals differ per remote, then group them. `<result>` is
`skipped: <reason>` if eligibility prevented the question, `declined` if refused, `nothing stale`,
`N stale refs removed  <names>`, or `failed: <error>` — never imply an approval or an attempted fetch
succeeded. The `stale` line appears only when merged local branches remain after a successful pull.

A folder of repos reports a header and one line per repo, dirty ones included so the skips are
visible:

```
folder    projects  4 repos  2 synced, 1 dirty, 1 failed
prune     declined
repo      repo-a  main  4 new commits  a1b2c3d..e4f5a6b
repo      repo-b  main  already up to date
dirty     repo-c  README.md — not switched, not pulled
failed    repo-d  pull refused: local and remote base have diverged
stale     repo-a 3, repo-b 1
```

**A folder run reports stale branches as counts only** — no names, no delete command. Fifteen repos'
worth of branch names is a wall nobody audits, and one `git branch -d` line per repo is not a thing
to paste. Name them by running the skill in the one repo that matters.

Already current → `pull      already up to date`. Already on `<base>` → say so on the `branch` line
instead of naming a previous branch. **Deleting the branch you left is still not this skill's job**,
even when its pull request has merged and the `stale` line names it — that line is a report and a
command to copy, not an offer to run it.
