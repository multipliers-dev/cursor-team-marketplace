import { execFileSync } from "node:child_process";
import {
  chmodSync,
  cpSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { dirname, join } from "node:path";

import { describe, expect, it } from "vitest";

const REPO_ROOT = join(import.meta.dirname, "..");
const SCRIPT = join(REPO_ROOT, "scripts/verify-savepoints-marketplace-layout.sh");
const REPO_PLUGIN = join(REPO_ROOT, "plugins/team-harness");

function runLayoutVerify(options: {
  cacheRoot?: string;
  env?: Record<string, string>;
}): { stdout: string; stderr: string; status: number } {
  const env: Record<string, string> = {
    ...process.env,
    ...options.env,
  };
  if (options.cacheRoot !== undefined) {
    env.SAVEPOINTS_PLUGIN_CACHE_ROOT = options.cacheRoot;
  }
  try {
    const stdout = execFileSync("sh", [SCRIPT], {
      cwd: REPO_ROOT,
      env,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
    });
    return { stdout, stderr: "", status: 0 };
  } catch (error: unknown) {
    const e = error as { status?: number; stdout?: string; stderr?: string };
    return {
      stdout: e.stdout ?? "",
      stderr: e.stderr ?? "",
      status: e.status ?? 1,
    };
  }
}

function installCacheCopy(cacheRoot: string, hash: string, mutate?: (pluginRoot: string) => void): string {
  const pluginRoot = join(
    cacheRoot,
    "multipliers-dev-cursor-team-marketplace",
    "team-harness",
    hash,
  );
  const paths = [
    "skills/savepoints/SKILL.md",
    "vendor/savepoints-lite/skills/savepoints/SKILL.md",
    "vendor/savepoints-lite/skills/savepoints-notion/SKILL.md",
    ".cursor-plugin/plugin.json",
  ];
  for (const rel of paths) {
    const dest = join(pluginRoot, rel);
    mkdirSync(join(dest, ".."), { recursive: true });
    cpSync(join(REPO_PLUGIN, rel), dest);
  }
  mutate?.(pluginRoot);
  return pluginRoot;
}

function tempCacheRoot(prefix: string): string {
  return mkdtempSync(join(REPO_ROOT, `.vitest-${prefix}`));
}

describe("verify-savepoints-marketplace-layout installed-cache discovery", () => {
  it("verifies a valid nested cache installation at the expected version", () => {
    const cacheRoot = tempCacheRoot("savepoints-cache-valid-");
    const pluginRoot = installCacheCopy(cacheRoot, "abc123deadbeef");

    const result = runLayoutVerify({ cacheRoot });
    expect(result.status).toBe(0);
    expect(result.stdout).toContain(`ok (repo + installed cache`);
    expect(result.stdout).toContain(pluginRoot);

    rmSync(cacheRoot, { recursive: true, force: true });
  });

  it("reports no installation when the cache root is empty", () => {
    const cacheRoot = tempCacheRoot("savepoints-cache-missing-");

    const result = runLayoutVerify({ cacheRoot });
    expect(result.status).toBe(0);
    expect(result.stdout).toContain("ok (repo layout)");
    expect(result.stdout).toContain("installed-cache verification not run");
    expect(result.stdout).toContain("no team-harness savepoints wrapper");

    rmSync(cacheRoot, { recursive: true, force: true });
  });

  it("ignores outdated installations and reports refresh guidance", () => {
    const cacheRoot = tempCacheRoot("savepoints-cache-outdated-");
    installCacheCopy(cacheRoot, "oldhash111111111111111111111111", (pluginRoot) => {
      const overlay = join(pluginRoot, ".cursor-plugin", "plugin.json");
      const pkg = JSON.parse(readFileSync(overlay, "utf8")) as { version: string };
      pkg.version = "1.0.0";
      writeFileSync(overlay, JSON.stringify(pkg, null, 2));
    });

    const result = runLayoutVerify({ cacheRoot });
    expect(result.status).toBe(0);
    expect(result.stdout).toContain("ok (repo layout)");
    expect(result.stdout).toContain("team-harness cache found but none at version");

    rmSync(cacheRoot, { recursive: true, force: true });
  });

  it("fails when a matching-version cache installation is incomplete", () => {
    const cacheRoot = tempCacheRoot("savepoints-cache-invalid-");
    installCacheCopy(cacheRoot, "badhash222222222222222222222222", (pluginRoot) => {
      const wrapper = join(pluginRoot, "skills/savepoints/SKILL.md");
      writeFileSync(wrapper, "# broken wrapper\n", "utf8");
    });

    const result = runLayoutVerify({ cacheRoot });
    expect(result.status).toBe(1);
    expect(result.stderr).toContain("installed-cache");

    rmSync(cacheRoot, { recursive: true, force: true });
  });

  it("discovers installations without ripgrep on PATH", () => {
    const cacheRoot = tempCacheRoot("savepoints-cache-no-rg-");
    const pluginRoot = installCacheCopy(cacheRoot, "norghash3333333333333333333333");

    const fakeBin = tempCacheRoot("savepoints-fake-bin-");
    writeFileSync(
      join(fakeBin, "rg"),
      "#!/bin/sh\necho 'verify-savepoints-marketplace-layout: rg must not be used' >&2\nexit 99\n",
      "utf8",
    );
    chmodSync(join(fakeBin, "rg"), 0o755);

    const pathWithoutRealRg = [
      fakeBin,
      dirname(process.execPath),
      "/usr/bin",
      "/bin",
      "/usr/sbin",
      "/sbin",
    ].join(":");
    const result = runLayoutVerify({
      cacheRoot,
      env: { PATH: pathWithoutRealRg },
    });
    expect(result.status).toBe(0);
    expect(result.stdout).toContain(`ok (repo + installed cache`);
    expect(result.stdout).toContain(pluginRoot);

    rmSync(cacheRoot, { recursive: true, force: true });
    rmSync(fakeBin, { recursive: true, force: true });
  });

  it("fails discovery when the cache root is not searchable", () => {
    const cacheRoot = tempCacheRoot("savepoints-cache-unreadable-");
    try {
      // chmod after creating so cleanup can still remove the directory.
      mkdirSync(join(cacheRoot, "placeholder"));
      chmodSync(cacheRoot, 0o000);

      const result = runLayoutVerify({ cacheRoot });
      expect(result.status).toBe(1);
      expect(result.stderr).toContain("installed-cache discovery failed");
    } finally {
      chmodSync(cacheRoot, 0o700);
      rmSync(cacheRoot, { recursive: true, force: true });
    }
  });
});
