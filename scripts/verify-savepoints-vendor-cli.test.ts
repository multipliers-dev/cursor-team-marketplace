import { spawnSync } from "node:child_process";
import { existsSync } from "node:fs";
import { join } from "node:path";

import { describe, expect, it } from "vitest";

const REPO_ROOT = join(import.meta.dirname, "..");
const VENDOR_ROOT = join(REPO_ROOT, "plugins/team-harness/vendor/savepoints-lite");
const CLI = join(VENDOR_ROOT, "skills/bin/savepoints-lite-validate.mjs");
const SCHEMA = join(VENDOR_ROOT, "skills/savepoints/schema.json");
const MAPPING = join(VENDOR_ROOT, "skills/savepoints-notion/mapping.json");

function runCli(args: string[]): {
  status: number | null;
  stdout: string;
  stderr: string;
} {
  const result = spawnSync(process.execPath, [CLI, ...args], {
    cwd: REPO_ROOT,
    encoding: "utf8",
  });
  return {
    status: result.status,
    stdout: result.stdout ?? "",
    stderr: result.stderr ?? "",
  };
}

describe("vendored savepoints-lite-validate CLI smoke", () => {
  it("uses the committed vendor install root (not node_modules)", () => {
    expect(existsSync(CLI)).toBe(true);
    expect(existsSync(SCHEMA)).toBe(true);
    expect(existsSync(MAPPING)).toBe(true);
    expect(CLI.includes(`${join("plugins", "team-harness", "vendor", "savepoints-lite")}`)).toBe(
      true,
    );
  });

  it("valid record exits 0 with ok:true when walk-up finds vendor schema/mapping", () => {
    const input = {
      persisted: {
        Name: "marketplace vendor smoke — ok",
        Repository: "multipliers-dev/cursor-team-marketplace",
        Agent: "Composer",
      },
    };
    const result = runCli(["--input", JSON.stringify(input)]);
    expect(result.status).toBe(0);
    expect(JSON.parse(result.stdout)).toEqual({ ok: true, issues: [] });
  });

  it("missing required property exits 1 with missing_persisted_property", () => {
    const input = {
      persisted: {
        Name: "marketplace vendor smoke — missing repository",
        Repository: "",
        Agent: "Composer",
      },
    };
    const result = runCli(["--input", JSON.stringify(input)]);
    expect(result.status).toBe(1);
    const body = JSON.parse(result.stdout) as {
      ok: boolean;
      issues: Array<{ kind: string; field?: string; property?: string }>;
    };
    expect(body.ok).toBe(false);
    expect(body.issues).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          kind: "missing_persisted_property",
          field: "repository",
          property: "Repository",
        }),
      ]),
    );
  });

  it("also accepts explicit --package-root pointing at the vendor tree", () => {
    const input = {
      persisted: {
        Name: "marketplace vendor smoke — package-root",
        Repository: "multipliers-dev/cursor-team-marketplace",
        Agent: "Composer",
      },
    };
    const result = runCli([
      "--package-root",
      VENDOR_ROOT,
      "--input",
      JSON.stringify(input),
    ]);
    expect(result.status).toBe(0);
    expect(JSON.parse(result.stdout).ok).toBe(true);
  });
});
