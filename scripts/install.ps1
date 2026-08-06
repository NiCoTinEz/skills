#!/usr/bin/env pwsh
<#
.SYNOPSIS
Install these skills into Claude Code, Codex CLI, OpenCode, or the shared ~/.agents/skills dir.

.EXAMPLE
./scripts/install.ps1
Installs every skill for every detected tool, user scope, by junction (live-updating).

.EXAMPLE
./scripts/install.ps1 -Tool codex,opencode -Mode copy

.EXAMPLE
./scripts/install.ps1 -Scope project -Project D:\git\Net_Api.General

.EXAMPLE
./scripts/install.ps1 -Uninstall
#>
[CmdletBinding()]
param(
  # all = every tool this script knows. agents = the shared ~/.agents/skills dir, which OpenCode
  # also reads; useful for any other agent that adopts the convention.
  [ValidateSet('all', 'claude', 'codex', 'opencode', 'agents')]
  [string[]]$Tool = @('all'),

  # Which skills. Default: everything under skills/.
  [string[]]$Skill,

  # link = directory junction, so edits in this repo take effect immediately (default).
  # copy = independent snapshot.
  [ValidateSet('link', 'copy')]
  [string]$Mode = 'link',

  [ValidateSet('user', 'project')]
  [string]$Scope = 'user',

  # Target repo root for -Scope project. Defaults to the current directory.
  [string]$Project = (Get-Location).Path,

  [switch]$Uninstall,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$skillsRoot = Join-Path $repoRoot 'skills'

if (-not (Test-Path $skillsRoot)) { throw "skills/ not found under $repoRoot" }

# Keep generated references in sync before installing anything.
if (-not $Uninstall) {
  if (Get-Command node -ErrorAction SilentlyContinue) {
    & node (Join-Path $PSScriptRoot 'build.mjs') | Out-Null
  }
  else {
    Write-Warning "node not found — skipping build; skills/*/references/ may be stale"
  }
}

$home_ = $HOME ?? $env:USERPROFILE
$codexHome = $env:CODEX_HOME ?? (Join-Path $home_ '.codex')
$xdgConfig = $env:XDG_CONFIG_HOME ?? (Join-Path $home_ '.config')

# Dropped into every -Mode copy install, read back by -Uninstall. Same name in install.sh, so
# either script can clean up after the other.
$marker = '.installed-from'

# Paths mirror what `npx skills add` writes, so a skill installed that way and one installed from
# a clone land in the same place instead of two competing copies. Codex and OpenCode
# both use .agents/skills at project scope — the dedupe below stops that installing three times.
$targets = @(
  @{ Name = 'claude'; User = Join-Path $home_ '.claude\skills'; Project = '.claude\skills' }
  @{ Name = 'codex'; User = Join-Path $codexHome 'skills'; Project = '.agents\skills' }
  @{ Name = 'opencode'; User = Join-Path $xdgConfig 'opencode\skills'; Project = '.agents\skills' }
  @{ Name = 'agents'; User = Join-Path $home_ '.agents\skills'; Project = '.agents\skills' }
)

if ($Tool -notcontains 'all') {
  $targets = $targets | Where-Object { $Tool -contains $_.Name }
}

$skillDirs = Get-ChildItem $skillsRoot -Directory |
  Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') }
if ($Skill) {
  $skillDirs = $skillDirs | Where-Object { $Skill -contains $_.Name }
  $missing = $Skill | Where-Object { $_ -notin $skillDirs.Name }
  if ($missing) { throw "unknown skill(s): $($missing -join ', ')" }
}
if (-not $skillDirs) { throw 'no skills found' }

$done = 0
$skipped = 0
$seenDest = @{}

foreach ($target in $targets) {
  if ($Scope -eq 'project') {
    $dest = Join-Path $Project $target.Project
  }
  else {
    $dest = $target.User
  }

  # Several agents share a directory (.agents/skills at project scope). Do it once.
  $destKey = $dest.TrimEnd('\', '/').ToLowerInvariant()
  if ($seenDest.ContainsKey($destKey)) {
    Write-Host "skip $($target.Name): same dir as $($seenDest[$destKey])" -ForegroundColor DarkGray
    continue
  }
  $seenDest[$destKey] = $target.Name

  # User scope: only touch a tool that is actually set up, unless -Force.
  if ($Scope -eq 'user' -and -not $Uninstall -and -not $Force) {
    $toolHome = Split-Path -Parent $dest
    if (-not (Test-Path $toolHome)) {
      Write-Host "skip $($target.Name): $toolHome not present (use -Force to create)" -ForegroundColor DarkGray
      continue
    }
  }

  foreach ($skillDir in $skillDirs) {
    $link = Join-Path $dest $skillDir.Name

    if ($Uninstall) {
      if (-not (Test-Path $link)) { continue }
      $item = Get-Item $link -Force
      if ($item.LinkType) {
        # Remove the junction/symlink itself, never its target contents.
        $item.Delete()
      }
      elseif ((Test-Path (Join-Path $link $marker)) -or $Force) {
        # Our own -Mode copy install (marker present), or the user insisted.
        Remove-Item $link -Recurse -Force
      }
      else {
        # A plain directory with no marker may be a skill the user wrote by hand that happens to
        # share the name. Never delete it on the strength of its name alone.
        Write-Warning "kept, not installed by this script (use -Force to delete anyway): $link"
        $skipped++
        continue
      }
      Write-Host "removed  $link" -ForegroundColor Yellow
      $done++
      continue
    }

    New-Item -ItemType Directory -Path $dest -Force | Out-Null

    if (Test-Path $link) {
      $existing = Get-Item $link -Force
      $isOurs = $existing.LinkType -and $existing.Target -and
                (($existing.Target | ForEach-Object { $_.TrimEnd('\') }) -contains $skillDir.FullName.TrimEnd('\'))
      if ($isOurs -and $Mode -eq 'link') {
        Write-Host "ok       $link" -ForegroundColor DarkGray
        $skipped++
        continue
      }
      # A marked copy from an earlier -Mode copy run is also ours — refresh it rather than demanding
      # -Force for a directory this script wrote.
      $markerPath = Join-Path $link $marker
      $isOurCopy = -not $existing.LinkType -and (Test-Path $markerPath) -and
                   ((Get-Content $markerPath -Raw).Trim() -eq $skillDir.FullName)
      if (-not $Force -and -not $isOurCopy) {
        Write-Warning "exists, not overwriting (use -Force): $link"
        $skipped++
        continue
      }
      if ($existing.LinkType) { $existing.Delete() } else { Remove-Item $link -Recurse -Force }
    }

    if ($Mode -eq 'link') {
      # Junction, not SymbolicLink: works without admin rights or Developer Mode.
      New-Item -ItemType Junction -Path $link -Target $skillDir.FullName | Out-Null
      Write-Host "linked   $link" -ForegroundColor Green
    }
    else {
      Copy-Item $skillDir.FullName $link -Recurse
      # Marker so -Uninstall can tell our copy from a skill the user wrote themselves.
      Set-Content -Path (Join-Path $link $marker) -Value $skillDir.FullName -Encoding utf8
      Write-Host "copied   $link" -ForegroundColor Green
    }
    $done++
  }
}

Write-Host ''
if ($Uninstall) { Write-Host "$done removed, $skipped untouched" }
else { Write-Host "$done installed, $skipped skipped" }
if ($done -and -not $Uninstall) {
  Write-Host 'Restart the agent (or start a new session) to pick the skills up.' -ForegroundColor Cyan
}
