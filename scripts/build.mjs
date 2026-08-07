#!/usr/bin/env node
// Copies each shared reference into every skill that declares it, so a skill folder is
// self-contained and portable across Claude Code / Codex / OpenCode. Also checks the manifests
// agree with what's on disk.
//
//   npm run build    build
//   npm run check    verify committed copies are current and manifests consistent (exit 1 if not)
//
// Add a set: extend SETS below. Sources live in shared/<set>/, and land in
// skills/<skill>/references/<file> for each listed skill.

import { readFileSync, writeFileSync, mkdirSync, existsSync, readdirSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");

// One set per stage, so a skill carries only the stages it runs. `commit` reads core + commit and
// nothing about pushing or pull requests; the monolithic reference it replaced cost every skill the
// whole procedure. Membership here IS the stage list in each SKILL.md — keep the two in step, and
// `npm run check` will catch it if you don't (a cited reference that isn't installed fails, and so
// does an installed one the skill never cites).
const SETS = [
  {
    name: "git-flow-core",
    source: "shared/git-flow/core.md",
    target: "references/core.md",
    skills: [
      "branch-commit-push-pr",
      "branch-commit-push",
      "branch-commit",
      "commit-push-pr",
      "commit-push",
      "commit",
      "push-pr",
      "branch",
      "push",
      "pr",
      "sync-base",
    ],
  },
  {
    name: "git-flow-branch",
    source: "shared/git-flow/branch.md",
    target: "references/branch.md",
    skills: ["branch-commit-push-pr", "branch-commit-push", "branch-commit", "branch"],
  },
  {
    name: "git-flow-commit",
    source: "shared/git-flow/commit.md",
    target: "references/commit.md",
    skills: [
      "branch-commit-push-pr",
      "branch-commit-push",
      "branch-commit",
      "commit-push-pr",
      "commit-push",
      "commit",
    ],
  },
  {
    name: "git-flow-push",
    source: "shared/git-flow/push.md",
    target: "references/push.md",
    skills: [
      "branch-commit-push-pr",
      "branch-commit-push",
      "commit-push-pr",
      "commit-push",
      "push-pr",
      "push",
    ],
  },
  {
    name: "git-flow-pr",
    source: "shared/git-flow/pr.md",
    target: "references/pr.md",
    skills: ["branch-commit-push-pr", "commit-push-pr", "push-pr", "pr"],
  },
];

const BANNER = (source) =>
  `<!-- generated from ${source} — edit that file, then run: npm run build -->\n\n`;

// Compare and write LF, whatever the working tree holds. `.gitattributes` pins *.md to eol=lf, but
// a checkout made under core.autocrlf=true before that yields CRLF sources — and a byte compare
// then calls every copy stale forever, because the banner is LF while the body is CRLF and
// committing the mix normalises it straight back.
const norm = (s) => s.replace(/\r\n/g, "\n");

const check = process.argv.includes("--check");
let stale = 0;
let written = 0;
// skill -> targets this build owns, so a left-over file from a renamed source can be spotted.
const generated = new Map();

for (const set of SETS) {
  const sourcePath = join(ROOT, set.source);
  if (!existsSync(sourcePath)) {
    console.error(`missing source: ${set.source}`);
    process.exit(1);
  }
  const body = norm(BANNER(set.source) + readFileSync(sourcePath, "utf8"));

  for (const skill of set.skills) {
    const skillDir = join(ROOT, "skills", skill);
    if (!existsSync(join(skillDir, "SKILL.md"))) {
      console.error(`missing skill: skills/${skill}/SKILL.md`);
      process.exit(1);
    }
    if (!generated.has(skill)) generated.set(skill, new Set());
    generated.get(skill).add(set.target);

    const outPath = join(skillDir, set.target);
    const current = existsSync(outPath) ? norm(readFileSync(outPath, "utf8")) : null;
    if (current === body) continue;

    if (check) {
      console.error(`stale: skills/${skill}/${set.target}`);
      stale++;
      continue;
    }
    mkdirSync(dirname(outPath), { recursive: true });
    writeFileSync(outPath, body);
    console.log(`wrote skills/${skill}/${set.target}`);
    written++;
  }
}

// --- manifest + skill folder consistency ---------------------------------------------------
// The plugin install path ships exactly what plugin.json lists, so a skill missing from that
// array is invisible there even though `npx skills add` finds it. Names must also agree across
// plugin.json and the marketplace entry, or `/plugin install <name>@<marketplace>` won't resolve.
// The per-skill checks below cover the AGENTS.md invariants a reviewer can't see at a glance:
// frontmatter name == folder name, a description exists, no root SKILL.md, and references/
// holding exactly the files SETS produces — no dangling citation, no orphan left by a rename.
const problems = [];

const onDisk = readdirSync(join(ROOT, "skills"), { withFileTypes: true })
  .filter((e) => e.isDirectory() && existsSync(join(ROOT, "skills", e.name, "SKILL.md")))
  .map((e) => e.name)
  .sort();

const plugin = JSON.parse(readFileSync(join(ROOT, ".claude-plugin/plugin.json"), "utf8"));
const listed = (plugin.skills ?? []).map((p) => p.replace(/^\.\/skills\//, "")).sort();

// `npx skills add` searches shallowest-first, so a root SKILL.md shadows everything under skills/.
if (existsSync(join(ROOT, "SKILL.md"))) {
  problems.push("root SKILL.md exists — it shadows every skill under skills/ for `npx skills add`; delete it");
}

// Enough of a YAML reader for the two keys every tool reads. Handles `key: value` and the
// `key: >` block scalar the descriptions use.
function frontmatter(text) {
  const match = /^---\r?\n([\s\S]*?)\r?\n---/.exec(text);
  if (!match) return null;
  const out = {};
  let key = null;
  for (const line of match[1].split(/\r?\n/)) {
    const kv = /^([A-Za-z][\w-]*):[ \t]*(.*)$/.exec(line);
    if (kv) {
      key = kv[1];
      const value = kv[2].trim();
      out[key] = /^[|>][-+]?$/.test(value) ? "" : value;
    } else if (key && /^[ \t]+\S/.test(line)) {
      out[key] = `${out[key]} ${line.trim()}`.trim();
    }
  }
  return out;
}

for (const name of onDisk) {
  const skillDir = join(ROOT, "skills", name);
  const text = readFileSync(join(skillDir, "SKILL.md"), "utf8");
  const fm = frontmatter(text);

  if (!fm) {
    problems.push(`skills/${name}/SKILL.md has no --- frontmatter block`);
  } else {
    // The ecosystem CLI keys off `name`, so a mismatch installs the folder under one name while
    // tools route on the other.
    if (fm.name !== name) {
      problems.push(`skills/${name}/SKILL.md frontmatter name "${fm.name ?? ""}" != folder name "${name}"`);
    }
    if (!fm.description) {
      problems.push(`skills/${name}/SKILL.md has no description — the only routing signal a tool sees`);
    }
  }

  // Self-containment: every references/… path a skill cites has to exist inside its own folder.
  for (const ref of new Set(text.match(/references\/[\w.-]+\.md/g) ?? [])) {
    if (!existsSync(join(skillDir, ref))) {
      problems.push(`skills/${name}/SKILL.md cites ${ref}, which does not exist — register the set in SETS, then: npm run build`);
    }
  }

  // The reverse: a generated file no set produces any more, e.g. after a shared source was renamed.
  const refDir = join(skillDir, "references");
  if (existsSync(refDir)) {
    const owned = generated.get(name) ?? new Set();
    for (const entry of readdirSync(refDir)) {
      if (!owned.has(`references/${entry}`)) {
        problems.push(`skills/${name}/references/${entry} is produced by no set in SETS — delete it, or register the set`);
      }
    }
  }

  if (!listed.includes(name)) problems.push(`plugin.json "skills" is missing "./skills/${name}"`);
  if (!existsSync(join(skillDir, "agents/openai.yaml"))) {
    problems.push(`skills/${name}/agents/openai.yaml missing (Codex display metadata)`);
  }
}
for (const name of listed) {
  if (!onDisk.includes(name)) problems.push(`plugin.json lists "./skills/${name}", which has no SKILL.md`);
}

const pkg = JSON.parse(readFileSync(join(ROOT, "package.json"), "utf8"));
if (pkg.version !== plugin.version) {
  problems.push(`package.json version "${pkg.version}" != plugin.json version "${plugin.version}"`);
}

const market = JSON.parse(readFileSync(join(ROOT, ".claude-plugin/marketplace.json"), "utf8"));
const entry = (market.plugins ?? []).find((p) => p.source === "./");
if (!entry) problems.push('marketplace.json has no plugin entry with "source": "./"');
else if (entry.name !== plugin.name) {
  problems.push(
    `marketplace plugin name "${entry.name}" != plugin.json name "${plugin.name}" — ` +
      `/plugin install would not resolve`
  );
}

for (const p of problems) console.error(`manifest: ${p}`);

if (check) {
  if (stale) console.error(`\n${stale} file(s) stale — run: node scripts/build.mjs`);
  if (stale || problems.length) process.exit(1);
  console.log("all generated references current, manifests consistent");
} else {
  console.log(written ? `\n${written} file(s) written` : "already up to date");
  if (problems.length) process.exit(1);
}
