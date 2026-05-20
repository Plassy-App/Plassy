#!/usr/bin/env node
/**
 * Lists root package.json scripts grouped by prefix (app:, backend:, …).
 * Usage: bun run help | bun run help app | bun run help backend
 */
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const pkgPath = join(__dirname, "..", "package.json");
const pkg = JSON.parse(readFileSync(pkgPath, "utf8"));
const scripts = pkg.scripts ?? {};
const filterArg = (process.argv[2] ?? "").toLowerCase();

function matchesFilter(key) {
  if (!filterArg) {
    return true;
  }
  const lower = key.toLowerCase();
  const head = lower.split(":")[0] ?? "";
  return (
    head === filterArg ||
    head.startsWith(filterArg) ||
    lower.startsWith(`${filterArg}:`)
  );
}

function groupName(key) {
  if (key === "prepare" || key === "help" || key.startsWith("dev:")) {
    return "Workspace";
  }
  const i = key.indexOf(":");
  if (i === -1) {
    return "Workspace";
  }
  const head = key.slice(0, i);
  if (head === "sonar") {
    return "Sonar";
  }
  return head[0].toUpperCase() + head.slice(1);
}

const groups = new Map();
for (const key of Object.keys(scripts).sort((a, b) => a.localeCompare(b))) {
  if (key === "help") {
    continue;
  }
  if (!matchesFilter(key)) {
    continue;
  }
  const g = groupName(key);
  if (!groups.has(g)) {
    groups.set(g, []);
  }
  groups.get(g).push(key);
}

const order = [
  "Workspace",
  "App",
  "Backend",
  "Contracts",
  "Frontend",
  "Scraper",
  "Sonar",
];

const rest = [...groups.keys()].filter((k) => !order.includes(k)).sort();
const orderedKeys = [...order.filter((k) => groups.has(k)), ...rest];

console.log("Plassy workspace scripts (from repo root)\n");
console.log("  bun run help           — this list");
console.log("  bun run help app       — filter by name\n");

for (const g of orderedKeys) {
  const keys = groups.get(g);
  if (!keys?.length) {
    continue;
  }
  console.log(`— ${g}`);
  const pad = Math.min(48, Math.max(...keys.map((k) => k.length), 12) + 2);
  for (const key of keys) {
    console.log(`  ${key.padEnd(pad)} bun run ${key}`);
  }
  console.log("");
}
