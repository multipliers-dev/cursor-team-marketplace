import { execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

import { afterEach, describe, expect, it } from "vitest";

const REPO_ROOT = join(import.meta.dirname, "..");
const SCRIPT = join(REPO_ROOT, "scripts/generate-engineering-invariants-local.ts");
const PLACEHOLDER = "YOUR_NOTION_DATA_SOURCE_ID";

const cleanupDirs = new Set<string>();

afterEach(() => {
  for (const dir of cleanupDirs) {
    rmSync(dir, { recursive: true, force: true });
  }
  cleanupDirs.clear();
});

function tempFixture(): {
  dir: string;
  templatePath: string;
  configPath: string;
  outPath: string;
} {
  const dir = mkdtempSync(join(tmpdir(), "eng-invariants-gen-"));
  cleanupDirs.add(dir);
  const templatePath = join(dir, "engineering-invariants.md");
  const configPath = join(dir, "engineering-invariants.local.yml");
  const outPath = join(dir, "engineering-invariants.local.md");
  writeFileSync(
    templatePath,
    `# Rules\n\ndata_source_id: "${PLACEHOLDER}"\n`,
    "utf8",
  );
  return { dir, templatePath, configPath, outPath };
}

function runGenerator(env: Record<string, string>): {
  status: number;
  stderr: string;
} {
  try {
    execFileSync("npx", ["tsx", SCRIPT], {
      cwd: REPO_ROOT,
      env: { ...process.env, ...env },
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
    });
    return { status: 0, stderr: "" };
  } catch (error: unknown) {
    const e = error as { status?: number; stderr?: string };
    return { status: e.status ?? 1, stderr: e.stderr ?? "" };
  }
}

describe("generate-engineering-invariants-local", () => {
  it("substitutes the configured destination exactly once", () => {
    const { templatePath, configPath, outPath } = tempFixture();
    const dataSourceId = "822cbc89-7c89-4863-af3a-2fe0cd8ab56e";
    writeFileSync(
      configPath,
      `savepoints_lite:\n  destination:\n    data_source_id: "${dataSourceId}"\n`,
      "utf8",
    );

    const result = runGenerator({
      ENGINEERING_INVARIANTS_TEMPLATE: templatePath,
      ENGINEERING_INVARIANTS_CONFIG: configPath,
      ENGINEERING_INVARIANTS_OUT: outPath,
    });

    expect(result.status).toBe(0);
    const out = readFileSync(outPath, "utf8");
    expect(out).not.toContain(PLACEHOLDER);
    expect(out.match(new RegExp(dataSourceId, "g"))?.length).toBe(1);
  });

  it("exits non-zero when config is missing", () => {
    const { templatePath, outPath } = tempFixture();
    const missingConfig = join(tmpdir(), "eng-invariants-missing-config.yml");

    const result = runGenerator({
      ENGINEERING_INVARIANTS_TEMPLATE: templatePath,
      ENGINEERING_INVARIANTS_CONFIG: missingConfig,
      ENGINEERING_INVARIANTS_OUT: outPath,
    });

    expect(result.status).not.toBe(0);
    expect(result.stderr).toMatch(/Missing/);
  });

  it("exits non-zero when data_source_id is still the placeholder", () => {
    const { templatePath, configPath, outPath } = tempFixture();
    writeFileSync(
      configPath,
      `savepoints_lite:\n  destination:\n    data_source_id: "${PLACEHOLDER}"\n`,
      "utf8",
    );

    const result = runGenerator({
      ENGINEERING_INVARIANTS_TEMPLATE: templatePath,
      ENGINEERING_INVARIANTS_CONFIG: configPath,
      ENGINEERING_INVARIANTS_OUT: outPath,
    });

    expect(result.status).not.toBe(0);
    expect(result.stderr).toMatch(/Set a real/);
  });
});
