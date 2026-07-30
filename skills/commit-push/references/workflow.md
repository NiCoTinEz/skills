<!-- generated from shared/git-flow/workflow.md — edit that file, then run: npm run build -->

# git-flow shared workflow reference

Shared procedure for the `branch-*` / `commit-*` skills in this plugin. Each skill runs a
contiguous subset of the stages below. Run only the stages your skill names, in order, and
stop at the last one.

Stages: **0 preflight → 1 branch → 2 commit → 3 push → 4 pull request → 5 report**

---

## Stage 0 — Preflight (always)

Run these first, in one batch:

```bash
git rev-parse --show-toplevel
git status --porcelain=v1 --branch
git remote -v
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

Everything below writes `<remote>` where a remote name is needed. **It is usually `origin`, but
resolve it once here and then substitute the name you resolved into every later command** — base
resolution, branch creation, push and PR all have to agree on one remote. Never hardcode `origin`
after this point.

### Platform detection

Match the URL of `origin`, i.e. `git remote get-url origin`:

| URL contains | Platform | PR tool |
|---|---|---|
| `github.com` | GitHub | `gh` |
| `dev.azure.com`, `.visualstudio.com`, `ssh.dev.azure.com` | Azure DevOps | `az repos` |
| neither | unknown | see below |

`<remote>` is `origin` when it matched.

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

# Azure DevOps — strip the refs/heads/ prefix from the answer
az repos show --organization "https://dev.azure.com/<org>" --project "<project>" \
  --repository "<repo>" --query defaultBranch -o tsv
```

   Cache it locally so later runs skip the call: `git remote set-head <remote> <branch>`.
4. Only if all of the above fail: check which of `<remote>/main`, `<remote>/master`,
   `<remote>/development`, `<remote>/develop` exists — and say which one you picked and why.

Call the result `<base>`. Every later stage uses `<base>`, never a literal branch name.

Branch names are case-sensitive and may contain `/`. Quote them, and never "normalise" the casing
of one you were told. If two candidates exist and nothing above disambiguates, ask.

### Hard guardrails

Refuse and explain rather than working around any of these:

- **Nothing to commit** — no staged and no unstaged changes: stop, report clean tree.
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

### Tool preflight (only when the skill reaches stage 4)

**GitHub:**

```bash
gh --version
gh auth status
```

Missing `gh` → stop and ask the user to run one of:

```powershell
winget install --id GitHub.cli
```

```bash
# macOS / Linux
brew install gh
```

Not authenticated → ask the user to run `gh auth login`.

**Azure DevOps:**

```bash
az --version
az extension show --name azure-devops
```

Missing `az` → stop and ask the user to run:

```powershell
winget install --id Microsoft.AzureCLI
```

Extension not installed (`az extension show` errors) → stop and ask the user to run:

```bash
az extension add --name azure-devops
```

Not authenticated (`az repos` returns `TF400813`, `401`, or prompts) → ask the user to run
`az login`, or to set a PAT with `Code (read & write)` + `Pull Request contribute` scope:

```powershell
$env:AZURE_DEVOPS_EXT_PAT = "<pat>"
```

**Never install a CLI or extension yourself — always ask and give the exact command.** Wait for
the user to run it, then re-check. Stages already completed stay completed; tell the user exactly
where the flow stopped and what remains.

---

## Stage 1 — Branch

Only for skills whose name starts with `branch-`.

Name format: **`<type>/<short-slug>`**

- `<type>` ∈ `feat` `fix` `chore` `refactor` `perf` `docs` `test` `build` `ci` `style` `revert`
  — same vocabulary as the commit type, and it must match the commit's type.
- `<slug>` lowercase kebab-case, derived from what the change actually does, 2–4 words,
  ≤ 40 chars total. No ticket numbers unless the user gives one, no dates, no author name.
- Examples: `feat/add-cache-retry`, `fix/null-ref-login`, `chore/bump-serilog`.

Procedure:

1. Read the diff (`git diff`, plus `git diff --staged` if anything is staged) to pick type + slug.
2. If the branch already exists locally or on `<remote>`, append `-2`, `-3`, … or pick a better slug.
3. Create from an up-to-date base:

```bash
git fetch <remote> --quiet
git switch --create <type>/<slug> <remote>/<base>
```

   **Exception — uncommitted work must come along.** If the tree is dirty, do *not* rebase onto
   `<remote>/<base>`; branch off the current HEAD so the working tree is preserved:

```bash
git switch --create <type>/<slug>
```

   Say which of the two you used and why.
4. If the user already sits on a non-default feature branch with the pending work, do **not**
   create a second branch — reuse it and say so.

## Stage 2 — Commit

1. Stage deliberately. Everything relevant to this one logical change, nothing else:

```bash
git add -- <path> <path>
git diff --staged --stat
```

2. Write the message — **Conventional Commits**:

```
<type>(<scope>): <imperative summary>

- <why, or non-obvious detail>
- <second point>
```

   - `<scope>` optional; use the project/module name when the repo already does.
   - Imperative mood: `add`, `fix`, `remove` — not `added`/`adds`.
   - Subject ≤ 50 chars preferred, hard cap 72. No trailing period.
   - Body only when the *why* isn't obvious from the diff, or for breaking changes and
     migration notes. Wrap at 72. Bullets with `-`.
   - Breaking change: `feat(api)!: …` plus a `BREAKING CHANGE: …` footer.
   - **No AI attribution and no `Co-Authored-By` trailer.**
   - Do not restate filenames the scope already covers. No "this commit", no "I"/"we".
   - Match the repo's existing style if `git log` shows a different convention — follow the repo,
     mention the deviation.

3. Commit. **Write the message to a file and pass `-F`** — a multi-line message inlined with `-m`
   gets mangled differently by every shell, and a Bash heredoc is a syntax error in PowerShell,
   which is the shell some agents are configured with. Use the form that matches the shell you are
   actually running in, then delete the file:

   *Bash / zsh:*

```bash
cat > "$(git rev-parse --git-dir)/COMMIT_MSG_TMP" <<'EOF'
feat(cache): add retry on transient Redis failure

- wrap GetAsync in Polly retry, 3 attempts, exponential backoff
- transient socket errors were surfacing as 500s
EOF
git commit -F "$(git rev-parse --git-dir)/COMMIT_MSG_TMP"
rm -f "$(git rev-parse --git-dir)/COMMIT_MSG_TMP"
```

   *PowerShell:* a single-quoted here-string, whose closing `'@` must sit at column 0:

```powershell
$msg = @'
feat(cache): add retry on transient Redis failure

- wrap GetAsync in Polly retry, 3 attempts, exponential backoff
- transient socket errors were surfacing as 500s
'@
$f = Join-Path (git rev-parse --git-dir) COMMIT_MSG_TMP
Set-Content -Path $f -Value $msg -Encoding utf8
git commit -F $f
Remove-Item $f
```

   The file goes inside `.git/`, so it can never be picked up as a repo change.

4. If a hook rejects the commit, fix the underlying problem or report it. Never `--no-verify`.
5. Multiple unrelated logical changes in the tree → prefer several commits, or ask.

## Stage 3 — Push

```bash
git push --set-upstream <remote> HEAD
```

- Already has upstream → plain `git push`.
- **Rejected as non-fast-forward:** stop. Report it and offer `git pull --rebase <remote> <branch>`
  as a *suggestion*. Do not force-push, do not rebase without approval.
- Currently on the default/protected branch (only possible for the `commit-*` skills): warn
  clearly that this pushes straight to `<base>` and get explicit confirmation before pushing.

## Stage 4 — Pull request

Skip if a PR for this branch already exists — fetch and report its URL instead of creating a
duplicate (`gh pr view --json url,state`; `az repos pr list --source-branch <branch>`).

Title = the commit subject (drop the `<type>(<scope>):` prefix only if the platform convention
in the repo does). Multiple commits → one summarising title.

Body:

```markdown
## Summary
- <what changed and why, 1-3 bullets>

## Test plan
- <how it was verified, or "not run: <reason>">
```

For GitHub, write the body to a temp file and pass `--body-file` rather than inlining a multi-line
string. Azure DevOps takes it as one argument per line instead — see below.

### GitHub

```bash
gh pr create --base <base> --head <branch> --title "<title>" --body-file <bodyfile>
```

Opt-in flags, only when the user asks: `--draft`, `--reviewer <user>`, `--assignee @me`,
`--label <label>`, `--web`.

### Azure DevOps

Parse the org / project / repo out of the `<remote>` URL:

| URL shape | org | project | repo |
|---|---|---|---|
| `https://<user>@dev.azure.com/<org>/<project>/_git/<repo>` | `<org>` | `<project>` | `<repo>` |
| `https://dev.azure.com/<org>/<project>/_git/<repo>` | `<org>` | `<project>` | `<repo>` |
| `https://<org>.visualstudio.com/<project>/_git/<repo>` | `<org>` | `<project>` | `<repo>` |
| `git@ssh.dev.azure.com:v3/<org>/<project>/<repo>` | `<org>` | `<project>` | `<repo>` |

Strip a trailing `.git`. URL-decode `%20` in project names. Note that a project may itself
contain `/` segments only in the `DefaultCollection` legacy form — if the parse looks wrong,
confirm with `az repos list --organization <org> --project <project> --query "[].name"`.

```bash
az repos pr create \
  --organization "https://dev.azure.com/<org>" \
  --project "<project>" \
  --repository "<repo>" \
  --source-branch "<branch>" \
  --target-branch "<base>" \
  --title "<title>" \
  --description "## Summary" "- first point" "" "## Test plan" "- how it was checked" \
  --output json
```

- **`--description` takes one argument per line**, not a file and not one string with `\n` in it —
  `az repos pr create --help` states "Each value sent to this arg will be a new line". Pass an empty
  string `""` where you want a blank line. Markdown is allowed. A single `--description "a\nb"`
  renders the literal `\n`, so don't.
- The URL to report is `repository.webUrl` + `/pullrequest/` + `pullRequestId`, i.e.
  `https://dev.azure.com/<org>/<project>/_git/<repo>/pullrequest/<id>`.
- Opt-in flags, only when the user asks: `--draft true`, `--auto-complete true`,
  `--squash true`, `--delete-source-branch true`, `--reviewers <email…>`,
  `--work-items <id…>` (pass when the user supplies a work-item ID or the branch name carries one).

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
