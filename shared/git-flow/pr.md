## Stage 4 — Pull request

### Call one — parity and duplicates

A skill skipping stage 3 (`pr`) verifies source parity; it must never push to establish parity.

```bash
git rev-parse --verify --quiet "<remote>/<branch>"
git rev-list --left-right --count "<remote>/<branch>...HEAD"
git rev-list --count "<remote>/<base>..HEAD"
gh pr list --head "<branch>" --base "<base>" --state open --json url --jq '.[0].url // empty'
```

- Missing tracking ref or counts other than `0 0`: stop and report missing, ahead, behind or
  diverged. Offer `push-pr` for a missing branch or unpushed commits. A skill that runs stage 3
  already ran this call before pushing, minus those two lines. A failed push never advances further.
- `0` from the third line means **nothing to ship**: stop and report.
- An existing PR URL means report it and create nothing. Only successful empty output means none —
  `// empty` is what keeps a no-match from printing `null`. API errors stop. Azure DevOps replaces
  the list command with:

```bash
az repos pr list --organization "https://dev.azure.com/<org>" --project "<project>" --repository "<repo>" --source-branch "<branch>" --target-branch "<base>" --status active --query "[].pullRequestId" -o tsv
```

  One ID: report its URL; several: report and ask; successful empty output: continue.
- Title: commit subject (or summary of several), retaining its prefix unless repo convention differs.

### Call two — body and create

Write, use and remove the body in one call, including after failure. Check creation's result,
not cleanup's exit status, before reporting success. Bash:

```bash
cat > "$(git rev-parse --git-dir)/PR_BODY_TMP.md" <<'EOF'
## Summary
- <what changed and why, 1-3 bullets>

## Test plan
- <how it was verified, or "not run: reason">
EOF
gh pr create --base "<base>" --head "<branch>" --title "<title>" --body-file "$(git rev-parse --git-dir)/PR_BODY_TMP.md"
rm -f "$(git rev-parse --git-dir)/PR_BODY_TMP.md"
```

PowerShell — the closing `'@` starts at column 0:

```powershell
$prBody = @'
## Summary
- <what changed and why>

## Test plan
- <how verified, or not run: reason>
'@
$prBodyFile = Join-Path (git rev-parse --git-dir) PR_BODY_TMP.md
try {
  [IO.File]::WriteAllText($prBodyFile, $prBody, [Text.UTF8Encoding]::new($false))
  gh pr create --base "<base>" --head "<branch>" --title "<title>" --body-file $prBodyFile
} finally { Remove-Item -LiteralPath $prBodyFile -ErrorAction SilentlyContinue }
```

Opt-in flags, only when the user asks: `--draft`, `--reviewer <user>`, `--assignee @me`,
`--label <label>`, `--web`.

### Azure DevOps

Parse org/project/repo from the resolved remote: `dev.azure.com/<org>/<project>/_git/<repo>`,
`<org>.visualstudio.com/<project>/_git/<repo>`, or SSH `v3/<org>/<project>/<repo>`.
Strip trailing `.git` and URL-decode project names. Confirm an unclear parse with
`az repos list --organization "https://dev.azure.com/<org>" --project "<project>" --query "[].name" -o tsv`.

**Ask two things before building the command — every Azure DevOps pull request, no exceptions,**
unless the user's invocation already answered them (an explicit `--auto-complete` / `--work-items`
argument this turn skips its ask). Neither has a GitHub equivalent, so this section only:

- **Auto-complete** — merge automatically once policies and reviews are satisfied? Yes adds
  `--auto-complete true --delete-source-branch true` — completion and source-branch cleanup are one
  decision, not two asks. No omits both.
- **Work item** — bind one? Check `<branch>` for a leading `AB#<id>` or bare number first and offer
  it as the default rather than asking blind; a plain "no" adds nothing. Several IDs are
  space-separated in one `--work-items` flag.

```bash
az repos pr create --organization "https://dev.azure.com/<org>" --project "<project>" --repository "<repo>" --source-branch "<branch>" --target-branch "<base>" --title "<title>" --description "## Summary" "- first point" "" "## Test plan" "- how it was checked" --query "{id:pullRequestId,repo:repository.webUrl}" -o tsv
```

- `--description` takes one argument per line; `""` is a blank line (`" "` in PowerShell, which
  drops empty native arguments). **At most 4,000 characters** joined — count, then shorten it.
- Report URL: repository web URL + `/pullrequest/` + ID, using the two returned TSV values.
- Opt-in flags, only when the user asks: `--draft true`, `--squash true`, `--reviewers <email…>`.
