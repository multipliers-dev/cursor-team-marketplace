import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

import { describe, expect, it } from "vitest";

import {
  discoverPlanFiles,
  validatePlanFile,
  validatePlanPaths,
} from "../plugins/team-harness/scripts/lib/plan-validate.js";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(here, "..");
const fixturesDir = join(here, "fixtures", "plan-validate");
const cliPath = join(repoRoot, "plugins/team-harness/scripts/validate-plans.ts");
const skillTemplatePath = join(
  repoRoot,
  "plugins/team-harness/skills/planning-methodology/_template.plan.md",
);

type ExpectedIssue = { rule: string; line: number };

/** Regression expectations: exact rule ids and source lines per invalid fixture. */
const INVALID_FIXTURE_EXPECTATIONS: Record<string, ExpectedIssue[]> = {
  "invalid-authority-mismatch.plan.md": [
    { rule: "authority.mismatch", line: 20 },
    { rule: "authority.mismatch", line: 20 },
  ],
  "invalid-authority-table-duplicate-conflict.plan.md": [
    { rule: "authority.table.duplicate-row", line: 21 },
    { rule: "authority.mismatch", line: 20 },
    { rule: "authority.mismatch", line: 21 },
    { rule: "authority.mismatch", line: 20 },
    { rule: "authority.mismatch", line: 21 },
  ],
  "invalid-authority-table-duplicate-row.plan.md": [
    { rule: "authority.table.duplicate-row", line: 21 },
  ],
  "invalid-authority-table-missing-row.plan.md": [
    { rule: "authority.table.missing-row", line: 16 },
  ],
  "invalid-authority-table-unknown-todo.plan.md": [
    { rule: "authority.table.unknown-todo", line: 21 },
  ],
  "invalid-authority-table-unrecognized-label.plan.md": [
    { rule: "authority.table.unrecognized-label", line: 20 },
  ],
  "invalid-frontmatter-delimiter.plan.md": [{ rule: "frontmatter.delimiter", line: 1 }],
  "invalid-frontmatter-duplicate-todo-id.plan.md": [{ rule: "frontmatter.todos", line: 1 }],
  "invalid-frontmatter-plan-closure-last.plan.md": [{ rule: "frontmatter.todos", line: 1 }],
  "invalid-frontmatter-schema.plan.md": [
    { rule: "frontmatter.schema", line: 1 },
    { rule: "frontmatter.schema", line: 1 },
  ],
  "invalid-frontmatter-todo-status.plan.md": [{ rule: "frontmatter.todo-status", line: 1 }],
  "invalid-frontmatter-unclosed.plan.md": [{ rule: "frontmatter.delimiter", line: 1 }],
  "invalid-frontmatter-yaml.plan.md": [{ rule: "frontmatter.yaml", line: 1 }],
  "invalid-plan-authority-table.plan.md": [
    { rule: "plan.authority-table", line: 14 },
    { rule: "authority.table.missing-row", line: 14 },
    { rule: "authority.table.missing-row", line: 14 },
  ],
  "invalid-plan-repo-default.plan.md": [{ rule: "plan.repo-default", line: 14 }],
  "invalid-prompts-authority-label.plan.md": [{ rule: "prompts.authority-label", line: 53 }],
  "invalid-prompts-duplicate.plan.md": [{ rule: "prompts.duplicate", line: 60 }],
  "invalid-prompts-fence-missing.plan.md": [{ rule: "prompts.fence-missing", line: 51 }],
  "invalid-prompts-fence-unclosed.plan.md": [{ rule: "prompts.fence-unclosed", line: 66 }],
  "invalid-prompts-labeled-lines.plan.md": [{ rule: "prompts.labeled-lines", line: 53 }],
  "invalid-prompts-missing.plan.md": [{ rule: "prompts.missing", line: 49 }],
  "invalid-prompts-orphan.plan.md": [{ rule: "prompts.orphan", line: 60 }],
  "invalid-prompts-placeholder.plan.md": [{ rule: "prompts.placeholder", line: 53 }],
  "invalid-prompts-section.plan.md": [{ rule: "prompts.section", line: 14 }],
  "invalid-slice-acceptance-list-placeholder.plan.md": [
    { rule: "slice.acceptance", line: 35 },
  ],
  "invalid-slice-acceptance-placeholder.plan.md": [{ rule: "slice.acceptance", line: 35 }],
  // Same four slice.* lines: fence-only-fields keeps metadata inside a fence (fence-awareness regression).
  "invalid-slice-fence-only-fields.plan.md": [
    { rule: "slice.recommended-authority", line: 25 },
    { rule: "slice.rationale", line: 25 },
    { rule: "slice.agent-instruction", line: 25 },
    { rule: "slice.acceptance", line: 25 },
  ],
  // Same four slice.* lines: missing-fields omits labels in the open document (not fenced).
  "invalid-slice-missing-fields.plan.md": [
    { rule: "slice.recommended-authority", line: 25 },
    { rule: "slice.rationale", line: 25 },
    { rule: "slice.agent-instruction", line: 25 },
    { rule: "slice.acceptance", line: 25 },
  ],
  "invalid-slice-missing-authority-no-exemption.plan.md": [
    { rule: "slice.recommended-authority", line: 25 },
    { rule: "slice.acceptance", line: 25 },
  ],
  // Same slice.missing line: "Notes on slice-a" is a substring-only false positive guard.
  "invalid-slice-missing.plan.md": [{ rule: "slice.missing", line: 14 }],
  // Same slice.missing line: "Slice 1 — slice-a prose title" is template-style non-canonical heading.
  "invalid-slice-non-canonical-heading.plan.md": [{ rule: "slice.missing", line: 14 }],
  "invalid-slice-unknown-authority-no-exemption.plan.md": [
    { rule: "slice.authority-label", line: 27 },
    { rule: "slice.acceptance", line: 25 },
  ],
};

const VALID_FIXTURES = [
  "valid-minimal.plan.md",
  "valid-multi-slice.plan.md",
  "valid-single-slice.plan.md",
];

function issueShape(issues: { rule: string; line: number }[]): ExpectedIssue[] {
  return issues.map(({ rule, line }) => ({ rule, line }));
}

function runValidatePlansCli(args: string[]): { status: number | null; stderr: string; stdout: string } {
  const result = spawnSync("npx", ["tsx", cliPath, ...args], {
    cwd: repoRoot,
    encoding: "utf8",
    env: process.env,
  });
  return {
    status: result.status,
    stderr: result.stderr ?? "",
    stdout: result.stdout ?? "",
  };
}

describe("plan-validate fixture corpus (integration)", () => {
  for (const name of VALID_FIXTURES) {
    it(`valid fixture ${name} produces zero issues`, () => {
      const path = join(fixturesDir, name);
      expect(validatePlanFile(path)).toEqual([]);
    });
  }

  for (const [name, expected] of Object.entries(INVALID_FIXTURE_EXPECTATIONS)) {
    it(`invalid fixture ${name} matches expected rules and lines`, () => {
      const path = join(fixturesDir, name);
      const issues = validatePlanFile(path);
      expect(issueShape(issues)).toEqual(expected);
    });
  }

  it("default profile rejects ellipsis placeholders; template profile relaxes them only", () => {
    const acceptancePath = join(fixturesDir, "invalid-slice-acceptance-placeholder.plan.md");
    const promptPath = join(fixturesDir, "invalid-prompts-placeholder.plan.md");

    expect(
      validatePlanFile(acceptancePath, { profile: "default" }).some(
        (i) => i.rule === "slice.acceptance",
      ),
    ).toBe(true);
    expect(validatePlanFile(acceptancePath, { profile: "template" })).toEqual([]);

    expect(
      validatePlanFile(promptPath, { profile: "default" }).some(
        (i) => i.rule === "prompts.placeholder",
      ),
    ).toBe(true);
    expect(validatePlanFile(promptPath, { profile: "template" })).toEqual([]);
  });

  it("skill _template.plan.md passes under --profile template with zero issues", () => {
    expect(validatePlanFile(skillTemplatePath, { profile: "template" })).toEqual([]);
  });

  it("default discovery excludes archive/** and _template.plan.md", async () => {
    const root = mkdtempSync(join(tmpdir(), "plan-validate-discovery-"));
    const validSample = readFileSync(join(fixturesDir, "valid-minimal.plan.md"), "utf8");

    const activePath = join(root, ".cursor/plans/active/ok.plan.md");
    const archivePath = join(root, ".cursor/plans/archive/archived.plan.md");
    const cursorTemplatePath = join(root, ".cursor/plans/_template.plan.md");
    const skillTemplateCopy = join(
      root,
      "plugins/team-harness/skills/planning-methodology/_template.plan.md",
    );

    mkdirSync(dirname(activePath), { recursive: true });
    mkdirSync(dirname(archivePath), { recursive: true });
    mkdirSync(dirname(cursorTemplatePath), { recursive: true });
    mkdirSync(dirname(skillTemplateCopy), { recursive: true });

    writeFileSync(activePath, validSample);
    writeFileSync(archivePath, validSample);
    writeFileSync(cursorTemplatePath, validSample);
    writeFileSync(skillTemplateCopy, validSample);

    const { issues } = await validatePlanPaths([], { repoRoot: root });
    expect(issues).toEqual([]);

    const files = await discoverPlanFiles(root, undefined, false);
    expect(files).toEqual([activePath]);
  });

  it("--include-archive re-includes only the plans archive glob", async () => {
    const root = mkdtempSync(join(tmpdir(), "plan-validate-archive-"));
    const validSample = readFileSync(join(fixturesDir, "valid-minimal.plan.md"), "utf8");

    const activePath = join(root, ".cursor/plans/active/ok.plan.md");
    const archivePath = join(root, ".cursor/plans/archive/archived.plan.md");
    const cursorTemplatePath = join(root, ".cursor/plans/_template.plan.md");

    mkdirSync(dirname(activePath), { recursive: true });
    mkdirSync(dirname(archivePath), { recursive: true });
    mkdirSync(dirname(cursorTemplatePath), { recursive: true });

    writeFileSync(activePath, validSample);
    writeFileSync(archivePath, validSample);
    writeFileSync(cursorTemplatePath, validSample);

    const withoutArchive = await discoverPlanFiles(root, undefined, false);
    expect(withoutArchive).toEqual([activePath]);

    const withArchive = await discoverPlanFiles(root, undefined, true);
    expect(withArchive.sort()).toEqual([activePath, archivePath].sort());
    expect(withArchive).not.toContain(cursorTemplatePath);
  });

  it("CLI --repo-root validates caller tree, not a sibling marketplace checkout", () => {
    const caller = mkdtempSync(join(tmpdir(), "plan-validate-caller-"));
    const market = mkdtempSync(join(tmpdir(), "plan-validate-market-"));
    const validSample = readFileSync(join(fixturesDir, "valid-minimal.plan.md"), "utf8");
    const invalidSample = readFileSync(
      join(fixturesDir, "invalid-prompts-missing.plan.md"),
      "utf8",
    );

    const callerPlan = join(caller, ".cursor/plans/active/ok.plan.md");
    const marketPlan = join(market, ".cursor/plans/active/bad.plan.md");
    mkdirSync(dirname(callerPlan), { recursive: true });
    mkdirSync(dirname(marketPlan), { recursive: true });
    writeFileSync(callerPlan, validSample);
    writeFileSync(marketPlan, invalidSample);

    const callerResult = runValidatePlansCli(["--repo-root", caller, "--allow-empty"]);
    expect(callerResult.status).toBe(0);

    const marketResult = runValidatePlansCli(["--repo-root", market, "--allow-empty"]);
    expect(marketResult.status).toBe(1);
    expect(marketResult.stderr).toContain("[prompts.missing]");
  });

  it("CLI smoke: valid corpus fixture exits 0; invalid fixture exits 1 with rule id", () => {
    const valid = runValidatePlansCli([
      "scripts/fixtures/plan-validate/valid-minimal.plan.md",
    ]);
    expect(valid.status).toBe(0);
    expect(valid.stdout).toContain("ok plan validation");

    const invalid = runValidatePlansCli([
      "scripts/fixtures/plan-validate/invalid-prompts-missing.plan.md",
    ]);
    expect(invalid.status).toBe(1);
    expect(invalid.stderr).toContain("[prompts.missing]");
  });

  describe("CLI --allow-empty (discovery only)", () => {
    const validSample = readFileSync(join(fixturesDir, "valid-minimal.plan.md"), "utf8");
    const invalidSample = readFileSync(
      join(fixturesDir, "invalid-prompts-missing.plan.md"),
      "utf8",
    );

    function planAt(root: string, rel: string, content: string): string {
      const path = join(root, rel);
      mkdirSync(dirname(path), { recursive: true });
      writeFileSync(path, content);
      return path;
    }

    it("(a) empty discovery + --allow-empty → exit 0 + skip message", () => {
      const root = mkdtempSync(join(tmpdir(), "plan-validate-allow-empty-a-"));
      const result = runValidatePlansCli(["--repo-root", root, "--allow-empty"]);
      expect(result.status).toBe(0);
      expect(result.stdout).toContain("skip plan validation: no active plans discovered");
      expect(result.stdout).toContain(root);
      expect(result.stdout).toContain("plansGlobs:");
      expect(result.stdout).toContain("excludeGlobs:");
    });

    it("(b) empty discovery without flag → exit 1 discovery.empty", () => {
      const root = mkdtempSync(join(tmpdir(), "plan-validate-allow-empty-b-"));
      const result = runValidatePlansCli(["--repo-root", root]);
      expect(result.status).toBe(1);
      expect(result.stderr).toContain("[discovery.empty]");
    });

    it("(c) discovery with a valid plan + --allow-empty → exit 0", () => {
      const root = mkdtempSync(join(tmpdir(), "plan-validate-allow-empty-c-"));
      planAt(root, ".cursor/plans/active/ok.plan.md", validSample);
      const result = runValidatePlansCli(["--repo-root", root, "--allow-empty"]);
      expect(result.status).toBe(0);
      expect(result.stdout).toContain("ok plan validation");
    });

    it("(d) discovery with an invalid plan + --allow-empty → exit 1 with the rule", () => {
      const root = mkdtempSync(join(tmpdir(), "plan-validate-allow-empty-d-"));
      planAt(root, ".cursor/plans/active/bad.plan.md", invalidSample);
      const result = runValidatePlansCli(["--repo-root", root, "--allow-empty"]);
      expect(result.status).toBe(1);
      expect(result.stderr).toContain("[prompts.missing]");
    });

    it("(e) explicit missing path + --allow-empty → exit 1 io.not-found", () => {
      const root = mkdtempSync(join(tmpdir(), "plan-validate-allow-empty-e-"));
      const result = runValidatePlansCli([
        "--repo-root",
        root,
        "--allow-empty",
        "missing-plan.plan.md",
      ]);
      expect(result.status).toBe(1);
      expect(result.stderr).toContain("[io.not-found]");
    });

    it("(f) invalid config + --allow-empty → failure", () => {
      const root = mkdtempSync(join(tmpdir(), "plan-validate-allow-empty-f-"));
      const configPath = join(root, ".cursor/plan-validator.json");
      mkdirSync(dirname(configPath), { recursive: true });
      writeFileSync(configPath, "{ not-json");
      const result = runValidatePlansCli(["--repo-root", root, "--allow-empty"]);
      expect(result.status).not.toBe(0);
      expect(result.status).not.toBe(1);
    });

    it("(g) archive-only tree + --allow-empty → skip (exit 0)", () => {
      const root = mkdtempSync(join(tmpdir(), "plan-validate-allow-empty-g-"));
      planAt(root, ".cursor/plans/archive/archived.plan.md", validSample);
      const result = runValidatePlansCli(["--repo-root", root, "--allow-empty"]);
      expect(result.status).toBe(0);
      expect(result.stdout).toContain("skip plan validation: no active plans discovered");
    });
  });
});
