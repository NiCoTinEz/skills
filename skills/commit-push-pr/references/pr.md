<!-- generated from shared/git-flow/pr.md — edit that file, then run: npm run build -->

# git-flow stage 4 — Pull request

Read alongside `core.md`, which holds preflight, `<remote>` / `<base>` resolution, the guardrails
and the report format.

## Tool preflight

**This belongs in stage 0's batch, not here** — run it before any stage does work, so a missing CLI
stops the flow before it has half-finished.

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
az version -o tsv
az extension show --name azure-devops --query name -o tsv
```

Both are scoped on purpose: `az --version` prints 22 lines and `az extension show` 33, against one
short line each here. Do not "fix" the first into `az version --query '"azure-cli"' -o tsv` — that
works in Bash and fails in PowerShell, which strips the inner quotes. See *Command discipline* in
`core.md`.

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

## The pull request

**Nothing to ship** — `git rev-list --count <base>..HEAD` returns `0`: no commits separate the
branch from `<base>`, so there is no diff to open a PR for. Stop and report; both platforms reject
an empty PR anyway.

**A skill that skips stage 3 (`pr`) must not push to make the PR possible.** The platform opens the
PR from what the *remote* holds, so confirm first that the branch is there and that local HEAD is
not ahead of it:

```bash
git fetch <remote> --quiet
git rev-parse --verify --quiet <remote>/<branch>
git rev-list --count <remote>/<branch>..HEAD
```

A missing ref means the branch was never pushed; a count above `0` means the PR would open without
the commits the user is looking at. Either way stop, say which of the two it is, and offer
`push-pr`. Pushing to fix it is stage 3 — not this skill's to run.

Skip if a PR for this branch already exists — fetch and report its URL instead of creating a
duplicate:

```bash
# GitHub — defaults to the current branch
gh pr view --json url,state
```

```bash
# Azure DevOps — org / project / repo parsed as the Azure DevOps section below describes.
# `az repos pr list` needs them explicitly unless `az devops configure --defaults` is set,
# so pass the same three values the create call uses. One line: see Command discipline in core.md.
az repos pr list --organization "https://dev.azure.com/<org>" --project "<project>" --repository "<repo>" --source-branch "<branch>" --status active --query "[].pullRequestId" -o tsv
```

An ID comes back → a PR already exists; report its URL, composed as the Azure DevOps section below
describes. Empty output → none exists, carry on. The unscoped `--output json` returns the whole
PullRequest object for every match, none of which this check reads.

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
confirm with `az repos list --organization <org> --project <project> --query "[].name" -o tsv`.

One line, and scoped to the two fields the URL is built from — see *Command discipline* in
`core.md`. `--output json` returns the entire PullRequest object — repository, project, creator,
reviewers and ref graph, none of which is read — measured at 253 lines against 1 for the query
below, on a real pull request.

```bash
az repos pr create --organization "https://dev.azure.com/<org>" --project "<project>" --repository "<repo>" --source-branch "<branch>" --target-branch "<base>" --title "<title>" --description "## Summary" "- first point" "" "## Test plan" "- how it was checked" --query "{id:pullRequestId,repo:repository.webUrl}" -o tsv
```

- **`--description` takes one argument per line**, not a file and not one string with `\n` in it —
  `az repos pr create --help` states "Each value sent to this arg will be a new line". Pass an empty
  string `""` where you want a blank line. Markdown is allowed. A single `--description "a\nb"`
  renders the literal `\n`, so don't.
- The URL to report is `repository.webUrl` + `/pullrequest/` + `pullRequestId` — the two tab-separated
  values the `--query` above returns, in that order — i.e.
  `https://dev.azure.com/<org>/<project>/_git/<repo>/pullrequest/<id>`.
- Opt-in flags, only when the user asks: `--draft true`, `--auto-complete true`,
  `--squash true`, `--delete-source-branch true`, `--reviewers <email…>`,
  `--work-items <id…>` (pass when the user supplies a work-item ID or the branch name carries one).
