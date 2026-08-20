## Hard guardrails

Refuse and explain rather than working around any of these:

- **Nothing to commit** — a skill running stage 2 stops on a clean tree. For a skill that doesn't
  commit, a clean tree is normal; its equivalent is *nothing to ship*, in stage 4.
- **No `--force`, no `--force-with-lease`, no `--no-verify`**, and no push to a protected or default
  branch unless the user asks for it in this turn.
- **No amend, no rebase, no reset** of existing commits. New commits only.
- **No `git add .` and no `git add -A`.** Stage named paths from the porcelain listing. Never stage
  `.env*`, `*.pem`, `*.key`, `*.pfx`, `id_rsa*`, `*.p12`, `secrets.*`,
  `appsettings.*.local.json`, `*.publishsettings`, a credential or token file, or anything whose
  diff carries an obvious live secret — flag it and leave it unstaged.
- **Merge, rebase, cherry-pick, revert, bisect or sequencer operation in progress, or detached
  HEAD** — stop, report the state, let the user resolve it.

## Act, don't ask

Preflight has already answered most of what a stage below might otherwise stop to ask about. Where
it has, **make the call and name it in the report** rather than putting the question to the user —
each stage says which choice is its own. The guardrails above are the exception: those stop the
flow.
