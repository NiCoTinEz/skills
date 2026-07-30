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

`branch-*` create a branch. `commit-*` use the branch already checked out.

**Conventions**

- **Branch:** `<type>/<short-slug>` — `feat/add-cache-retry`, `fix/null-ref-login`,
  `chore/bump-serilog`. Type matches the commit type.
- **Commit:** Conventional Commits, subject ≤50 chars (hard cap 72), body bullets only when the
  *why* isn't obvious. No AI attribution, no `Co-Authored-By` trailer.
- **Base branch:** `origin/HEAD`, else `main` → `master` → `develop`.
- **PR body:** `## Summary` + `## Test plan`.

**Guardrails**

- Never `--force`, `--no-verify`, amend, rebase, or reset.
- Never `git add .` without reading `git status` first; refuses to stage `.env*`, `*.pem`,
  `*.key`, `id_rsa*` and similar secret-shaped paths.
- Pushing to the default branch needs explicit confirmation.
- Non-fast-forward push stops and reports — no force-push, no silent rebase.
- Never installs a CLI itself; asks with the exact command and waits.

All five share one procedure file: [`shared/git-flow/workflow.md`](./shared/git-flow/workflow.md).
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

`branch-commit`, `branch-commit-push` and `commit-push` need only `git`.

## Install

```bash
npx skills add NiCoTinEz/skills                            # pick skills + agents interactively
npx skills add NiCoTinEz/skills --skill commit-push -y     # one skill, no prompts
npx skills add NiCoTinEz/skills --skill '*' --global -y    # all five, user-level
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

| Flag | Meaning |
|---|---|
| `-Tool` / `--tool` | `all` (default), or any of `claude`, `codex`, `opencode`, `agents`, comma-separated |
| `-Skill` / `--skill` | install a subset instead of all five |
| `-Mode` / `--mode` | `link` (default) or `copy` |
| `-Scope` / `--scope` | `user` (default) or `project` |
| `-Project` / `--project` | target repo root for `--scope project` |
| `-Force` / `--force` | overwrite existing entries, and create tool dirs that don't exist yet |
| `-Uninstall` / `--uninstall` | remove the links/copies; sources are never touched |

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

`npm run build` regenerates, `npm run check` verifies — both the generated references and the
manifests.

Adding or changing a skill: see [`AGENTS.md`](./AGENTS.md).
