## Stage 0 — the remote half

These lines belong in the **same call** as the six above; this skill reaches a remote, so it needs
`<remote>` and `<base>` before any later stage runs. Use a user-specified remote instead of `origin`.

```bash
git remote get-url origin | sed -E 's#(://)[^@/]+@#\1#'
git symbolic-ref --quiet refs/remotes/origin/HEAD
git fetch origin --no-prune --quiet
repo_root="$(git rev-parse --show-toplevel)"
grep -nisE "base branch|pull request.*(target|into|against)" "$repo_root/CLAUDE.md" "$repo_root/AGENTS.md" "$repo_root/CONTRIBUTING.md"
```

PowerShell, for the lines with no portable form:

```powershell
(git remote get-url origin) -replace '://[^@/]+@','://'
$repo_root = (git rev-parse --show-toplevel)
Select-String -Path "$repo_root\CLAUDE.md","$repo_root\AGENTS.md","$repo_root\CONTRIBUTING.md" -Pattern "base branch","pull request.*(target|into|against)" -ErrorAction SilentlyContinue
```

That strips user-info from the URL, so it is safe to report. **Never print `git remote -v`** — it
shows every URL unredacted, PATs included. `grep -s` silences absent convention files. `--no-prune`
overrides configured auto-pruning: preflight never deletes refs. What the extra lines give you:

| Fact | From |
|---|---|
| platform, `<remote>` | the redacted URL: `github.com` → GitHub + `gh`; `dev.azure.com`, `.visualstudio.com`, `ssh.dev.azure.com` → Azure DevOps + `az repos`; neither → unknown, so no automated pull request, though `<remote>` still stands |
| `<base>` | a convention grep line that names a branch wins; otherwise `refs/remotes/<remote>/HEAD` minus its prefix |

**An explicit remote wins; otherwise use `origin` if present.** If it is missing, list names with `git remote`
and capture one redacted URL each: a single remote wins, otherwise the one GitHub or Azure DevOps
remote, saying why. No remote, or several still ambiguous, stops remote work and reports the choices.
After resolving a missing remote, batch its redacted URL, HEAD and non-pruning fetch before continuing.
Substitute the resolved name into every later command — never hardcode `origin` past this point.

**`<base>` is never guessed from a hardcoded list.** A convention in `CLAUDE.md`, `AGENTS.md` or
`CONTRIBUTING.md` outranks the platform default — but only a line that names a branch, and only
while `<remote>/<name>` exists: the first later command using it is the check, and a missing ref
drops to the next rung instead of stopping. If neither the grep nor
`refs/remotes/<remote>/HEAD` answers, ask the platform once — `gh repo view "<host>/<owner>/<repo>" --json defaultBranchRef --jq .defaultBranchRef.name`,
or for Azure DevOps, one line, stripping `refs/heads/` from the answer:

```bash
az repos show --organization "https://dev.azure.com/<org>" --project "<project>" --repository "<repo>" --query defaultBranch -o tsv
```

Use the repository identified by the resolved remote, including in folder mode. Cache the answer with
`git remote set-head "<remote>" "<base>"` once that tracking ref exists. Only if all that
fails, take whichever of `<remote>/main`, `<remote>/master`, `<remote>/development`,
`<remote>/develop` exists — and if two candidates remain plausible, take the one this ladder ranks
higher and say which and why rather than asking. No candidate means stop and request the base.
Batch needed fallback probes across repositories; never switch using an unresolved base or remote.
Branch names are case-sensitive and may contain `/`: quote them without changing case.
Every later stage uses `<base>`, never a literal branch name.
