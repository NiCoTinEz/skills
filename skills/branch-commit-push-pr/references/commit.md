<!-- generated from shared/git-flow/commit.md — edit that file, then run: npm run build -->

# git-flow stage 2 — Commit

Read alongside `core.md`, which holds preflight, `<remote>` / `<base>` resolution, the guardrails
(including the staging and secret-path rules this stage relies on) and the report format.

1. Read the change, then stage deliberately — everything relevant to this one logical change,
   nothing else. **Stat first; never a bare `git diff`:**

```bash
git diff --stat
git diff --staged --stat
git add -- <path> <path>
git diff --staged --stat
```

   The stat names most changes on its own. Where it doesn't — you need the *why* for the body, or
   you're deciding which group a path belongs to — read that one path with `git diff -- <path>`.
   Reading the whole tree costs tens of thousands of tokens where the stat costs a few hundred
   (128× on a real tree), and the message is a subject line plus two bullets either way.

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
git commit --quiet -F "$(git rev-parse --git-dir)/COMMIT_MSG_TMP"
rm -f "$(git rev-parse --git-dir)/COMMIT_MSG_TMP"
git rev-parse --short HEAD
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
git commit --quiet -F $f
Remove-Item $f
git rev-parse --short HEAD
```

   The file goes inside `.git/`, so it can never be picked up as a repo change. `--quiet` drops the
   per-file change summary, which is a line per file on a large commit; `git rev-parse --short HEAD`
   gives the one thing the report actually needs.

4. If a hook rejects the commit, fix the underlying problem or report it. Never `--no-verify`.
5. **Several unrelated logical changes in the tree → make several commits.** Default to splitting;
   one commit per logical change, not one commit per invocation. Repeat steps 1–4 for each group.

   Group by *change*, not by file or directory. A file touched for two unrelated reasons belongs to
   two groups — stage the paths that carry each reason, not the whole file, and if a single file
   can't be split by path, say so and keep it in the group it mostly serves.

   The test for one group: it would read as a single line in a changelog, and it could be reverted
   on its own without taking unrelated work with it.

   **Every commit must stand alone.** Order the groups so each one leaves the tree in a working
   state — if the repo has a verification gate (`npm run check`, a test suite, a build), each commit
   should pass it, not just the last. Two changes that only work together are *one* logical change,
   however different they look: a new module plus the manifest entry that registers it cannot be
   split, because the commit that registers a file that doesn't exist yet is broken.

   Split, and the report lists one `commit` line per commit, in the order they were made. Don't
   split when it would produce a commit that can't stand alone, and say why you kept them together.
   If the grouping is genuinely ambiguous, ask rather than guessing.
