# skills

Agent skills that work in **Claude Code**, **Codex CLI**, **OpenCode**, and anything else that
reads the [Agent Skills](https://code.claude.com/docs/en/skills) `SKILL.md` format. One source,
no per-tool forks — every skill folder is self-contained, so installing it is just putting the
folder where the tool looks.

## git-flow — branch / commit / push / PR

Same invocation against **GitHub** and **Azure DevOps**. The platform is read off the `origin`
remote: `gh` for `github.com`, `az repos` for `dev.azure.com` / `*.visualstudio.com`.

| Skill | branch | commit | push | PR |
|---|:--:|:--:|:--:|:--:|
| `branch-commit-push-pr` | ✅ | ✅ | ✅ | ✅ |
| `branch-commit-push` | ✅ | ✅ | ✅ | — |
| `branch-commit` | ✅ | ✅ | — | — |
| `commit-push-pr` | — | ✅ | ✅ | ✅ |
| `commit-push` | — | ✅ | ✅ | — |
| `commit` | — | ✅ | — | — |
| `push-pr` | — | — | ✅ | ✅ |

`branch-*` create a branch. `commit-*` use the branch already checked out; `commit` alone stops
there and never touches a remote. `push-pr` does neither — it ships the commits already on the
branch and leaves any uncommitted work where it is.

**Conventions**

- **Branch:** `<type>/<short-slug>` — `feat/add-cache-retry`, `fix/null-ref-login`,
  `chore/bump-serilog`. Type matches the commit type.
- **Commit:** Conventional Commits, subject ≤50 chars (hard cap 72), body bullets only when the
  *why* isn't obvious. No AI attribution, no `Co-Authored-By` trailer.
- **One commit per logical change**, not one per invocation. A mixed tree gets split, ordered so
  each commit stands on its own and passes the repo's gate; changes that only work together stay
  together.
- **Base branch:** resolved, never guessed — repo convention (`CLAUDE.md` / `AGENTS.md` /
  `CONTRIBUTING.md`) first, then `<remote>/HEAD`, then the platform's own default-branch API, and
  only as a last resort `main` → `master` → `development` → `develop`. A hardcoded ladder gets
  `development`, `DEV` and `v1/development` defaults wrong, which silently opens a PR with the
  wrong diff.
- **PR body:** `## Summary` + `## Test plan`.

**Guardrails**

- Never `--force`, `--no-verify`, amend, rebase, or reset.
- Never `git add .` without reading `git status` first; refuses to stage `.env*`, `*.pem`,
  `*.key`, `id_rsa*` and similar secret-shaped paths.
- Pushing to the default branch needs explicit confirmation.
- Non-fast-forward push stops and reports — no force-push, no silent rebase.
- Nothing to push, or no commits between branch and base, stops and says which — no empty PR.
- Never installs a CLI itself; asks with the exact command and waits.

They all share one procedure file: [`shared/git-flow/workflow.md`](./shared/git-flow/workflow.md).
Edit it, run `npm run build`, and every skill picks the change up.

**Needs**

| Need | For |
|---|---|
| `git` | everything |
| [`gh`](https://cli.github.com/) + `gh auth login` | GitHub PRs |
| `az` + `az extension add --name azure-devops` | Azure DevOps PRs |

Azure DevOps auth: `az login`, or a PAT with `Code (read & write)` + `Pull Request contribute`:

```powershell
$env:AZURE_DEVOPS_EXT_PAT = "<pat>"
```

`commit`, `branch-commit`, `branch-commit-push` and `commit-push` need only `git`.

## Install

```bash
npx skills add NiCoTinEz/skills                            # pick skills + agents interactively
npx skills add NiCoTinEz/skills --skill commit-push -y     # one skill, no prompts
npx skills add NiCoTinEz/skills --skill '*' --global -y    # all of them, user-level
```

Uses the `skills` CLI. It detects which coding agents you have and installs into each one's skill
directory — 75+ agents, including Claude Code, Codex, OpenCode, Cursor, Cline, Copilot, Gemini CLI,
Windsurf and Zed. Nothing here is tool-specific, so all of them get the same files.

| Flag | Meaning |
|---|---|
| `-s`, `--skill <names…>` | which skills; `'*'` for all. Omit to choose interactively |
| `-a`, `--agent <agents…>` | target specific agents instead of the detected set |
| `-g`, `--global` | install to the user directory instead of the current project |
| `-l`, `--list` | list what the repo offers, install nothing |
| `--copy` | copy the files instead of symlinking them |
| `-y`, `--yes` | skip confirmation prompts |
| `--all` | every skill into every agent, no prompts |

### From a clone

For when you want the skills linked straight to a working copy, so a `git pull` (or your own edit)
applies without reinstalling — or when you'd rather not run `npx`:

```bash
git clone https://github.com/NiCoTinEz/skills.git
cd skills
```

```powershell
./scripts/install.ps1          # Windows
```

```bash
./scripts/install.sh           # macOS / Linux / WSL / git-bash
```

Links (Windows: directory junction — no admin needed) each skill into every tool's skill directory.
`-Mode copy` / `--mode copy` takes an independent snapshot instead.

Copies — and links made in a shell that can't create symlinks, i.e. git-bash without
`MSYS=winsymlinks:nativestrict`, where `ln -s` silently deep-copies — carry a `.installed-from`
file naming their source. That is how `-Uninstall` / `--uninstall` tells its own copies from a skill
you wrote by hand that happens to share the name: the latter is kept and reported, never deleted,
unless you pass `-Force` / `--force`. Symlinks and junctions are removed without it, target
untouched. A snapshot is reported as `copied`, not `linked`, so you can see it isn't live-updating.

| Flag | Meaning |
|---|---|
| `-Tool` / `--tool` | `all` (default), or any of `claude`, `codex`, `opencode`, `agents`, comma-separated |
| `-Skill` / `--skill` | install a subset instead of all of them |
| `-Mode` / `--mode` | `link` (default) or `copy` |
| `-Scope` / `--scope` | `user` (default) or `project` |
| `-Project` / `--project` | target repo root for `--scope project` |
| `-Force` / `--force` | overwrite existing entries, create missing tool dirs, widen `--uninstall` |
| `-Uninstall` / `--uninstall` | remove the links/copies it made; sources are never touched |

An unknown `--tool` or `--skill` name is an error, not a silent no-op — a typo can't quietly install
less than you asked for.

By default a tool is skipped when its home directory is absent — nothing gets created for a tool
you don't use.

Its four targets use the same directories `npx skills` does, so the two install methods can't
produce competing copies of a skill:

| Tool | User scope | Project scope |
|---|---|---|
| Claude Code | `~/.claude/skills/<name>/` | `.claude/skills/<name>/` |
| Codex CLI | `$CODEX_HOME/skills/<name>/` (default `~/.codex`) | `.agents/skills/<name>/` |
| OpenCode | `~/.config/opencode/skills/<name>/` | `.agents/skills/<name>/` |
| any agent following the convention | `~/.agents/skills/<name>/` | `.agents/skills/<name>/` |

Codex, OpenCode and `agents` share `.agents/skills` at project scope, so a project install writes
two directories, not four — the installer reports the ones it skipped as duplicates. OpenCode also
reads `~/.claude/skills` and `~/.agents/skills` directly, so it usually works even if you only
installed for another tool. For anything outside these four, use `npx skills` with `--agent`.

### Claude Code, as a plugin instead

If you'd rather manage it through `/plugin`:

```
/plugin marketplace add NiCoTinEz/skills
/plugin install nicotinez-skills@nicotinez-skills
```

Update later with `/plugin marketplace update nicotinez-skills`.

### Agents that don't load SKILL.md themselves

Some agents need to be told where to look. `npx skills --agent <name>` handles the ones it knows;
otherwise install to project scope and point the agent's own rules file at
`.agents/skills/<name>/SKILL.md`. Failing that, paste the skill body into the chat — these are plain
Markdown with no tool-specific syntax.

## Update

Which command depends on how you installed. Skills aren't versioned individually — an update just
brings the installed folder in line with the repo.

**Installed with `npx skills add`:**

```bash
npx skills update                       # every installed skill, scope auto-detected
npx skills update commit-push -y        # one skill, skip the scope prompt
npx skills update --global -y           # user-level installs only (--project for the other)
```

`npx skills list` shows what is installed and where. Re-running the original `npx skills add …`
command works too — it overwrites the existing install.

**Installed from a clone:**

```bash
git pull
```

For a default `link` install that is the whole update: the junction/symlink points at the working
copy, so the agent reads the new files on its next session. Nothing to re-run.

A `copy` install is a snapshot, so re-run the same install command to refresh it — no `-Force` /
`--force` needed, because the installer recognises its own copies by their `.installed-from` marker:

```powershell
./scripts/install.ps1 -Mode copy
```

```bash
./scripts/install.sh --mode copy
```

The same applies to a `link` install made in git-bash without `MSYS=winsymlinks:nativestrict` —
`ln -s` deep-copies there, so it is a snapshot too. The installer reports those as `copied` rather
than `linked`, which is how you can tell. `--force` is only needed when the target isn't a directory
these scripts wrote — one from `npx skills add --copy`, say, or a skill of your own.

Both installers run `npm run build` before installing anything, so a regenerated `references/`
always lands before the copy or link is made. Without `node` on `PATH` they warn and skip that step.

**Installed as a Claude Code plugin:**

```
/plugin marketplace update nicotinez-skills
```

### Changing a skill yourself

These are plain Markdown. Edit `skills/<name>/SKILL.md` in a clone and a `link` install picks the
change up on the agent's next session — no reinstall, no build.

Two rules. Prose shared by several skills lives in `shared/<set>/`, so edit that and run
`npm run build`; **never hand-edit `skills/*/references/`**, which is generated and will be
overwritten. Then run `npm run check` — it fails on a stale generated copy, a frontmatter `name`
that no longer matches its folder, a missing `description`, a `references/` path a skill cites but
doesn't ship, and manifest drift.

Adding a new skill, and the invariants behind those checks: [`AGENTS.md`](./AGENTS.md).

## Usage

Ask for it by name, or describe the outcome — the `description` frontmatter is what routes it:

```
/branch-commit-push-pr
commit and push this on a new branch
ship this and open a PR
```

## Repo layout

```
skills/<name>/SKILL.md            the skill
skills/<name>/agents/openai.yaml  Codex display name + one-line summary
skills/<name>/references/*.md     bundled resources — generated, don't edit
shared/<set>/*.md                 source for anything shared by several skills
scripts/build.mjs                 shared/ -> skills/*/references/, plus manifest checks
scripts/install.ps1 | install.sh  installers
.claude-plugin/                   plugin manifest (owns the skills list) + marketplace entry
AGENTS.md                         contributor/agent notes, invariants, how to add a skill
```

`npm run build` regenerates, `npm run check` verifies. Editing a skill:
[Changing a skill yourself](#changing-a-skill-yourself). Adding one, and the invariants the check
enforces: [`AGENTS.md`](./AGENTS.md).
