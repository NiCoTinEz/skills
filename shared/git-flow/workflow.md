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
| platform | see *Platform detection* |
| base branch | see *Base branch* |

### Platform detection

Match the `origin` URL:

| Origin contains | Platform | PR tool |
|---|---|---|
| `github.com` | GitHub | `gh` |
| `dev.azure.com`, `.visualstudio.com`, `ssh.dev.azure.com` | Azure DevOps | `az repos` |
| neither | unknown | see below |

Unknown host: check other remotes (`git remote -v`). If a GitHub/ADO remote exists under a
different name, use it and say which. Otherwise complete every stage except the PR, and tell
the user the host is unsupported for automated PR creation.

### Base branch

In order, first that resolves:

1. `git symbolic-ref --quiet refs/remotes/origin/HEAD` → strip `refs/remotes/origin/`
2. `git rev-parse --verify --quiet origin/main` → `main`
3. `git rev-parse --verify --quiet origin/master` → `master`
4. `git rev-parse --verify --quiet origin/develop` → `develop`

If a repo convention says PRs target `develop` (see `CLAUDE.md`, `CONTRIBUTING.md`), prefer it.
If still ambiguous, ask.

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

### Tool preflight (only when the skill reaches stage 3 or 4)

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
2. If the branch already exists locally or on `origin`, append `-2`, `-3`, … or pick a better slug.
3. Create from an up-to-date base:

```bash
git fetch origin --quiet
git switch --create <type>/<slug> origin/<base>
```

   **Exception — uncommitted work must come along.** If the tree is dirty, do *not* rebase onto
   `origin/<base>`; branch off the current HEAD so the working tree is preserved:

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

3. Commit via a heredoc so multi-line messages survive PowerShell quoting:

```bash
git commit -F - <<'EOF'
feat(cache): add retry on transient Redis failure

- wrap GetAsync in Polly retry, 3 attempts, exponential backoff
- transient socket errors were surfacing as 500s
EOF
```

4. If a hook rejects the commit, fix the underlying problem or report it. Never `--no-verify`.
5. Multiple unrelated logical changes in the tree → prefer several commits, or ask.

## Stage 3 — Push

```bash
git push --set-upstream origin HEAD
```

- Already has upstream → plain `git push`.
- **Rejected as non-fast-forward:** stop. Report it and offer `git pull --rebase origin <branch>`
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

Write the body to a temp file rather than inlining a multi-line string.

### GitHub

```bash
gh pr create --base <base> --head <branch> --title "<title>" --body-file <bodyfile>
```

Opt-in flags, only when the user asks: `--draft`, `--reviewer <user>`, `--assignee @me`,
`--label <label>`, `--web`.

### Azure DevOps

Parse the org / project / repo out of the origin URL:

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
  --description @<bodyfile> \
  --output json
```

- `--description @<file>` reads the file; if the installed extension version rejects `@file`,
  fall back to passing the body as repeated `--description "line" "line"` values.
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
push      origin/feat/add-cache-retry
pr        https://github.com/owner/repo/pull/42
```

Omit lines for stages your skill doesn't run. If a stage was skipped or failed, say so on that
line with the reason.
