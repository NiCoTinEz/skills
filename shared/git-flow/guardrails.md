## Hard guardrails

Refuse and explain rather than working around any of these:

- **Nothing to commit** — a skill running stage 2 stops on a clean tree. For a skill that doesn't
  commit, a clean tree is normal; its own equivalent is the nothing-to-ship stop, in stage 3 or 4.
- **No `--force`, no `--force-with-lease`, no `--no-verify`**, and no push to a protected or default
  branch unless the user asked when invoking, or confirmed the warning stage 3 gives when it runs.
- **No amend, no rebase, no reset** of existing commits. New commits only.
- **No `git add .` and no `git add -A`.** Stage named paths from the porcelain listing. Never stage or commit
  `.env*`, `*.pem`, `*.key`, `*.pfx`, `id_rsa*`, `*.p12`, `secrets.*`,
  `appsettings.*.local.json`, `*.publishsettings`, a credential or token file, or anything whose
  diff carries an obvious live secret. Check staged content too. If already staged, stop and name
  the paths without exposing secrets or changing the user's index; otherwise leave it unstaged.
- **Merge, rebase, cherry-pick, revert, bisect or sequencer operation in progress, or detached
  HEAD** — stop, report the state, let the user resolve it.

## Act, don't ask

Where preflight already answers a question a stage might ask, **make the call and name it in the
report** — each stage says which choices are its own. The guardrails above still stop the flow.
