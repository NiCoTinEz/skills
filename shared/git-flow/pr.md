## Stage 4 — Pull request

### CLI preflight

`gh auth status` rides in stage 0's call and answers both questions at once: a missing `gh` fails
it, and so does an unauthenticated one. Azure DevOps needs its own scoped pair there instead, whose
unscoped forms print 22 and 33 lines against one each:

```bash
az version -o tsv
az extension show --name azure-devops --query name -o tsv
```

**Never install a CLI or an extension yourself.** Stop, give the exact command, wait for the user:
`brew install gh` or `winget install --id GitHub.cli`; `gh auth login`;
`winget install --id Microsoft.AzureCLI`; `az extension add --name azure-devops`; `az login`, or a
PAT with `Code (read & write)` plus `Pull Request contribute` scope in `AZURE_DEVOPS_EXT_PAT`
(`TF400813`, a `401` or a prompt all mean auth). Stages already completed stay completed — say where
the flow stopped and what remains.

### Call one — parity and duplicates

The platform opens the pull request from what the *remote* holds, so a skill that skips stage 3
(`pr`) confirms the branch is there and that HEAD is not ahead of it — and must not push to make it
possible.

```bash
git rev-parse --verify --quiet "<remote>/<branch>"
git rev-list --left-right --count "<remote>/<branch>...HEAD"
git rev-list --count "<remote>/<base>..HEAD"
gh pr list --head "<branch>" --base "<base>" --state open --json url --jq '.[0].url'
```

- An empty first line means no `<remote>/<branch>` ref, so the branch was never pushed: stop, say
  so, offer `push-pr`. The count line then reports `ambiguous argument` — that is the same answer,
  not a second problem. Counts other than `0 0` mean local and remote differ, so the pull request
  would describe a different commit set from the one under review; stop there too, saying whether
  local is ahead, behind or diverged. A skill that just ran stage 3 satisfies both by construction
  and drops those two lines.
- `0` from the third line is **nothing to ship**: no commits separate the branch from the refreshed
  base, and both platforms reject an empty pull request anyway. Stop and report.
- A URL back from `gh pr list` means one already exists — report it and create nothing; no output
  means none does. Azure DevOps replaces that line with, on one line:

```bash
az repos pr list --organization "https://dev.azure.com/<org>" --project "<project>" --repository "<repo>" --source-branch "<branch>" --target-branch "<base>" --status active --query "[].pullRequestId" -o tsv
```

  One ID means it exists — report its URL, composed as below. Several: report them and ask rather
  than choosing silently. Empty: none exists, carry on.
- Title is the commit subject, keeping its `<type>(<scope>):` prefix unless the repo's own pull
  request convention drops it. Several commits get one summarising title.

### Call two — body and create

Nothing above wrote a file, so a stop costs no cleanup. The body is written here, used, and removed
in the one call — including when the create fails:

```bash
cat > "$(git rev-parse --git-dir)/PR_BODY_TMP.md" <<'EOF'
## Summary
- <what changed and why, 1-3 bullets>

## Test plan
- <how it was verified, or "not run: reason">
EOF
gh pr create --base <base> --head <branch> --title "<title>" --body-file "$(git rev-parse --git-dir)/PR_BODY_TMP.md"
rm -f "$(git rev-parse --git-dir)/PR_BODY_TMP.md"
```

Opt-in flags, only when the user asks: `--draft`, `--reviewer <user>`, `--assignee @me`,
`--label <label>`, `--web`.

### Azure DevOps

Parse org, project and repo out of the redacted `<remote>` URL: the three path segments around
`_git` in `https://dev.azure.com/<org>/<project>/_git/<repo>` and in the
`<org>.visualstudio.com/<project>/_git/<repo>` form, or after `v3` in the SSH form
`git@ssh.dev.azure.com:v3/<org>/<project>/<repo>`. Strip a trailing `.git`, URL-decode `%20` in
project names, and if the parse looks wrong confirm with
`az repos list --organization <org> --project <project> --query "[].name" -o tsv`.

```bash
az repos pr create --organization "https://dev.azure.com/<org>" --project "<project>" --repository "<repo>" --source-branch "<branch>" --target-branch "<base>" --title "<title>" --description "## Summary" "- first point" "" "## Test plan" "- how it was checked" --query "{id:pullRequestId,repo:repository.webUrl}" -o tsv
```

- **`--description` takes one argument per line** — not a file, and not one string containing a
  newline escape, which renders literally. Pass an empty string for a blank line; Markdown is
  allowed. That is why Azure DevOps skips the body file.
- The URL to report is the repository web URL, then `pullrequest`, then the pull request ID — the
  two tab-separated values `--query` returns, in that order. That scoped query is deliberate:
  default JSON returns the whole pull request object, 253 lines against 1.
- Opt-in flags, only when the user asks: `--draft true`, `--auto-complete true`, `--squash true`,
  `--delete-source-branch true`, `--reviewers <email…>`, `--work-items <id…>` — the last when the
  user supplies a work-item ID or the branch name carries one.
