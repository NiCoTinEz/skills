#!/usr/bin/env bash
# Install these skills into Claude Code, Codex CLI, OpenCode, or the shared ~/.agents/skills dir.
#
#   ./scripts/install.sh                              every detected tool, user scope, symlinked
#   ./scripts/install.sh --tool codex,opencode
#   ./scripts/install.sh --mode copy
#   ./scripts/install.sh --scope project --project ~/src/some-repo
#   ./scripts/install.sh --skill commit-push,commit-push-pr
#   ./scripts/install.sh --uninstall
#
# Flags: --tool all|claude|codex|opencode|agents (comma-separated)  --skill <names>
#        --mode link|copy  --scope user|project  --project <path>  --force  --uninstall
#        -h, --help
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skills_root="$repo_root/skills"
[ -d "$skills_root" ] || { echo "skills/ not found under $repo_root" >&2; exit 1; }

tools=all
skills=
mode=link
scope=user
project="$PWD"
force=0
uninstall=0

while [ $# -gt 0 ]; do
  case "$1" in
    --tool) tools="$2"; shift 2 ;;
    --skill) skills="$2"; shift 2 ;;
    --mode) mode="$2"; shift 2 ;;
    --scope) scope="$2"; shift 2 ;;
    --project) project="$2"; shift 2 ;;
    --force) force=1; shift ;;
    --uninstall) uninstall=1; shift ;;
    # Print the header comment block only — stop at the first non-comment line.
    -h|--help) sed -n '2,${/^#/!q;s/^#\( \|$\)//;p;}' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 1 ;;
  esac
done

case "$mode" in link|copy) ;; *) echo "--mode must be link or copy" >&2; exit 1 ;; esac
case "$scope" in user|project) ;; *) echo "--scope must be user or project" >&2; exit 1 ;; esac

# Keep generated references in sync before installing anything.
if [ "$uninstall" -eq 0 ]; then
  if command -v node >/dev/null 2>&1; then
    node "$repo_root/scripts/build.mjs" >/dev/null
  else
    echo "warning: node not found — skipping build; skills/*/references/ may be stale" >&2
  fi
fi

codex_home="${CODEX_HOME:-$HOME/.codex}"
xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}"

# Paths mirror what `npx skills add` writes, so a skill installed that way and one installed from
# a clone land in the same place instead of two competing copies. Codex and OpenCode
# both use .agents/skills at project scope — the dedupe below stops that installing three times.
#
# name|user-scope dir|project-scope subdir
all_targets=$(cat <<EOF
claude|$HOME/.claude/skills|.claude/skills
codex|$codex_home/skills|.agents/skills
opencode|$xdg_config/opencode/skills|.agents/skills
agents|$HOME/.agents/skills|.agents/skills
EOF
)

wanted() {
  [ "$tools" = all ] && return 0
  case ",$tools," in *",$1,"*) return 0 ;; *) return 1 ;; esac
}

skill_dirs=()
for d in "$skills_root"/*/; do
  [ -f "$d/SKILL.md" ] || continue
  name=$(basename "$d")
  if [ -n "$skills" ]; then
    case ",$skills," in *",$name,"*) ;; *) continue ;; esac
  fi
  skill_dirs+=("$name")
done
[ ${#skill_dirs[@]} -gt 0 ] || { echo "no skills matched" >&2; exit 1; }

done_count=0
skipped=0
seen_dests=""

while IFS='|' read -r name user_dir project_sub; do
  wanted "$name" || continue

  if [ "$scope" = project ]; then
    dest="$project/$project_sub"
  else
    dest="$user_dir"
    # Only touch a tool that is actually set up, unless --force.
    if [ "$uninstall" -eq 0 ] && [ "$force" -eq 0 ] && [ ! -d "$(dirname "$dest")" ]; then
      echo "skip $name: $(dirname "$dest") not present (use --force to create)"
      continue
    fi
  fi

  # Several agents share a directory (.agents/skills at project scope). Do it once.
  case "$seen_dests" in
    *"|${dest%/}|"*) echo "skip $name: same dir as an agent already handled"; continue ;;
  esac
  seen_dests="$seen_dests|${dest%/}|"

  for skill in "${skill_dirs[@]}"; do
    src="$skills_root/$skill"
    link="$dest/$skill"

    if [ "$uninstall" -eq 1 ]; then
      [ -e "$link" ] || [ -L "$link" ] || continue
      rm -rf -- "$link"   # removes the symlink itself, not its target
      echo "removed  $link"
      done_count=$((done_count + 1))
      continue
    fi

    mkdir -p "$dest"

    if [ -L "$link" ] && [ "$(readlink "$link")" = "$src" ] && [ "$mode" = link ]; then
      echo "ok       $link"
      skipped=$((skipped + 1))
      continue
    fi

    if [ -e "$link" ] || [ -L "$link" ]; then
      if [ "$force" -eq 0 ]; then
        echo "exists, not overwriting (use --force): $link" >&2
        skipped=$((skipped + 1))
        continue
      fi
      rm -rf -- "$link"
    fi

    if [ "$mode" = link ]; then
      ln -s "$src" "$link"
      echo "linked   $link"
    else
      cp -R "$src" "$link"
      echo "copied   $link"
    fi
    done_count=$((done_count + 1))
  done
done <<< "$all_targets"

echo
if [ "$uninstall" -eq 1 ]; then
  echo "$done_count removed, $skipped untouched"
else
  echo "$done_count installed, $skipped skipped"
  [ "$done_count" -gt 0 ] && echo "Restart the agent (or start a new session) to pick the skills up."
fi
