## Stage 0 — the remote half

These lines belong in the **same call** as the six above; this skill reaches a remote, so it needs
`<remote>` and `<base>` before any later stage runs. Use a user-specified remote instead of `origin`.

```bash
git remote get-url origin | sed -E 's#(://)[^@/]+@#\1#'
git symbolic-ref --quiet refs/remotes/origin/HEAD
git fetch origin --no-prune --quiet
grep -nisE "base branch|pull request.*(target|into|against)" CLAUDE.md AGENTS.md CONTRIBUTING.md
```

PowerShell, for the two lines with no portable form:

```powershell
(git remote get-url origin) -replace '://[^@/]+@','://'
Select-String -Path CLAUDE.md,AGENTS.md,CONTRIBUTING.md -Pattern "base branch","pull request.*(target|into|against)" -ErrorAction SilentlyContinue
```

That strips any user-info from the URL, so what prints is safe to keep and to report. **Never print
`git remote -v`** — it shows every URL unredacted, passwords and PATs included. `grep -s` matters:
without it, absent convention files print warnings. This fetch refreshes refs for the later stages;
the standalone `commit` skill omits this remote half. `--no-prune` overrides automatic pruning in
Git configuration: preflight must never delete refs. What the extra lines give you:

| Fact | From |
|---|---|
| platform, `<remote>` | the redacted URL: `github.com` → GitHub + `gh`; `dev.azure.com`, `.visualstudio.com`, `ssh.dev.azure.com` → Azure DevOps + `az repos`; neither → unknown, so no automated pull request, though `<remote>` still stands |
| `<base>` | the convention grep wins outright; otherwise `refs/remotes/origin/HEAD` minus its prefix |

**An explicit remote wins; otherwise use `origin` if present.** If it is missing, list names with `git remote`
and capture one redacted URL each: a single remote wins, otherwise the one GitHub or Azure DevOps
remote, saying why. No remote, or several still ambiguous, stops remote work and reports the choices.
After resolving a missing remote, batch its redacted URL, HEAD and non-pruning fetch before continuing.
Substitute the resolved name into every later command — never hardcode `origin` past this point.

**`<base>` is never guessed from a hardcoded list.** A convention in `CLAUDE.md`, `AGENTS.md` or
`CONTRIBUTING.md` outranks the platform default. If neither the grep nor
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
