#!/usr/bin/env node
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

import {
  formatPlanIssues,
  loadPlanValidatorConfig,
  validatePlanPaths,
  type SkippedEmptyDiscovery,
  type ValidationProfile,
} from "./lib/plan-validate.js";

function parseArgs(argv: string[]): {
  paths: string[];
  profile: ValidationProfile;
  includeArchive: boolean;
  allowEmpty: boolean;
  repoRoot: string;
} {
  const paths: string[] = [];
  let profile: ValidationProfile = "default";
  let includeArchive = false;
  let allowEmpty = false;
  let repoRoot = process.cwd();

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i]!;
    if (arg === "--profile" && argv[i + 1]) {
      const value = argv[++i]!;
      if (value !== "default" && value !== "template") {
        console.error(`error: unknown profile ${JSON.stringify(value)} (expected default or template)`);
        process.exit(2);
      }
      profile = value;
      continue;
    }
    if (arg === "--include-archive") {
      includeArchive = true;
      continue;
    }
    if (arg === "--allow-empty") {
      allowEmpty = true;
      continue;
    }
    if (arg === "--repo-root" && argv[i + 1]) {
      repoRoot = resolve(argv[++i]!);
      continue;
    }
    if (arg.startsWith("-")) {
      console.error(`error: unknown option ${arg}`);
      process.exit(2);
    }
    paths.push(arg);
  }

  return { paths, profile, includeArchive, allowEmpty, repoRoot };
}

export function formatSkippedEmptyDiscoveryMessage(skip: SkippedEmptyDiscovery): string {
  const globs = skip.plansGlobs.join(", ");
  const excludes = skip.excludeGlobs.join(", ");
  return (
    `skip plan validation: no active plans discovered under ${skip.repoRoot} ` +
    `(plansGlobs: ${globs}; excludeGlobs: ${excludes})`
  );
}

async function main(): Promise<void> {
  const { paths, profile, includeArchive, allowEmpty, repoRoot } = parseArgs(process.argv.slice(2));
  const config = loadPlanValidatorConfig(repoRoot);

  const result = await validatePlanPaths(paths, {
    profile,
    config,
    repoRoot,
    includeArchive,
    allowEmpty,
  });

  if (result.skippedEmptyDiscovery) {
    console.log(formatSkippedEmptyDiscoveryMessage(result.skippedEmptyDiscovery));
    return;
  }

  if (result.issues.length > 0) {
    console.error(formatPlanIssues(result.issues));
    process.exit(1);
  }

  const count = paths.length > 0 ? paths.length : "discovered";
  console.log(`ok plan validation (${count} file(s), profile=${profile})`);
}

const isMain =
  process.argv[1] &&
  resolve(process.argv[1]) === resolve(fileURLToPath(import.meta.url));

if (isMain) {
  main().catch((err) => {
    console.error(err instanceof Error ? err.message : String(err));
    process.exit(2);
  });
}
