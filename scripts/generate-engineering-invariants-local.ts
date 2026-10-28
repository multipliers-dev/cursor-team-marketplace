import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { parse } from "yaml";

const repoRoot = join(dirname(fileURLToPath(import.meta.url)), "..");
const templatePath =
  process.env.ENGINEERING_INVARIANTS_TEMPLATE ??
  join(repoRoot, "docs/engineering-invariants.md");
const configPath =
  process.env.ENGINEERING_INVARIANTS_CONFIG ??
  join(repoRoot, "docs/engineering-invariants.local.yml");
const examplePath = join(repoRoot, "docs/engineering-invariants.local.example.yml");
const outPath =
  process.env.ENGINEERING_INVARIANTS_OUT ??
  join(repoRoot, "docs/engineering-invariants.local.md");

const PLACEHOLDER = "YOUR_NOTION_DATA_SOURCE_ID";

type LocalConfig = {
  savepoints_lite?: { destination?: { data_source_id?: string } };
};

function fail(message: string): never {
  console.error(message);
  process.exit(1);
}

if (!existsSync(configPath)) {
  fail(
    `Missing ${configPath}\nCopy ${examplePath} to engineering-invariants.local.yml and set data_source_id.`,
  );
}

const config = parse(readFileSync(configPath, "utf8")) as LocalConfig;
const dataSourceId = config.savepoints_lite?.destination?.data_source_id?.trim();

if (!dataSourceId || dataSourceId === PLACEHOLDER) {
  fail(
    `Set a real savepoints_lite.destination.data_source_id in ${configPath}`,
  );
}

const template = readFileSync(templatePath, "utf8");
if (!template.includes(PLACEHOLDER)) {
  fail(
    `${templatePath} no longer contains ${PLACEHOLDER}; update the generator or template.`,
  );
}

writeFileSync(
  outPath,
  template.replaceAll(PLACEHOLDER, dataSourceId),
  "utf8",
);
console.log(`Wrote ${outPath}`);
