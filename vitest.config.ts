import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["scripts/**/*.test.ts", "plugins/team-harness/scripts/**/*.test.ts"],
    passWithNoTests: true,
  },
});
