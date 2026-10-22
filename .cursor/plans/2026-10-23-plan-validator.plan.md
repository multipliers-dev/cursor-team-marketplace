---
name: Plan validator
overview: Add a vendored TypeScript plan validator under team-harness (canonical source), wire it into planning-methodology docs and marketplace CI via fixtures, and document copy-only adoption for consuming repos—without changing those repos in this PR.
todos:
  - id: plan-review
    content: "Plan-only PR: commit this plan under .cursor/plans/ and open for review; do not implement"
    status: completed
  - id: plan-validate-lib
    content: "PR: validator lib + CLI under plugins/team-harness/scripts, tsconfig scope, yaml + lockfile, minimal merge-safe tests + CLI smoke"
    status: completed
  - id: fixtures-tests
    content: "PR: expand regression fixtures under scripts/fixtures/plan-validate and integration-style Vitest coverage"
    status: completed
  - id: ci-npm
    content: "PR: validate:plans npm scripts, ci.yml/check.sh template gate, plugin/marketplace version bump (no new deps)"
    status: completed
  - id: docs-skill
    content: "PR: plan-validation.md; align SKILL.md item 7 todo/prompt rule with validator; README scripts table"
    status: completed
  - id: plan-closure
    content: "Docs-only PR after last slice: add # Shipped note, move plan to .cursor/plans/archive/2026-10-23-plan-validator.plan.md"
    status: pending
isProject: false
---

# Deterministic plan validation (team-harness)

## Recommended execution authority

| Slice             | Recommended authority | Agent instruction                                      |
| ----------------- | --------------------- | ------------------------------------------------------ |
| plan-review       | Plan-only PR          | Do not implement. Stop after opening the plan-only PR. |
| plan-validate-lib | Open PR only          | Do not merge. Stop after opening the PR.               |
| fixtures-tests    | Open PR only          | Do not merge. Stop after opening the PR.               |
| ci-npm            | Open PR only          | Do not merge. Stop after opening the PR.               |
| docs-skill        | Open PR only          | Do not merge. Stop after opening the PR.               |
| plan-closure      | Open PR only          | Do not merge. Stop after opening the PR.               |

Repo default: **Open PR only** (see team skill `/planning-methodology`).

## Repository topology (default)

Multi-slice plans stack execution order, not Git branches. Integration branch is `main`.

**Before implementation:** start from latest `origin/main`.

**Before opening the PR:** branch represents only this slice — prior-slice work is on the integration branch, not via branch ancestry.

**After opening the PR:** GitHub PR base is `main`; diff excludes prior-slice work except through merged `main`.

This plan is **same-repo / single-checkout**: `multipliers-dev/cursor-team-marketplace` only. Do not edit consuming repositories in this plan.

---

## Context from reconnaissance

| Area | Current state |
| --- | --- |
| Methodology | Canonical procedure in [`plugins/team-harness/skills/planning-methodology/SKILL.md`](../../plugins/team-harness/skills/planning-methodology/SKILL.md), skeleton in [`_template.plan.md`](../../plugins/team-harness/skills/planning-methodology/_template.plan.md) |
| Consuming repos | Copy prose into repo `planning-standards.md` and `_template.plan.md`; **no** automated sync today |
| Vendoring precedent | Copy-only snapshots from [`plugins/team-harness/scripts/`](../../plugins/team-harness/scripts/) (hooks) |
| Marketplace CI | [`scripts/check.sh`](../../scripts/check.sh) + Vitest on `scripts/**/*.test.ts` |
| Prior art | Resumes `validate:lifecycle` pattern; **no** plan validator exists |

```mermaid
flowchart LR
  canonical["plugins/team-harness/scripts/plan-validate"]
  marketplaceCI["cursor-team-marketplace CI"]
  fixtures["scripts/fixtures/plan-validate"]
  consumer["Consuming repo scripts copy"]
  consumerCI["Consumer npm run validate:plans"]

  canonical --> marketplaceCI
  fixtures --> marketplaceCI
  canonical --> consumer
  consumer --> consumerCI
```

**Motivation:** recurring planning-conformance defects in consuming repos (authority, acceptance/verification, todo/prompt mismatch, topology, structural contradictions). Catch structural violations deterministically; keep semantic merge-safety review (Bugbot, humans).

---

## Slice — plan-review

**Recommended authority:** Plan-only PR

**Rationale:**

- Plan must land for review before validator implementation
- Expected diff is plan artifact only

**Agent instruction:** Do not implement. Stop after opening the plan-only PR.

**Goal:** Commit this plan artifact only.

**Acceptance:** Plan file at `.cursor/plans/2026-10-23-plan-validator.plan.md` with frontmatter todos, authority table, topology, per-slice blocks, agent prompts, and `plan-closure` todo.

---

## Slice — plan-validate-lib

**Recommended authority:** Open PR only

**Rationale:**

- Core library + CLI must typecheck and run on a clean checkout after `npm ci` — **`yaml` lands in this slice**, not `ci-npm`
- Merge-safe: minimal Vitest unit tests co-located with the library (not deferred to `fixtures-tests`)
- No consumer-repo changes

**Agent instruction:** Do not merge. Stop after opening the PR.

**Goal:** Implement the canonical validator under team-harness scripts with parser contract below and first-line regression tests.

**Acceptance:**

- Add the canonical validator library and CLI under [`plugins/team-harness/scripts/`](../../plugins/team-harness/scripts/) ([`lib/plan-validate.ts`](../../plugins/team-harness/scripts/lib/plan-validate.ts), [`validate-plans.ts`](../../plugins/team-harness/scripts/validate-plans.ts)): `PlanIssue` (`file`, `line`, `rule`, `message`); discovery, explicit paths, `--profile template`, optional `.cursor/plan-validator.json`
- Extend [`scripts/tsconfig.json`](../../scripts/tsconfig.json) (or add a dedicated TypeScript configuration referenced from root `typecheck`) so **`npm run typecheck` covers both existing root `scripts/` and `plugins/team-harness/scripts/**/*.ts`**
- Add the **`yaml`** devDependency and update **`package-lock.json`** in this slice
- Include **minimal automated tests** for core parsing and validation (e.g. valid plan pass, malformed frontmatter, actionable-todo prompt gap) so this PR is **independently merge-safe** — extend [`vitest.config.ts`](../../vitest.config.ts) `include` if tests live under the plugin tree
- Implement **Parser and CLI behavior** (section below); machine rules per **Machine-enforced rules**
- Co-locate at least one **valid** and one **invalid** plan fixture for CLI smoke (may live under `plugins/team-harness/scripts/fixtures/` or `scripts/fixtures/plan-validate/`; `fixtures-tests` may relocate or expand them)

**Verification:**

- `npm ci`
- `npm run typecheck` — must typecheck `plugins/team-harness/scripts/**/*.ts`
- `npm test` — must exercise the new validator, not only pre-existing tests
- CLI smoke: `tsx plugins/team-harness/scripts/validate-plans.ts` against valid and invalid fixtures — expect exit `0` vs non-zero and actionable diagnostics on stderr/stdout

**Prerequisite:** `plan-review` merged.

---

## Slice — fixtures-tests

**Recommended authority:** Open PR only

**Rationale:**

- **Expands** regression coverage and fixture corpus; does not carry merge-safety alone for `plan-validate-lib`
- Fixtures stay in marketplace `scripts/` (not plugin-only) for Vitest integration tests

**Agent instruction:** Do not merge. Stop after opening the PR.

**Goal:** Expanded positive, negative, and boundary coverage beyond `plan-validate-lib` minimal tests — discovery exclusions, profiles, and line-number regressions.

**Acceptance:**

- [`scripts/fixtures/plan-validate/`](../../scripts/fixtures/plan-validate/) corpus: valid single/multi-slice plans and targeted `invalid-*` fixtures (expand or supersede smoke fixtures from `plan-validate-lib` if relocated)
- [`scripts/plan-validate.test.ts`](../../scripts/plan-validate.test.ts) (or equivalent) asserts rules, profiles, and line numbers across the full fixture set
- Default discovery excludes `archive/**` and `_template.plan.md`

**Prerequisite:** `plan-validate-lib` merged.

---

## Slice — ci-npm

**Recommended authority:** Open PR only

**Rationale:**

- Wires validator into npm scripts and CI **after** deps and core tests exist on `main`
- No new dependencies in this slice (`yaml` already on `main`)

**Agent instruction:** Do not merge. Stop after opening the PR.

**Goal:** Marketplace CI runs plan validation gates.

**Acceptance:**

- Root `package.json`: register `validate:plans` and `validate:plans:template` only (no dependency changes unless a script path fix requires none)
- [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) runs template validation after tests; optional `check.sh` hook
- Bump plugin + marketplace version per [`versioning.md`](../../plugins/team-harness/docs/versioning.md) (`1.11.0` → `1.12.0`)

**Prerequisite:** `fixtures-tests` merged.

---

## Slice — docs-skill

**Recommended authority:** Open PR only

**Rationale:**

- Distribution and authoring guidance ship after validator exists and CI proves it
- **Normative skill text must match validator** (actionable vs completed/cancelled prompt headings)

**Agent instruction:** Do not merge. Stop after opening the PR.

**Goal:** Document vendoring and align planning-methodology with enforced contract.

**Acceptance:**

- New [`plugins/team-harness/docs/plan-validation.md`](../../plugins/team-harness/docs/plan-validation.md) (install, run, update, CI without plugin)
- [`planning-methodology/SKILL.md`](../../plugins/team-harness/skills/planning-methodology/SKILL.md):
  - **Revise item 7** (and any duplicate wording in staged authoring): require `### <todo-id>` for **actionable** todos (`pending`, `in_progress`); **completed** and **cancelled** todos may omit prompts; any existing `###` under Agent prompts must reference a known todo id (no orphans/duplicates)
  - Add **Plan validation** subsection (when to run `validate:plans`, deterministic vs semantic review)
- Mirror the todo/prompt rule in [`reference.md`](../../plugins/team-harness/skills/planning-methodology/reference.md) and boilerplate note in [`_template.plan.md`](../../plugins/team-harness/skills/planning-methodology/_template.plan.md) if they still say every todo requires a heading
- [`team-harness/README.md`](../../plugins/team-harness/README.md) scripts table updated

**Prerequisite:** `ci-npm` merged.

---

## Parser and CLI behavior (implement before coding)

These decisions are part of the validator contract; `plan-validate-lib` must implement them.

| Topic | Behavior |
| --- | --- |
| **Fenced code** | Headings and structure inside fenced blocks are **ignored** for agent-prompt and slice-section scans. Only the **outer** markdown document structure counts. Scan ` ```text ` / ` ``` ` blocks in the Agent prompts section for labeled lines. |
| **YAML frontmatter** | Missing `---` delimiters, unclosed frontmatter, or **malformed YAML** → **fail closed** with a parse error issue (line 1 or delimiter line). Empty `todos` or wrong types → schema issues. |
| **Todo `status`** | Only `pending`, `in_progress`, `completed`, `cancelled`. **Unrecognized status → error** (fail closed). |
| **Authority labels** | Normalize slice/table/prompt authorities to the four known labels (+ orthogonal Manual gate). **Unrecognized recommended authority → error** when the slice is actionable. Prompt `Authority:` must prefix-match a known label after normalization. |
| **Multi-file runs** | **Aggregate all diagnostics** across discovered or explicit paths; exit non-zero if any file has issues. Do not stop at first file or first issue within a file (report all issues per file). |
| **`--profile template`** | Same schema and rules; **relaxes placeholder checks only** (allow `….` / `…` in Deliverables, Verification, Acceptance). Does not skip frontmatter, heading correspondence, or authority structure. Used for skill `_template.plan.md` CI. |
| **Default profile** | Strict placeholders: Deliverables / Verification / Acceptance that are only ellipsis placeholders → error for actionable todos. |

---

## Machine-enforced rules (validator contract)

### Shared methodology

**Frontmatter:** `name`, `overview`, `todos`, `isProject`; unique todo `id`s; allowed statuses; last todo `plan-closure` when multi-slice.

**Agent prompts:** section title `## Agent prompts (copy/paste for Cursor)`; labeled `Authority` / `Topology` / `Deliverables` / `Verification` in actionable prompts; optional `Repositories:` when slice lists required repositories.

**Plan-level:** `## Recommended execution authority` table; **Repo default:** line (configurable hint).

**Per-slice body:** `**Recommended authority:**`, `**Rationale:**`, `**Agent instruction:**`, `**Acceptance:**` (exceptions for Plan-only PR, Manual verification gate, plan-closure per skill).

**Authority consistency:** slice, table, and prompt agree on normalized authority label.

**Not enforced:** merge-safety semantics, verification sufficiency, diagram preservation, cross-repo completion correctness.

### Repo-specific (optional `.cursor/plan-validator.json`)

`integrationBranch`, `plansGlobs` / `excludeGlobs`, `requireRepoDefaultLine`, `repoDefaultHint` — no hardcoded consumer commands.

---

## Compatibility and migration

- In-flight consumer plans may omit prompts for **completed** todos; actionable todos still validated.
- Archived marketplace plans excluded from default CI (`--include-archive` for audits).
- Consumer rollout: copy scripts + optional config in **later** PRs (out of scope here).

---

## Plan closure (docs-only PR)

**Recommended authority:** Open PR only

**Rationale:**

- Docs-only archival; human review of closure checklist

**Agent instruction:** Do not merge. Stop after opening the PR.

After `docs-skill` merges:

1. Verify implementation PRs are actually merged to `main` (not merely frontmatter `completed`)
2. Verify remaining todos are `completed` or `cancelled`
3. Add `# Shipped` with date, PR links, deferred work
4. Move to `.cursor/plans/archive/2026-10-23-plan-validator.plan.md`
5. Mark `plan-closure` completed; update agent prompt references to the archived path
6. No production behavior changes

---

## Agent prompts (copy/paste for Cursor)

Use a **fresh Agent-mode chat** per slice. Headings use frontmatter `id` values exactly.

### plan-review

```text
@.cursor/plans/2026-10-23-plan-validator.plan.md

Execute only plan-review. Do not start plan-validate-lib or later slices.

Authority: Plan-only PR — commit the plan artifact only; do not implement. Stop after opening the plan-only PR.

Topology: start from latest origin/main; branch represents only the plan artifact; PR base must be main.

Deliverables: commit .cursor/plans/2026-10-23-plan-validator.plan.md; mark plan-review completed in plan frontmatter in this PR.

Verification: plan satisfies planning-methodology envelope (frontmatter, authority table, topology, per-slice blocks, agent prompts, plan-closure); mermaid distribution diagram preserved; no validator implementation in this PR.
```

### plan-validate-lib

```text
@.cursor/plans/2026-10-23-plan-validator.plan.md

Implement slice plan-validate-lib only. Prerequisite: plan-review merged. Do not start fixtures-tests or later. Do not archive the plan.

Authority: Open PR only — implement and open the PR; do not merge.

Topology: start from latest origin/main; branch represents only this slice; PR base must be main.

Deliverables: canonical validator lib + CLI under plugins/team-harness/scripts; extend scripts/tsconfig (or dedicated config) so typecheck covers plugins/team-harness/scripts/**/*.ts; yaml + lockfile; minimal merge-safe validator tests; Parser and CLI behavior table; valid + invalid smoke fixtures for CLI. Mark plan-validate-lib completed in plan frontmatter in this PR.

Verification: npm ci; npm run typecheck (includes plugins/team-harness/scripts/**/*.ts); npm test (new validator tests run, not only existing tests); CLI smoke on valid fixture (exit 0) and invalid fixture (non-zero + diagnostics).
```

### fixtures-tests

```text
@.cursor/plans/2026-10-23-plan-validator.plan.md

Implement slice fixtures-tests only. Prerequisite: plan-validate-lib merged. Do not start ci-npm or later. Do not archive the plan.

Authority: Open PR only — implement and open the PR; do not merge.

Topology: start from latest origin/main; branch represents only this slice; PR base must be main.

Deliverables: scripts/fixtures/plan-validate/* and scripts/plan-validate.test.ts per slice acceptance. Mark fixtures-tests completed in plan frontmatter in this PR.

Verification: npm test.
```

### ci-npm

```text
@.cursor/plans/2026-10-23-plan-validator.plan.md

Implement slice ci-npm only. Prerequisite: fixtures-tests merged. Do not start docs-skill or plan-closure. Do not archive the plan.

Authority: Open PR only — implement and open the PR; do not merge.

Topology: start from latest origin/main; branch represents only this slice; PR base must be main.

Deliverables: validate:plans npm scripts only; ci.yml and optional check.sh template validation; plugin/marketplace version bump from main (no new dependencies). Mark ci-npm completed in plan frontmatter in this PR.

Verification: npm ci; npm run typecheck; npm test; npm run validate:plans:template.
```

### docs-skill

```text
@.cursor/plans/2026-10-23-plan-validator.plan.md

Implement slice docs-skill only. Prerequisite: ci-npm merged. Do not start plan-closure. Do not archive the plan.

Authority: Open PR only — implement and open the PR; do not merge.

Topology: start from latest origin/main; branch represents only this slice; PR base must be main.

Deliverables: plan-validation.md; SKILL.md item 7 revised for actionable vs completed/cancelled prompts + Plan validation subsection; reference.md/_template.plan.md aligned if needed; team-harness README scripts table. Mark docs-skill completed in plan frontmatter in this PR.

Verification: sh scripts/check.sh; npm test; grep/read confirms SKILL item 7 matches validator todo/prompt rules.
```

### plan-closure

```text
@.cursor/plans/2026-10-23-plan-validator.plan.md

Execute only plan-closure.

Authority: Open PR only — docs-only archive PR; do not merge.

Prerequisites: plan-validate-lib through docs-skill actually merged to main (not merely frontmatter completed).

Topology: start from latest origin/main; branch represents only this slice; PR base must be main.

Deliverables: verify slice todos, add # Shipped note, move plan to .cursor/plans/archive/2026-10-23-plan-validator.plan.md, mark plan-closure completed, update agent prompt references to the archived path.

Verification: confirm all prerequisite implementation PRs are merged and slice todos are completed before archiving.
```
