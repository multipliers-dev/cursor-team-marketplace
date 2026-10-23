import { copyFileSync, mkdtempSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

import { describe, expect, it } from "vitest";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(here, "..");
const tsCliPath = join(repoRoot, "plugins/team-harness/scripts/validate-plans.ts");
const bundlePath = join(repoRoot, "packages/plan-validator/dist/plan-validator.mjs");
const fixturesDir = join(here, "fixtures", "plan-validate");
const skillTemplatePath = join(
  repoRoot,
  "plugins/team-harness/skills/planning-methodology/_template.plan.md",
);

function runTsCli(args: string[], cwd: string) {
  return spawnSync("npx", ["tsx", tsCliPath, ...args], { cwd, encoding: "utf8", env: process.env });
}

function runPackageCli(args: string[], cwd: string) {
  const isolated = mkdtempSync(join(tmpdir(), "plan-validator-bin-only-"));
  copyFileSync(bundlePath, join(isolated, "plan-validator.mjs"));
  return spawnSync(process.execPath, [join(isolated, "plan-validator.mjs"), ...args], {
    cwd,
    encoding: "utf8",
    env: { ...process.env, NODE_PATH: "" },
  });
}

function stripNpmNoise(text: string): string {
  return text
    .split("\n")
    .filter((line) => {
      const t = line.trim();
      if (!t) return false;
      if (t.startsWith("npm warn")) return false;
      return true;
    })
    .join("\n");
}

function expectParity(args: string[], cwd: string): void {
  const ts = runTsCli(args, cwd);
  const pkg = runPackageCli(args, cwd);
  expect(pkg.status).toBe(ts.status);
  expect(pkg.stdout).toBe(ts.stdout ?? "");
  expect(stripNpmNoise(pkg.stderr ?? "")).toBe(stripNpmNoise(ts.stderr ?? ""));
}

describe("@multipliers-dev/plan-validator dist parity", () => {
  it("matches TS CLI for valid, invalid, template, and allow-empty cases", () => {
    expectParity([join(fixturesDir, "valid-minimal.plan.md")], repoRoot);

    const invalid = join(fixturesDir, "invalid-prompts-missing.plan.md");
    const tsBad = runTsCli([invalid], repoRoot);
    const pkgBad = runPackageCli([invalid], repoRoot);
    expect(pkgBad.status).toBe(1);
    expect(tsBad.status).toBe(1);
    expect(stripNpmNoise(pkgBad.stderr ?? "")).toContain("[prompts.missing]");

    expectParity(["--profile", "template", skillTemplatePath], repoRoot);

    const emptyRoot = mkdtempSync(join(tmpdir(), "plan-validator-empty-"));
    expectParity(["--repo-root", emptyRoot, "--allow-empty"], emptyRoot);
  });

  it("validates caller repo-root only", () => {
    const validSample = readFileSync(join(fixturesDir, "valid-minimal.plan.md"), "utf8");
    const invalidSample = readFileSync(join(fixturesDir, "invalid-prompts-missing.plan.md"), "utf8");
    const caller = mkdtempSync(join(tmpdir(), "plan-validator-caller-"));
    const market = mkdtempSync(join(tmpdir(), "plan-validator-market-"));
    const callerPlan = join(caller, ".cursor/plans/active/ok.plan.md");
    const marketPlan = join(market, ".cursor/plans/active/bad.plan.md");
    mkdirSync(dirname(callerPlan), { recursive: true });
    mkdirSync(dirname(marketPlan), { recursive: true });
    writeFileSync(callerPlan, validSample);
    writeFileSync(marketPlan, invalidSample);

    expect(runPackageCli(["--repo-root", caller, "--allow-empty"], caller).status).toBe(0);
    expect(runPackageCli(["--repo-root", market, "--allow-empty"], market).status).toBe(1);
  });
});
