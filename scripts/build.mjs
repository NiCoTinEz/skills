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

const SETS = [
  {
    name: "git-flow",
    source: "shared/git-flow/workflow.md",
    target: "references/workflow.md",
    skills: [
      "branch-commit-push-pr",
      "branch-commit-push",
      "branch-commit",
      "commit-push-pr",
      "commit-push",
    ],
  },
];

const BANNER = (source) =>
  `<!-- generated from ${source} — edit that file, then run: npm run build -->\n\n`;

const check = process.argv.includes("--check");
let stale = 0;
let written = 0;

for (const set of SETS) {
  const sourcePath = join(ROOT, set.source);
  if (!existsSync(sourcePath)) {
    console.error(`missing source: ${set.source}`);
    process.exit(1);
  }
  const body = BANNER(set.source) + readFileSync(sourcePath, "utf8");

  for (const skill of set.skills) {
    const skillDir = join(ROOT, "skills", skill);
    if (!existsSync(join(skillDir, "SKILL.md"))) {
      console.error(`missing skill: skills/${skill}/SKILL.md`);
      process.exit(1);
    }
    const outPath = join(skillDir, set.target);
    const current = existsSync(outPath) ? readFileSync(outPath, "utf8") : null;
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

// --- manifest consistency -----------------------------------------------------------------
// The plugin install path ships exactly what plugin.json lists, so a skill missing from that
// array is invisible there even though `npx skills add` finds it. Names must also agree across
// plugin.json and the marketplace entry, or `/plugin install <name>@<marketplace>` won't resolve.
const problems = [];

const onDisk = readdirSync(join(ROOT, "skills"), { withFileTypes: true })
  .filter((e) => e.isDirectory() && existsSync(join(ROOT, "skills", e.name, "SKILL.md")))
  .map((e) => e.name)
  .sort();

const plugin = JSON.parse(readFileSync(join(ROOT, ".claude-plugin/plugin.json"), "utf8"));
const listed = (plugin.skills ?? []).map((p) => p.replace(/^\.\/skills\//, "")).sort();

for (const name of onDisk) {
  if (!listed.includes(name)) problems.push(`plugin.json "skills" is missing "./skills/${name}"`);
  if (!existsSync(join(ROOT, "skills", name, "agents/openai.yaml"))) {
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
