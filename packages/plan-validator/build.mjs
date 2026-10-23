import { mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import * as esbuild from "esbuild";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "../..");
const entry = resolve(repoRoot, "plugins/team-harness/scripts/validate-plans.ts");
const outfile = resolve(here, "dist/plan-validator.mjs");

const generatedBanner = `/*!
 * GENERATED FILE — DO NOT EDIT.
 * Source: plugins/team-harness/scripts/validate-plans.ts (bundles lib/plan-validate.ts and yaml).
 * Rebuild: npm run build --workspace @multipliers-dev/plan-validator
 */`;

const esmRequireShim =
  "import { createRequire as __createRequire } from 'node:module';" +
  "const require = __createRequire(import.meta.url);";

mkdirSync(dirname(outfile), { recursive: true });

await esbuild.build({
  entryPoints: [entry],
  bundle: true,
  platform: "node",
  format: "esm",
  target: ["node22"],
  outfile,
  banner: { js: `${generatedBanner}\n${esmRequireShim}` },
  legalComments: "none",
  minify: false,
  sourcemap: false,
  charset: "utf8",
  logLevel: "info",
});

console.log(`ok built ${outfile}`);
