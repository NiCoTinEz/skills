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

if (-not (Test-Path -LiteralPath $skillsRoot -PathType Container)) { throw "skills/ not found under $repoRoot" }

function Get-NormalPath([string]$Path) {
  $full = [IO.Path]::GetFullPath($Path)
  $root = [IO.Path]::GetPathRoot($full)
  $current = $root
  $parts = $full.Substring($root.Length) -split '[\\/]'
  foreach ($part in $parts) {
    $candidate = Join-Path $current $part
    if (Test-Path -LiteralPath $candidate) {
      $entry = Get-Item -LiteralPath $candidate -Force
      if ($entry.LinkType -and $entry.PSObject.Methods.Name -contains 'ResolveLinkTarget') {
        $target = $entry.ResolveLinkTarget($true)
        $current = if ($target) { $target.FullName } else { $candidate }
      }
      else { $current = $candidate }
    }
    else { $current = $candidate }
  }
  return [IO.Path]::GetFullPath($current).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
}

function Get-NormalMarkerPath([string]$Path) {
  if ($Path -match '^/mnt/([A-Za-z])/(.*)$') {
    $Path = "$($Matches[1]):\$($Matches[2].Replace('/', '\'))"
  }
  elseif ($Path -match '^/([A-Za-z])/(.*)$') {
    $Path = "$($Matches[1]):\$($Matches[2].Replace('/', '\'))"
  }
  return Get-NormalPath $Path
}

function Test-PathWithin([string]$Path, [string]$Parent) {
  $path_ = Get-NormalPath $Path
  $parent_ = Get-NormalPath $Parent
  return $path_.Equals($parent_, [StringComparison]::OrdinalIgnoreCase) -or
         $path_.StartsWith($parent_ + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)
}

# Unlike Test-Path, this can see a dangling link because it inspects the parent directory entry.
function Get-LiteralEntry([string]$Path) {
  $parent = Split-Path -Parent $Path
  $leaf = Split-Path -Leaf $Path
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) { return $null }
  return Get-ChildItem -LiteralPath $parent -Force |
    Where-Object { $_.Name -eq $leaf } |
    Select-Object -First 1
}

function Test-OwnedLink($Item, [string]$ExpectedSource) {
  if (-not $Item.LinkType -or -not $Item.Target) { return $false }
  foreach ($target in @($Item.Target)) {
    $targetPath = if ([IO.Path]::IsPathRooted($target)) { $target } else { Join-Path $Item.Parent.FullName $target }
    if ((Get-NormalPath $targetPath).Equals((Get-NormalPath $ExpectedSource), [StringComparison]::OrdinalIgnoreCase)) {
      return $true
    }
  }
  return $false
}

function Test-OwnedCopy([string]$Path, [string]$ExpectedSource, [string]$SkillName, [string]$Marker) {
  $markerPath = Join-Path $Path $Marker
  if (-not (Test-Path -LiteralPath $markerPath -PathType Leaf)) { return $false }
  $lines = @(Get-Content -LiteralPath $markerPath)
  if ($lines.Count -gt 0 -and $lines[0] -eq "nicotinez-skills/v1/$SkillName") { return $true }
  try {
    return (Get-NormalMarkerPath ((Get-Content -LiteralPath $markerPath -Raw).Trim())).Equals(
      (Get-NormalPath $ExpectedSource), [StringComparison]::OrdinalIgnoreCase)
  }
  catch { return $false }
}

# Keep the generated SKILL.md files in sync before installing anything.
if (-not $Uninstall) {
  if (Get-Command node -ErrorAction SilentlyContinue) {
    & node (Join-Path $PSScriptRoot 'build.mjs') | Out-Null
  }
  else {
    Write-Warning "node not found — skipping build; skills/*/SKILL.md may be stale"
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

$skillDirs = Get-ChildItem -LiteralPath $skillsRoot -Directory |
  Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') -PathType Leaf }
if ($Skill) {
  $skillDirs = $skillDirs | Where-Object { $Skill -contains $_.Name }
  $missing = $Skill | Where-Object { $_ -notin $skillDirs.Name }
  if ($missing) { throw "unknown skill(s): $($missing -join ', ')" }
}
if (-not $skillDirs) { throw 'no skills found' }

if ($Scope -eq 'project') {
  if ([string]::IsNullOrWhiteSpace($Project) -or -not (Test-Path -LiteralPath $Project -PathType Container)) {
    throw "project root must be an existing directory: $Project"
  }
  $Project = (Resolve-Path -LiteralPath $Project).Path
}

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

  if (Test-PathWithin $dest $skillsRoot) {
    throw "refusing destination inside source skills directory: $dest"
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
    if (-not (Test-Path -LiteralPath $toolHome -PathType Container)) {
      Write-Host "skip $($target.Name): $toolHome not present (use -Force to create)" -ForegroundColor DarkGray
      continue
    }
  }

  foreach ($skillDir in $skillDirs) {
    $link = Join-Path $dest $skillDir.Name

    if ($Uninstall) {
      $item = Get-LiteralEntry $link
      if (-not $item) { continue }
      if ($item.LinkType) {
        if ((Test-OwnedLink $item $skillDir.FullName) -or $Force) {
          # Remove the junction/symlink itself, never its target contents.
          $item.Delete()
        }
        else {
          Write-Warning "kept, link points elsewhere (use -Force to delete anyway): $link"
          $skipped++
          continue
        }
      }
      elseif ((Test-OwnedCopy $link $skillDir.FullName $skillDir.Name $marker) -or $Force) {
        # Our own -Mode copy install (marker present), or the user insisted.
        Remove-Item -LiteralPath $link -Recurse -Force
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

    $existing = Get-LiteralEntry $link
    if ($existing) {
      $isOurLink = Test-OwnedLink $existing $skillDir.FullName
      if ($isOurLink -and $Mode -eq 'link') {
        Write-Host "ok       $link" -ForegroundColor DarkGray
        $skipped++
        continue
      }
      # A marked copy from an earlier -Mode copy run is also ours — refresh it rather than demanding
      # -Force for a directory this script wrote.
      $isOurCopy = -not $existing.LinkType -and (Test-OwnedCopy $link $skillDir.FullName $skillDir.Name $marker)
      if (-not $Force -and -not $isOurCopy -and -not $isOurLink) {
        Write-Warning "exists, not overwriting (use -Force): $link"
        $skipped++
        continue
      }
      if ($existing.LinkType) { $existing.Delete() } else { Remove-Item -LiteralPath $link -Recurse -Force }
    }

    if ($Mode -eq 'link') {
      # Junction, not SymbolicLink: works without admin rights or Developer Mode.
      New-Item -ItemType Junction -Path $link -Target $skillDir.FullName | Out-Null
      Write-Host "linked   $link" -ForegroundColor Green
    }
    else {
      Copy-Item -LiteralPath $skillDir.FullName -Destination $link -Recurse
      # Marker so -Uninstall can tell our copy from a skill the user wrote themselves.
      Set-Content -LiteralPath (Join-Path $link $marker) -Value @("nicotinez-skills/v1/$($skillDir.Name)", $skillDir.FullName) -Encoding utf8
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
