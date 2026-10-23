import { copyFileSync, mkdtempSync, mkdirSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

import { describe, expect, it } from "vitest";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(here, "..");
const tsCliPath = join(repoRoot, "plugins/team-harness/scripts/validate-plans.ts");
const bundleSourcePath = join(repoRoot, "plugins/team-harness/dist/validate-plans.mjs");
const fixturesDir = join(here, "fixtures", "plan-validate");
const skillTemplatePath = join(
  repoRoot,
  "plugins/team-harness/skills/planning-methodology/_template.plan.md",
);

function runTsCli(args: string[], cwd: string): { status: number | null; stderr: string; stdout: string } {
  const result = spawnSync("npx", ["tsx", tsCliPath, ...args], {
    cwd,
    encoding: "utf8",
    env: process.env,
  });
  return {
    status: result.status,
    stderr: result.stderr ?? "",
    stdout: result.stdout ?? "",
  };
}

function stripNpmCliNoise(text: string): string {
  return text
    .split("\n")
    .filter((line) => {
      const trimmed = line.trim();
      if (!trimmed) return false;
      if (trimmed.startsWith("npm warn")) return false;
      if (trimmed.startsWith("npm notice")) return false;
      return true;
    })
    .join("\n");
}

function runBundledCli(args: string[], cwd: string): { status: number | null; stderr: string; stdout: string } {
  const isolated = mkdtempSync(join(tmpdir(), "plan-validate-bundle-only-"));
  const bundlePath = join(isolated, "validate-plans.mjs");
  copyFileSync(bundleSourcePath, bundlePath);
  const result = spawnSync(process.execPath, [bundlePath, ...args], {
    cwd,
    encoding: "utf8",
    env: {
      ...process.env,
      NODE_PATH: "",
      npm_config_prefix: "",
    },
  });
  return {
    status: result.status,
    stderr: result.stderr ?? "",
    stdout: result.stdout ?? "",
  };
}

function expectParity(args: string[], cwd: string): void {
  const ts = runTsCli(args, cwd);
  const bundle = runBundledCli(args, cwd);
  expect(bundle.status).toBe(ts.status);
  expect(bundle.stdout).toBe(ts.stdout);
  expect(stripNpmCliNoise(bundle.stderr)).toBe(stripNpmCliNoise(ts.stderr));
}

describe("validate-plans bundled CLI parity (isolated .mjs, no node_modules)", () => {
  it("matches TS CLI for valid fixture path", () => {
    const fixture = join(fixturesDir, "valid-minimal.plan.md");
    expectParity([fixture], repoRoot);
  });

  it("matches TS CLI for invalid fixture (diagnostics + exit 1)", () => {
    const fixture = join(fixturesDir, "invalid-prompts-missing.plan.md");
    const ts = runTsCli([fixture], repoRoot);
    const bundle = runBundledCli([fixture], repoRoot);
    expect(bundle.status).toBe(1);
    expect(ts.status).toBe(1);
    expect(stripNpmCliNoise(bundle.stderr)).toBe(stripNpmCliNoise(ts.stderr));
    expect(bundle.stderr).toContain("[prompts.missing]");
  });

  it("matches TS CLI for template profile on skill template", () => {
    expectParity(["--profile", "template", skillTemplatePath], repoRoot);
  });

  it("matches TS CLI for empty discovery with --allow-empty in temp repo", () => {
    const root = mkdtempSync(join(tmpdir(), "plan-validate-bundle-empty-"));
    expectParity(["--repo-root", root, "--allow-empty"], root);
  });

  it("matches TS CLI for invalid plan under --repo-root in temp repo", () => {
    const root = mkdtempSync(join(tmpdir(), "plan-validate-bundle-bad-"));
    const planPath = join(root, ".cursor/plans/active/bad.plan.md");
    mkdirSync(dirname(planPath), { recursive: true });
    writeFileSync(planPath, "---\nname: x\noverview: x\ntodos:\n  - id: a\n    content: a\n    status: pending\nisProject: false\n---\n# X\n");
    const ts = runTsCli(["--repo-root", root, "--allow-empty"], root);
    const bundle = runBundledCli(["--repo-root", root, "--allow-empty"], root);
    expect(bundle.status).toBe(ts.status);
    expect(stripNpmCliNoise(bundle.stderr)).toBe(stripNpmCliNoise(ts.stderr));
  });
});
