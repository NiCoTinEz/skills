## How this skill runs

Stages: **0 preflight → 1 branch → 2 commit → 3 push → 4 pull request → 5 report**. Only the ones
this skill runs appear below; run them in order and stop at the last. **Each block below is one tool
call** — its lines run in one shell and answer at once, so don't split a block across calls and don't
add a call a block already covers. A stage is one block unless it says otherwise: every line in a
block runs before you see any of the output, so a stage whose next step depends on the previous one
having worked says so and spends the second call.

## Stage 0 — Preflight (always)

```bash
git rev-parse --show-toplevel
git status --porcelain=v1 --branch
git symbolic-ref --quiet --short HEAD
git log --oneline -5
git diff --stat
git diff --staged --stat
```

An unborn HEAD makes `git log` fail: report `no commits yet` and carry on, a valid state for a
commit skill. Read out of that one answer:

| Fact | From |
|---|---|
| repo root, current branch | lines 1 and 3 |
| dirty / staged | porcelain lines other than the `##` header; staged = first column not space or `?` |
| what changed | the two `--stat` lines — enough to name a branch and write a message |

**Command discipline.** Keep output scoped — `--stat`, `--quiet`, `--porcelain`,
`--query … -o tsv` — and never run a command whose full output you won't read. Every line must run
in Bash *and* PowerShell: one command per line, no `\` continuation (a PowerShell parse error), no
backtick (breaks Bash), and no nested quotes inside `--query` (PowerShell strips the inner pair, so
any hyphenated JMESPath key is unwritable — pick a query that doesn't need one). Where no portable
form exists, both variants are given.
