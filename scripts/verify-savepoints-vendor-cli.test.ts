import { spawnSync } from "node:child_process";
import { existsSync } from "node:fs";
import { join } from "node:path";

import { describe, expect, it } from "vitest";

const REPO_ROOT = join(import.meta.dirname, "..");
const VENDOR_ROOT = join(REPO_ROOT, "plugins/team-harness/vendor/savepoints-lite");
const CLI = join(VENDOR_ROOT, "skills/bin/savepoints-lite-validate.mjs");
const SCHEMA = join(VENDOR_ROOT, "skills/savepoints/schema.json");
const MAPPING = join(VENDOR_ROOT, "skills/savepoints-notion/mapping.json");

function runCli(
  args: string[],
  stdin?: string,
): {
  status: number | null;
  stdout: string;
  stderr: string;
} {
  const result = spawnSync(process.execPath, [CLI, ...args], {
    cwd: REPO_ROOT,
    encoding: "utf8",
    // Piped stdin (never a TTY) exercises implicit-stdin behavior; omitted means an empty pipe.
    input: stdin ?? "",
    timeout: 15_000,
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

  describe("implicit stdin and notion-fetch input (2.2.0)", () => {
    const properties = (repository: string): string =>
      JSON.stringify({
        Name: "marketplace vendor smoke — implicit stdin",
        Repository: repository,
        Agent: "Composer",
      });
    const propertiesBlock = (repository: string): string =>
      `<properties>\n${properties(repository)}\n</properties>`;
    const envelope = (repository: string): string =>
      JSON.stringify({
        title: "marketplace vendor smoke — implicit stdin",
        url: "https://www.notion.so/00000000000000000000000000000000",
        text: `Here is the result of "view" for the Page.\n${propertiesBlock(repository)}\n<content>\nbody\n</content>`,
      });

    it("reads structured JSON from piped stdin with no flag (exit 0)", () => {
      const result = runCli(
        [],
        JSON.stringify({
          persisted: JSON.parse(properties("multipliers-dev/cursor-team-marketplace")),
        }),
      );
      expect(result.status).toBe(0);
      expect(JSON.parse(result.stdout)).toEqual({ ok: true, issues: [] });
    });

    it("reports missing_persisted_property from implicit stdin (exit 1)", () => {
      const result = runCli(
        [],
        JSON.stringify({ persisted: JSON.parse(properties("")) }),
      );
      expect(result.status).toBe(1);
      expect(JSON.parse(result.stdout).issues).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ kind: "missing_persisted_property", property: "Repository" }),
        ]),
      );
    });

    it("accepts a notion-fetch envelope on implicit stdin (exit 0)", () => {
      const result = runCli([], envelope("multipliers-dev/cursor-team-marketplace"));
      expect(result.status).toBe(0);
      expect(JSON.parse(result.stdout)).toEqual({ ok: true, issues: [] });
    });

    it("accepts a notion-fetch envelope via --stdin and a raw <properties> block", () => {
      const repo = "multipliers-dev/cursor-team-marketplace";
      expect(runCli(["--stdin"], envelope(repo)).status).toBe(0);
      expect(runCli([], propertiesBlock(repo)).status).toBe(0);
    });

    it("reports a bare repository as an advisory warning, not an issue (exit 0)", () => {
      const result = runCli([], envelope("resumes"));
      expect(result.status).toBe(0);
      const body = JSON.parse(result.stdout) as {
        ok: boolean;
        issues: unknown[];
        warnings?: Array<{ kind: string }>;
      };
      expect(body.ok).toBe(true);
      expect(body.issues).toEqual([]);
      expect(body.warnings).toEqual([expect.objectContaining({ kind: "repository_format" })]);
    });

    it("exits 2 for empty stdin and for an envelope with no properties block", () => {
      expect(runCli([]).status).toBe(2);
      expect(runCli([], JSON.stringify({ text: "no block here" })).status).toBe(2);
    });
  });
});
