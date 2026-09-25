## Stage 2 — Commit

1. **Review content before staging or committing**, in one inspection call (or batched into
   preflight): `git diff --cached -- <path>` for pre-staged content, `git diff -- <path>` for
   unstaged, new untracked files read directly and capped if oversized. Reuse what this turn already
   read. The secret guardrail covers both sides; stop on a prohibited pre-staged path, preserving the
   index. Safe pre-staged changes are included without another question — name them in the report.
   Stage only reviewed changes belonging to this logical commit. A partially staged file keeps its
   reviewed index version unless its remaining changes belong too; `git add <path>` includes both.

2. **Conventional Commits:**

```
<type>(<scope>): <imperative summary>

- <why, or non-obvious detail>
```

   Optional scope; imperative subject, preferably 50 chars, at most 72, no trailing period.
   Use a body for non-obvious reasons, breaking changes or migration notes; wrap at 72.
   Breaking change: `feat(api)!: …` and a `BREAKING CHANGE: …` footer. **No AI attribution or
   `Co-Authored-By` trailer.** Follow an established different repo convention and report it.
   No "this commit", "I" / "we", or redundant filenames; use `-` bullets in the body.

3. **One call per commit.** The message goes to a file passed with `-F`: a multi-line `-m` is
   mangled differently by every shell.

```bash
git add -- <path> <path>
cat > "$(git rev-parse --git-dir)/COMMIT_MSG_TMP" <<'EOF'
feat(cache): add retry on transient Redis failure

- transient socket errors were surfacing as 500s
EOF
git commit --quiet -F "$(git rev-parse --git-dir)/COMMIT_MSG_TMP"
rm -f "$(git rev-parse --git-dir)/COMMIT_MSG_TMP"
git show --shortstat --format=%h HEAD
git diff --staged --shortstat
```

   *PowerShell* — same call, with a single-quoted here-string whose closing `'@` sits at column 0:

```powershell
git add -- <path> <path>
$msg = @'
feat(cache): add retry on transient Redis failure

- transient socket errors were surfacing as 500s
'@
$f = Join-Path (git rev-parse --git-dir) COMMIT_MSG_TMP
[IO.File]::WriteAllText($f, $msg, [Text.UTF8Encoding]::new($false))
git commit --quiet -F $f
Remove-Item $f
git show --shortstat --format=%h HEAD
git diff --staged --shortstat
```

   Omit `git add` for content already staged. The message file stays inside the git directory.
   Check the commit's own result before reading `git show` as success. The last line is empty
   unless a split left content staged for the next commit.
   A hook rejection stops the flow: fix or report it, never `--no-verify`.

4. **Split unrelated logical changes**, one call per commit, each revertible and passing the repo's
   gate; changes that only work together stay together. Group by change, not filename. Regroup a
   pre-staged index deliberately — never claim a split while committing all of it in the first.
