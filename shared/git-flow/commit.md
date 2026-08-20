## Stage 2 — Commit

1. **Stage deliberately** — everything belonging to this one logical change, nothing else.
   Preflight already printed both stats; where they don't say enough for the message body, read the
   single path with `git diff -- <path>` rather than the whole tree. Anything **already staged**
   before you started is included rather than queried — name it in the report.

2. **Conventional Commits:**

```
<type>(<scope>): <imperative summary>

- <why, or non-obvious detail>
```

   `<scope>` is optional — use the project or module name when the repo already does. Imperative
   mood: `add`, `fix`, `remove`, not `added` or `adds`. Subject 50 chars preferred, hard cap 72, no
   trailing period. A body only when the *why* isn't obvious from the diff, or for breaking changes
   and migration notes; wrap at 72, bullets with `-`. Breaking change: `feat(api)!: …` plus a
   `BREAKING CHANGE: …` footer. **No AI attribution and no `Co-Authored-By` trailer.** No "this
   commit", no "I" or "we", and don't restate filenames the scope already covers. If preflight's
   `git log` shows the repo using a different convention, follow the repo and mention the deviation.

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
Set-Content -Path $f -Value $msg -Encoding utf8
git commit --quiet -F $f
Remove-Item $f
git diff --staged --stat
git rev-parse --short HEAD
```

   The message file sits inside the git directory, so it can never be picked up as a repo change.
   `--quiet` drops the per-file summary; the last two lines are what the report needs, and an empty
   stat confirms nothing was left staged by mistake. A hook rejecting the commit is a real problem —
   fix it or report it, never `--no-verify`.

4. **Several unrelated logical changes means several commits** — one call each, and default to
   splitting: one commit per logical change, not one per invocation. Group by *change*, not by file;
   a file touched for two unrelated reasons belongs to two groups, staged by path, and if it can't
   be split by path, say so and keep it in the group it mostly serves. The test for one group: it
   reads as a single changelog line, and could be reverted on its own without taking unrelated work
   with it. **Every commit must stand alone** — order the groups so each leaves the tree working and
   passes any verification gate the repo has, not just the last one. Two changes that only work
   together are *one* logical change however different they look: a new module plus the manifest
   entry registering it can't be split, because the commit registering a file that doesn't exist yet
   is broken. Ambiguous grouping is not a question for the user — take the defensible split and say
   what you chose.
