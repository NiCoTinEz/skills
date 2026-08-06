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
#
# --uninstall removes symlinks and copies this script made. A plain directory it did not install is
# kept and reported; --force deletes that too.
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

# Dropped into every --mode copy install, read back by --uninstall. Same name in install.ps1, so
# either script can clean up after the other.
marker=".installed-from"

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

# Reject unknown --tool names up front. Without this a typo silently installs nothing (or, mixed
# with a valid name, silently installs less than asked) and still exits 0 — mirrors the PowerShell
# installer's ValidateSet.
known_tools="all claude codex opencode agents"
if [ "$tools" != all ]; then
  bad=""
  old_ifs=$IFS
  IFS=','
  for t in $tools; do
    [ -n "$t" ] || continue
    case " $known_tools " in *" $t "*) ;; *) bad="$bad $t" ;; esac
  done
  IFS=$old_ifs
  if [ -n "$bad" ]; then
    echo "unknown --tool value(s):$bad" >&2
    echo "valid values: ${known_tools// /, }" >&2
    exit 1
  fi
fi

available=()
for d in "$skills_root"/*/; do
  [ -f "$d/SKILL.md" ] || continue
  available+=("$(basename "$d")")
done
[ ${#available[@]} -gt 0 ] || { echo "no skills found under $skills_root" >&2; exit 1; }

# Reject unknown --skill names up front, same reasoning as --tool above: mixed with a valid name a
# typo would otherwise install less than asked and still exit 0. Mirrors install.ps1's throw.
if [ -n "$skills" ]; then
  # Join under the default IFS — "${available[*]}" separates on IFS's first char, so building this
  # after the IFS=',' below would produce a comma-joined string that never matches.
  known_skills=" ${available[*]} "
  bad=""
  old_ifs=$IFS
  IFS=','
  for s in $skills; do
    [ -n "$s" ] || continue
    case "$known_skills" in *" $s "*) ;; *) bad="$bad $s" ;; esac
  done
  IFS=$old_ifs
  if [ -n "$bad" ]; then
    echo "unknown skill(s):$bad" >&2
    echo "available: ${available[*]}" >&2
    exit 1
  fi
fi

skill_dirs=()
for name in "${available[@]}"; do
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
      # A symlink is unambiguously ours. A plain directory is either a --mode copy install (which
      # carries the marker) or a skill the user wrote by hand that happens to share the name —
      # never rm -rf the latter on the strength of its name alone.
      if [ ! -L "$link" ] && [ ! -f "$link/$marker" ] && [ "$force" -eq 0 ]; then
        echo "kept $link: not installed by this script (use --force to delete anyway)" >&2
        skipped=$((skipped + 1))
        continue
      fi
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
      # Already ours from an earlier run — a --mode copy, or a link-mode run in a shell that could
      # not symlink. Refresh it instead of demanding --force for a directory this script wrote.
      if [ -f "$link/$marker" ] && [ "$(cat "$link/$marker")" = "$src" ]; then
        rm -rf -- "$link"
      elif [ "$force" -eq 0 ]; then
        echo "exists, not overwriting (use --force): $link" >&2
        skipped=$((skipped + 1))
        continue
      else
        rm -rf -- "$link"
      fi
    fi

    if [ "$mode" = link ]; then
      ln -s "$src" "$link"
      if [ -L "$link" ]; then
        echo "linked   $link"
      else
        # git-bash with MSYS winsymlinks unset deep-copies instead of linking, silently. Say so —
        # a `git pull` in this repo will not reach it — and mark it so --uninstall knows it is ours.
        printf '%s\n' "$src" > "$link/$marker"
        echo "copied   $link  (this shell cannot create symlinks — snapshot, not live-updating)"
      fi
    else
      cp -R "$src" "$link"
      # Marker so --uninstall can tell our copy from a skill the user wrote themselves.
      printf '%s\n' "$src" > "$link/$marker"
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
