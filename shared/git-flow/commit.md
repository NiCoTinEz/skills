## Stage 2 — Commit

1. **Review content before staging or committing.** Batch reads into preflight when paths are known,
   otherwise one inspection call: `git diff --cached -- <path>` for pre-staged content and
   `git diff -- <path>` for unstaged changes to include; read new untracked files directly.
   Reuse content already inspected in this turn if unchanged. Apply the secret guardrail to both
   staged and unstaged content; stop on a prohibited pre-staged path, preserving the user's index.
   Safe pre-staged changes are included without another question — name them in the report.
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
git diff --staged --stat
git rev-parse --short HEAD
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
git diff --staged --stat
git rev-parse --short HEAD
```

   Omit `git add` for content already staged. The message file stays inside the git directory.
   Check the commit's own result before interpreting the final stats or HEAD as success.
   A hook rejection stops the flow: fix or report it, never `--no-verify`.

4. **Split unrelated logical changes**, one call per commit. Each should be independently
   revertible and pass the repo's verification gate. Changes that only work together stay together.
   Group by change, not filename; if a file cannot be split by path, explain its chosen group.
   Pre-staged unrelated changes need deliberate index regrouping before separate commits; never
   claim a split while committing the entire original index into the first group.
