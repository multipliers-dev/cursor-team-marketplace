import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

import { describe, expect, it } from "vitest";

import {
  parsePlanFrontmatter,
  validatePlanContent,
  validatePlanFile,
} from "./plan-validate.js";

const here = dirname(fileURLToPath(import.meta.url));
const fixturesDir = join(here, "..", "fixtures", "plan-validate");

describe("plan-validate", () => {
  it("passes a valid minimal fixture plan", () => {
    const path = join(fixturesDir, "valid-minimal.plan.md");
    const issues = validatePlanFile(path);
    expect(issues).toEqual([]);
  });

  it("reports malformed frontmatter", () => {
    const path = join(fixturesDir, "invalid-malformed-frontmatter.plan.md");
    const content = readFileSync(path, "utf8");
    const parsed = parsePlanFrontmatter(content, path);
    expect(parsed.ok).toBe(false);
    if (!parsed.ok) {
      expect(parsed.issues.some((i) => i.rule === "frontmatter.delimiter")).toBe(true);
    }
    const issues = validatePlanContent(content, path);
    expect(issues.length).toBeGreaterThan(0);
  });

  it("reports missing agent prompt for actionable todo", () => {
    const path = join(fixturesDir, "invalid-actionable-prompt-gap.plan.md");
    const issues = validatePlanFile(path);
    expect(
      issues.some(
        (i) => i.rule === "prompts.missing" && i.message.includes("slice-a"),
      ),
    ).toBe(true);
  });

  it("flags unrecognized todo status", () => {
    const content = `---
name: Bad status
overview: x
todos:
  - id: a
    content: "x"
    status: done
isProject: false
---

# x

## Recommended execution authority

| Slice | Recommended authority | Agent instruction |
| --- | --- | --- |
| a | Open PR only | Stop |

Repo default: **Open PR only**

## Slice — a

**Recommended authority:** Open PR only

**Rationale:**

- r

**Agent instruction:** Stop

**Acceptance:**

- a

## Agent prompts (copy/paste for Cursor)

### a

\`\`\`text
Authority: Open PR only — x
Topology: x
Deliverables: x
Verification: x
\`\`\`
`;
    const issues = validatePlanContent(content, "bad-status.plan.md");
    expect(issues.some((i) => i.rule === "frontmatter.todo-status")).toBe(true);
  });
});
