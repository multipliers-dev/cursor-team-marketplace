import { mkdtempSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

import { describe, expect, it } from "vitest";

import {
  effectiveExcludeGlobs,
  parsePlanFrontmatter,
  sliceHeadingTodoId,
  validatePlanContent,
  validatePlanFile,
  validatePlanPaths,
} from "./plan-validate.js";

const here = dirname(fileURLToPath(import.meta.url));
const fixturesDir = join(here, "..", "fixtures", "plan-validate");

function minimalPlan(body: string): string {
  return `---
name: Test plan
overview: Test overview for validator regressions.
todos:
  - id: slice-a
    content: "PR: slice a"
    status: pending
  - id: plan-closure
    content: "Docs-only closure"
    status: pending
isProject: false
---

# Test plan

## Recommended execution authority

| Slice | Recommended authority | Agent instruction |
| --- | --- | --- |
| slice-a | Open PR only | Do not merge. Stop after opening the PR. |
| plan-closure | Open PR only | Do not merge. Stop after opening the PR. |

Repo default: **Open PR only** (see team skill \`/planning-methodology\`).

## Repository topology (default)

Multi-slice plans stack execution order, not Git branches. Integration branch is \`main\`.

**Before implementation:** start from latest \`origin/main\`.

**Before opening the PR:** branch represents only this slice.

**After opening the PR:** GitHub PR base is \`main\`.

${body}
`;
}

function sliceBlock(id: string, extra = ""): string {
  const heading =
    id === "plan-closure" ? "## Plan closure (docs-only PR)" : `## Slice — ${id}`;
  return `${heading}

**Recommended authority:** Open PR only

**Rationale:**

- rationale

**Agent instruction:** Do not merge. Stop after opening the PR.

**Acceptance:**

- ships work
${extra}
`;
}

function agentPrompts(blocks: string): string {
  return `## Agent prompts (copy/paste for Cursor)

${blocks}`;
}

function promptBlock(id: string, inner: string): string {
  return `### ${id}

\`\`\`text
${inner}
\`\`\``;
}

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

  it("reports missing agent prompt heading for actionable todo", () => {
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

  it("requires authority table row for actionable todos", () => {
    const body = `${sliceBlock("slice-a")}

${sliceBlock("plan-closure")}

${agentPrompts(
  [
    promptBlock(
      "slice-a",
      "Authority: Open PR only — x\nTopology: x\nDeliverables: x\nVerification: x",
    ),
    promptBlock(
      "plan-closure",
      "Authority: Open PR only — x\nTopology: x\nDeliverables: x\nVerification: x",
    ),
  ].join("\n\n"),
)}`;
    const content = minimalPlan(body).replace(
      "| slice-a | Open PR only | Do not merge. Stop after opening the PR. |\n",
      "",
    );
    const issues = validatePlanContent(content, "missing-table-row.plan.md");
    expect(issues.some((i) => i.rule === "authority.table.missing-row")).toBe(true);
  });

  it("errors on unrecognized authority table label", () => {
    const body = `${sliceBlock("slice-a")}

${sliceBlock("plan-closure")}

${agentPrompts(
  [
    promptBlock(
      "slice-a",
      "Authority: Open PR only — x\nTopology: x\nDeliverables: x\nVerification: x",
    ),
    promptBlock(
      "plan-closure",
      "Authority: Open PR only — x\nTopology: x\nDeliverables: x\nVerification: x",
    ),
  ].join("\n\n"),
)}`;
    const content = minimalPlan(body).replace(
      "| slice-a | Open PR only |",
      "| slice-a | Not a real authority |",
    );
    const issues = validatePlanContent(content, "bad-table-label.plan.md");
    expect(issues.some((i) => i.rule === "authority.table.unrecognized-label")).toBe(true);
  });

  it("errors on duplicate authority table rows", () => {
    const body = `${sliceBlock("slice-a")}

${sliceBlock("plan-closure")}

${agentPrompts(
  [
    promptBlock(
      "slice-a",
      "Authority: Open PR only — x\nTopology: x\nDeliverables: x\nVerification: x",
    ),
    promptBlock(
      "plan-closure",
      "Authority: Open PR only — x\nTopology: x\nDeliverables: x\nVerification: x",
    ),
  ].join("\n\n"),
)}`;
    const content = minimalPlan(body).replace(
      "| slice-a | Open PR only | Do not merge. Stop after opening the PR. |",
      "| slice-a | Open PR only | Do not merge. Stop after opening the PR. |\n| slice-a | Open PR only | Do not merge. Stop after opening the PR. |",
    );
    const issues = validatePlanContent(content, "dup-table-row.plan.md");
    expect(issues.some((i) => i.rule === "authority.table.duplicate-row")).toBe(true);
  });

  it("distinguishes missing fence from missing heading", () => {
    const body = `${sliceBlock("slice-a")}

${sliceBlock("plan-closure")}

${agentPrompts(
  [
    "### slice-a",
    "",
    "Some prose but no fence.",
    promptBlock(
      "plan-closure",
      "Authority: Open PR only — x\nTopology: x\nDeliverables: x\nVerification: x",
    ),
  ].join("\n\n"),
)}`;
    const issues = validatePlanContent(minimalPlan(body), "fence-missing.plan.md");
    expect(issues.some((i) => i.rule === "prompts.fence-missing")).toBe(true);
    expect(issues.some((i) => i.rule === "prompts.missing")).toBe(false);
  });

  it("reports unclosed prompt fence", () => {
    const body = `${sliceBlock("slice-a")}

${sliceBlock("plan-closure")}

${agentPrompts(
  [
    "### slice-a",
    "",
    "```text",
    "Authority: Open PR only — x",
    "Topology: x",
    "Deliverables: x",
    "Verification: x",
    promptBlock(
      "plan-closure",
      "Authority: Open PR only — x\nTopology: x\nDeliverables: x\nVerification: x",
    ),
  ].join("\n"),
)}`;
    const issues = validatePlanContent(minimalPlan(body), "fence-unclosed.plan.md");
    expect(issues.some((i) => i.rule === "prompts.fence-unclosed")).toBe(true);
  });

  it("include-archive removes only the default plans archive glob", () => {
    const config = {
      excludeGlobs: [".cursor/plans/archive/**", "**/archive-notes/**"],
    };
    expect(effectiveExcludeGlobs(config, false)).toEqual(config.excludeGlobs);
    expect(effectiveExcludeGlobs(config, true)).toEqual(["**/archive-notes/**"]);
  });

  it("does not treat substring headings as slice sections", () => {
    expect(sliceHeadingTodoId("Notes on plan-validate-lib")).toBeNull();
    const body = `${sliceBlock("slice-a").replace("## Slice — slice-a", "## Notes on slice-a")}

${sliceBlock("plan-closure")}

${agentPrompts(
  [
    promptBlock(
      "slice-a",
      "Authority: Open PR only — x\nTopology: x\nDeliverables: x\nVerification: x",
    ),
    promptBlock(
      "plan-closure",
      "Authority: Open PR only — x\nTopology: x\nDeliverables: x\nVerification: x",
    ),
  ].join("\n\n"),
)}`;
    const issues = validatePlanContent(minimalPlan(body), "bad-slice-heading.plan.md");
    expect(issues.some((i) => i.rule === "slice.missing" && i.message.includes("slice-a"))).toBe(
      true,
    );
  });

  it("accepts canonical slice heading dash variants", () => {
    expect(sliceHeadingTodoId("Slice — slice-a")).toBe("slice-a");
    expect(sliceHeadingTodoId("Slice - slice-a")).toBe("slice-a");
    expect(sliceHeadingTodoId("Slice – slice-a")).toBe("slice-a");
    expect(sliceHeadingTodoId("Plan closure (docs-only PR)")).toBe("plan-closure");
  });

  it("ignores slice fields that appear only inside fenced blocks", () => {
    const body = `## Slice — slice-a

\`\`\`markdown
**Recommended authority:** Open PR only
**Rationale:**
- inside fence
**Agent instruction:** Do not merge.
**Acceptance:**
- fenced only
\`\`\`

${sliceBlock("plan-closure")}

${agentPrompts(
  [
    promptBlock(
      "slice-a",
      "Authority: Open PR only — x\nTopology: x\nDeliverables: x\nVerification: x",
    ),
    promptBlock(
      "plan-closure",
      "Authority: Open PR only — x\nTopology: x\nDeliverables: x\nVerification: x",
    ),
  ].join("\n\n"),
)}`;
    const issues = validatePlanContent(minimalPlan(body), "fenced-slice-fields.plan.md");
    expect(issues.some((i) => i.rule === "slice.recommended-authority")).toBe(true);
    expect(issues.some((i) => i.rule === "slice.rationale")).toBe(true);
    expect(issues.some((i) => i.rule === "slice.agent-instruction")).toBe(true);
    expect(issues.some((i) => i.rule === "slice.acceptance")).toBe(true);
  });

  it("does not exempt Acceptance when slice authority is unrecognized", () => {
    const body = `${sliceBlock("slice-a").replace(
      "**Recommended authority:** Open PR only",
      "**Recommended authority:** Not a real authority",
    ).replace("**Acceptance:**\n\n- ships work", "")}

${sliceBlock("plan-closure")}

${agentPrompts(
  [
    promptBlock(
      "slice-a",
      "Authority: Open PR only — x\nTopology: x\nDeliverables: x\nVerification: x",
    ),
    promptBlock(
      "plan-closure",
      "Authority: Open PR only — x\nTopology: x\nDeliverables: x\nVerification: x",
    ),
  ].join("\n\n"),
)}`;
    const issues = validatePlanContent(minimalPlan(body), "unknown-auth-acceptance.plan.md");
    expect(issues.some((i) => i.rule === "slice.authority-label")).toBe(true);
    expect(issues.some((i) => i.rule === "slice.acceptance")).toBe(true);
  });

  it("rejects ellipsis-only slice Acceptance in default profile", () => {
    const body = `${sliceBlock("slice-a").replace("- ships work", "…")}

${sliceBlock("plan-closure")}

${agentPrompts(
  [
    promptBlock(
      "slice-a",
      "Authority: Open PR only — x\nTopology: x\nDeliverables: x\nVerification: x",
    ),
    promptBlock(
      "plan-closure",
      "Authority: Open PR only — x\nTopology: x\nDeliverables: x\nVerification: x",
    ),
  ].join("\n\n"),
)}`;
    const strict = validatePlanContent(minimalPlan(body), "ellipsis-acceptance.plan.md");
    expect(
      strict.some(
        (i) => i.rule === "slice.acceptance" && i.message.includes("ellipsis placeholder"),
      ),
    ).toBe(true);
    const relaxed = validatePlanContent(minimalPlan(body), "ellipsis-acceptance.plan.md", {
      profile: "template",
    });
    expect(
      relaxed.some(
        (i) => i.rule === "slice.acceptance" && i.message.includes("ellipsis placeholder"),
      ),
    ).toBe(false);
  });

  it("reports authority.mismatch for every conflicting duplicate table row", () => {
    const body = `${sliceBlock("slice-a")}

${sliceBlock("plan-closure")}

${agentPrompts(
  [
    promptBlock(
      "slice-a",
      "Authority: Open PR only — x\nTopology: x\nDeliverables: x\nVerification: x",
    ),
    promptBlock(
      "plan-closure",
      "Authority: Open PR only — x\nTopology: x\nDeliverables: x\nVerification: x",
    ),
  ].join("\n\n"),
)}`;
    const content = minimalPlan(body).replace(
      "| slice-a | Open PR only | Do not merge. Stop after opening the PR. |",
      "| slice-a | Open PR only | Do not merge. Stop after opening the PR. |\n| slice-a | Merge granted | May merge when verified. |",
    );
    const issues = validatePlanContent(content, "dup-table-mismatch.plan.md");
    const mismatches = issues.filter((i) => i.rule === "authority.mismatch");
    expect(mismatches.length).toBeGreaterThanOrEqual(2);
    expect(mismatches.some((i) => i.message.includes("Merge granted"))).toBe(true);
    expect(issues.some((i) => i.rule === "authority.table.duplicate-row")).toBe(true);
  });

  it("reports prompts.duplicate on the duplicate heading line", () => {
    const body = `${sliceBlock("slice-a")}

${sliceBlock("plan-closure")}

${agentPrompts(
  [
    promptBlock(
      "slice-a",
      "Authority: Open PR only — x\nTopology: x\nDeliverables: x\nVerification: x",
    ),
    "### slice-a",
    "",
    promptBlock(
      "plan-closure",
      "Authority: Open PR only — x\nTopology: x\nDeliverables: x\nVerification: x",
    ),
  ].join("\n\n"),
)}`;
    const content = minimalPlan(body);
    const issues = validatePlanContent(content, "dup-prompt-heading.plan.md");
    const dup = issues.find((i) => i.rule === "prompts.duplicate");
    expect(dup).toBeDefined();
    expect(dup!.line).toBeGreaterThan(1);
    expect(content.split("\n")[dup!.line - 1]?.trim()).toMatch(/^### slice-a$/);
  });

  it("reports discovery.empty and handles explicit paths", async () => {
    const emptyRoot = mkdtempSync(join(tmpdir(), "plan-validate-empty-"));
    const emptyIssues = await validatePlanPaths([], { repoRoot: emptyRoot });
    expect(emptyIssues.some((i) => i.rule === "discovery.empty")).toBe(true);

    const validPath = join(fixturesDir, "valid-minimal.plan.md");
    const explicitOk = await validatePlanPaths([validPath], { repoRoot: emptyRoot });
    expect(explicitOk).toEqual([]);

    const missing = await validatePlanPaths(["does-not-exist.plan.md"], {
      repoRoot: emptyRoot,
    });
    expect(missing.some((i) => i.rule === "io.not-found")).toBe(true);
  });
});
