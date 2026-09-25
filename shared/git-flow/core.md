## How this skill runs

Stages: **0 preflight → 1 branch → 2 commit → 3 push → 4 pull request → 5 report**. Only the ones
this skill runs appear below; run them in order and stop at the last. **Each block below is one tool
call** — don't split it, and don't add a call a block already covers. Every line runs before you see
any output, so a stage whose next step depends on an earlier one says so and spends a second call.

## Stage 0 — Preflight (always)

```bash
git rev-parse --show-toplevel
git status --porcelain=v1 --branch
git symbolic-ref --quiet --short HEAD
git log --oneline -5
git diff --shortstat
git diff --staged --shortstat
```

An unborn HEAD makes `git log` fail: report `no commits yet` and carry on, a valid state for a
commit skill. Read out of that one answer:

| Fact | From |
|---|---|
| repo root, current branch | lines 1 and 3 |
| `<branch>` | line 3; the branch created or reused by stage 1, or the current branch when no stage 1 runs |
| dirty / staged | porcelain lines other than the `##` header; staged = first column not space or `?` |
| what changed | porcelain paths plus the two bounded `--shortstat` summaries — enough to name a branch and write a message without flooding a large tree |

**Command discipline.** Keep output scoped (`--shortstat`, `--quiet`, `--porcelain`, `-o tsv`);
never run a command whose full output you won't read. Every line runs in Bash *and* PowerShell: one
command per line, no `\` continuation, no backtick, no nested quotes inside `--query` (PowerShell
strips the inner pair). Where no portable form exists, both variants are given.
