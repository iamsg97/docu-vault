#!/usr/bin/env node
// Copies every .env.example → .env (skips if .env already exists).
// Run via: pnpm env:init

import { readdirSync, copyFileSync, existsSync, statSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(fileURLToPath(import.meta.url), "..", "..");
const SKIP_DIRS = new Set(["node_modules", ".git", "dist", ".next", ".turbo"]);

const RESET = "\x1b[0m";
const GREEN = "\x1b[32m";
const YELLOW = "\x1b[33m";
const CYAN = "\x1b[36m";

function* findEnvExamples(dir) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (entry.isDirectory()) {
      if (!SKIP_DIRS.has(entry.name)) yield* findEnvExamples(join(dir, entry.name));
    } else if (entry.name === ".env.example") {
      yield join(dir, entry.name);
    }
  }
}

let created = 0;
let skipped = 0;

for (const examplePath of findEnvExamples(ROOT)) {
  const envPath = join(dirname(examplePath), ".env");
  const rel = examplePath.replace(ROOT + "/", "");

  if (existsSync(envPath)) {
    console.log(`${YELLOW}skip${RESET}    ${rel} → .env already exists`);
    skipped++;
  } else {
    copyFileSync(examplePath, envPath);
    console.log(`${GREEN}created${RESET}  ${rel.replace(".env.example", ".env")}`);
    created++;
  }
}

console.log(`\n${CYAN}Done.${RESET} ${created} created, ${skipped} skipped.`);
