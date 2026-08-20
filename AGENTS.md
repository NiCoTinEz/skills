# AGENTS.md

Agent-facing notes for this repo. This repo *is* a skill library — the deliverable is the
`skills/` folder, consumed by Claude Code, Codex CLI, OpenCode, and anything else that reads the
[Agent Skills](https://code.claude.com/docs/en/skills) `SKILL.md` format.

## Layout

```
skills/<name>/SKILL.md              a skill — GENERATED, do not edit. Frontmatter: name + description
skills/<name>/agents/openai.yaml    Codex display metadata (display_name, short_description, default_prompt)
shared/<set>/heads/<name>.md        per-skill head: frontmatter, what it refuses, its own stops
shared/<set>/*.md                   one file per stage, shared by every skill that runs it
scripts/build.mjs                   assembles shared/ -> skills/*/SKILL.md, plus manifest checks
scripts/install.ps1 / install.sh    installs skills into each tool's skill dir
.claude-plugin/plugin.json          plugin manifest — owns the authoritative skills list
.claude-plugin/marketplace.json     marketplace entry pointing at the plugin
```

A `SKILL.md` is `heads/<name>.md` followed by the stage bodies that skill runs, in the order the
`SKILLS` array in `scripts/build.mjs` lists them. Nothing is loaded at runtime beyond that one file:
the stages used to ship as `references/*.md` that every skill then told the agent to read, which
cost 2-5 tool calls before any work and bought nothing over having the body already in hand.

## Invariants

- **A skill folder must be self-contained.** Only the folder gets copied or linked into a tool's
  skill dir — by our installers *and* by `npx skills add` — so a skill may never reference a path
  outside itself. No `${CLAUDE_PLUGIN_ROOT}`, no `../shared/…`; Codex, OpenCode and the ecosystem
  CLI do not expand or resolve those.
- **Stay discoverable by the `npx skills add` installer**, the documented primary install path. It
  wants `skills/<name>/SKILL.md` with `name` (equal to the folder name) and `description`. **Never
  add a root-level `SKILL.md`**: it searches shallowest-first and a root file shadows everything
  under `skills/`.
- **Never hand-edit `skills/*/SKILL.md`.** Each carries a generated banner under its frontmatter.
  Edit `shared/<set>/heads/<name>.md` for one skill or `shared/<set>/<stage>.md` for a stage every
  skill shares, then run `npm run build`.
- **A generated `SKILL.md` is capped** (`MAX_LINES` in `scripts/build.mjs`). It is the whole runtime
  payload now, so the build fails rather than letting it creep. Trim a stage instead of raising it,
  and cut any "why" that doesn't change what the agent types.
- **One tool call per stage.** The stage bodies are written as single batched calls; a change that
  splits one into several commands the agent must run separately is a regression, not a hardening.
- **Frontmatter stays portable.** `name` and `description` are the only keys every tool reads.
  Extra keys are ignored by others, so keep tool-specific ones optional and harmless.
- **`description` is the routing signal.** It is the only text a tool sees before deciding to load
  the skill — state what it does *and* the phrases that should trigger it.
- **Plugin content changes require a version bump.** Claude Code caches plugin versions, so update
  both `package.json` and `.claude-plugin/plugin.json` whenever a shipped skill body changes.
- Skill body text must not name one specific agent ("this plugin", "Claude will…"). Write it for
  any agent.

## Verification gate before claiming done

```pwsh
npm run check    # generated SKILL.md files current + manifests consistent — must pass
```

If anything about skill folders, names or frontmatter changed, confirm the ecosystem CLI still sees
them. Cheapest real check, and it needs no push:

```bash
npx skills add "<repo-root>" -l                    # must list every skills/<name>, none missing
cd <tmpdir> && npx skills add "<repo-root>" --skill commit-push --agent claude-code --copy -y
# then assert the folder really is self-contained — and carries no references/ any more:
#   .claude/skills/commit-push/SKILL.md
#   .claude/skills/commit-push/agents/openai.yaml
```

Then, if scripts changed, exercise them against a throwaway dir rather than your real config:

```pwsh
./scripts/install.ps1 -Scope project -Project <tmpdir> -Skill commit-push
./scripts/install.ps1 -Scope project -Project <tmpdir> -Uninstall
```

```bash
./scripts/install.sh --scope project --project <tmpdir> --skill commit-push --mode copy
./scripts/install.sh --scope project --project <tmpdir> --uninstall
```

## Adding a skill

1. `shared/<set>/heads/<name>.md`: frontmatter with `name` (must equal the folder name) and
   `description`, then what the skill refuses and any stop that is its own. Keep it short — the
   stages carry the procedure.
2. An entry in the `SKILLS` array in `scripts/build.mjs` listing the stages it runs, in order.
   Membership there *is* the stage list the head claims in its opening line.
3. A stage body only if the skill needs one no other skill has → `shared/<set>/<stage>.md`, plus a
   key in `STAGES`. Then `npm run build` writes `skills/<name>/SKILL.md`.
4. `skills/<name>/agents/openai.yaml` — Codex reads it for the skill's display name and one-line
   summary. Schema, as used by Codex's own bundled skills:
   ```yaml
   interface:
     display_name: "Commit Push"
     short_description: "Commit on this branch and push it"
     default_prompt: "Use $commit-push to …"   # optional
     icon_small: "./assets/x-small.svg"        # optional
     icon_large: "./assets/x.png"              # optional
   policy:
     allow_implicit_invocation: false          # optional; omit to let Codex trigger it from context
   ```
5. Add `"./skills/<name>"` to the `skills` array in `.claude-plugin/plugin.json`.
6. Update the tables in `README.md`.

`npm run check` enforces steps 4 and 5, so a forgotten one fails the gate rather than shipping a
half-registered skill. It also fails if `plugin.json` lists a skill that has no `SKILL.md`, if the
marketplace entry's name drifts from `plugin.json`'s, or if `package.json` and `plugin.json`
versions disagree.

It enforces the folder invariants too, so none of them relies on a reviewer noticing:

- frontmatter `name` equals the folder name, and a `description` exists;
- no root-level `SKILL.md`;
- every `skills/<name>/` is listed in `SKILLS`, so a hand-written `SKILL.md` can't sit there and
  drift out of the build's reach;
- no `references/` folder survives and no `SKILL.md` cites one — `npm run build` deletes a leftover,
  `npm run check` reports it;
- and no generated body exceeds `MAX_LINES`.

## Traps

- **Installer paths match what `npx skills add` writes, on purpose** — that CLI's own agent table is
  the authority, not intuition. Codex and OpenCode both use `.agents/skills` at *project* scope (not
  `.codex/skills`, not `.opencode/skills`), while their *global* dirs are `$CODEX_HOME/skills` and
  `~/.config/opencode/skills`. If these drift, a user who runs both install methods ends up with two
  competing copies of the same skill. Verify against the CLI before changing any path.
- Because three targets share `.agents/skills` at project scope, both installers dedupe by
  destination and print `skip <tool>: same dir as …`. That output is correct, not a bug.
- OpenCode also reads `~/.claude/skills` and `~/.agents/skills`, so a Claude install often covers
  OpenCode too — the installer still writes its own dir on purpose, so removing one doesn't
  silently break the other.
- `install.ps1` uses a directory **junction**, not a symlink, because junctions need no admin
  rights on Windows. Uninstall calls `.Delete()` on the link so target contents survive.
- **Don't add a divergence probe to stage 0.** A `git rev-list --left-right --count <remote>/HEAD...HEAD`
  line looks free there, but `refs/remotes/<remote>/HEAD` is unset in plenty of clones and the line
  then goes `fatal: ambiguous argument` on every run. The branch stage owns that check, and spends a
  call on it only when the tree is dirty.
- **`.gitattributes` pins `*.md` to `eol=lf`, and `build.mjs` compares newline-normalised.** Both
  are load-bearing, not style. `BANNER` is an LF string spliced into the source body, so a CRLF
  checkout (any Windows clone with `core.autocrlf=true`) makes every generated copy compare unequal:
  `npm run check` reports all of them stale, `npm run build` "fixes" it by writing mixed-eol files,
  git normalises those back to LF on commit, and the next clone is stale again. Don't remove either.
- **A copy install carries a `.installed-from` marker; a link doesn't need one.** That is how
  `--uninstall` distinguishes its own copies from a skill the user wrote by hand under the same
  name, which it keeps and reports instead of `rm -rf`-ing. `--force` overrides. It also lets a
  re-run refresh its own copy instead of demanding `--force`.
- **`ln -s` in git-bash silently deep-copies** unless `MSYS=winsymlinks:nativestrict` is set, so the
  default `--mode link` is a snapshot there, not live-updating. `install.sh` tests `[ -L ]` after
  creating the link, reports `copied` rather than `linked` when it lost, and drops the marker.
- The two manifests split responsibilities: `plugin.json` owns the `skills` array (one list, so it
  can't drift), `marketplace.json` just points at the plugin with `source: "./"`. Their `name`
  fields must be identical — `/plugin install <plugin-name>@<marketplace-name>` resolves through
  both. `npm run check` fails on either mistake.
