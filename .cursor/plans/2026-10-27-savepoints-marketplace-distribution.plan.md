---
name: Savepoints marketplace distribution
overview: Distribute @multipliers-dev/savepoints-lite@2.0.0 through team-harness (vendored canonical skills, thin wrapper, engineering invariants destination handoff), then consumer cleanup after verified global integration. Open PR only throughout.
todos:
  - id: plan-review
    content: "Plan-only PR — commit this plan; do not implement slices"
    status: completed
  - id: marketplace-distribution
    content: "cursor-team-marketplace PR: vendor sync/verify, savepoints wrapper skill, engineering invariants, docs, version 1.15.0; mark completed in same PR; Open PR only"
    status: pending
  - id: gate-consumer-prereqs
    content: "Operator: confirm marketplace merged, team-harness plugin refreshed, engineering invariants in User Rules, vendored skills readable, end-to-end Savepoint persistence via installed plugin"
    status: pending
  - id: consumer-cleanup
    content: "Per-repo inventory; one Open PR only per repo needing changes; record no-change repos; preserve marketplace build-time savepoints-lite devDep"
    status: pending
  - id: plan-closure
    content: "Docs-only PR after last slice: # Shipped note, move plan to .cursor/plans/archive/2026-10-27-savepoints-marketplace-distribution.plan.md"
    status: pending
isProject: false
---

# Centralized Savepoints Lite via Team Marketplace

## Recommended execution authority

| Slice | Recommended authority | Agent instruction |
| --- | --- | --- |
| plan-review | Plan-only PR | Do not implement slices. Stop after opening the plan-only PR. |
| marketplace-distribution | Open PR only | Marketplace repo only. Mark `marketplace-distribution` completed in plan frontmatter in the **same** implementation PR. Stop after opening the PR. |
| gate-consumer-prereqs | Manual verification gate | Confirm prerequisites for consumer cleanup; no consumer edits. Stop with pass/fail report. |
| consumer-cleanup | Open PR only | **Prerequisite:** `gate-consumer-prereqs` passed. One repo per PR. Record inventory in marketplace plan when opening `plan-closure` (or a short progress note in the consumer-cleanup PR description). |
| plan-closure | Open PR only | Docs-only archive PR. Do not merge. |

Repo default: **Open PR only** (plan-review for plan artifact only).

## Repository topology

Multi-slice plans stack execution order, not Git branches. Integration branch is `main` for every repository.

**Before implementation:** `git fetch` and branch from latest `origin/main` in the target repo.

**Before opening the PR:** branch contains only the current slice.

**After opening the PR:** GitHub base is `main`; diff excludes prior-slice work except through merged `main`.

**Cross-repo:** Phases 1–2 → `cursor-team-marketplace`. Consumer cleanup → each consumer repo (separate PRs).

## Plan coordination (cross-repository)

This file lives in **`multipliers-dev/cursor-team-marketplace`** and is the **single coordination record** for the initiative.

| Event | Where to record progress |
| --- | --- |
| Marketplace implementation PR opened/merged | Mark `marketplace-distribution` `completed` and link the PR in **the same implementation PR** (frontmatter + optional `# Progress` note in plan body). |
| Operator / integration gates | Mark `gate-consumer-prereqs` `completed` when confirming prerequisites (marketplace plan update in the same session or a follow-up docs-only commit on `main` — no separate plan-status PR required). |
| Consumer cleanup PRs opened | Record repo → PR link or “no change” in plan body or `plan-closure` PR; mark `consumer-cleanup` `completed` when opening `plan-closure` or in the last consumer PR batch. |
| Initiative complete | `plan-closure` docs-only PR: archive plan, mark `plan-closure` completed. |

Implementation PRs in **other** repositories must not edit this plan unless the slice explicitly authorizes it (consumer cleanup does not).

Run `npm run validate:plans` on any commit that changes this plan file.

## Completed prerequisites

Upstream Savepoints Lite work is **done** — not pending marketplace execution:

- **`@multipliers-dev/savepoints-lite@2.0.0`** is published on npm; registry version and `latest` dist-tag verified; clean install produced the expected 16 packaged files.
- **Merged Savepoints Lite PRs [#13](https://github.com/multipliers-dev/savepoints-lite/pull/13)–[#17](https://github.com/multipliers-dev/savepoints-lite/pull/17)** (configuration contract, OSS readiness, post-publish hub dogfood bump).
- **Archived OSS readiness plan:** [`savepoints-lite/.cursor/plans/archive/2026-10-27-oss-readiness-cleanup.plan.md`](https://github.com/multipliers-dev/savepoints-lite/blob/main/.cursor/plans/archive/2026-10-27-oss-readiness-cleanup.plan.md).

The published package owns canonical router/provider behavior, destination precedence (explicit integration → `.agents` → packaged defaults), and fail-open semantics. This marketplace plan **does not** reopen savepoints-lite OSS or publish gates.

## Context and gates

```mermaid
flowchart TD
  prereq[Completed_savepoints_lite_2_0_0]
  phase2[Phase2_marketplace_PR]
  merge2[Merge_marketplace_PR]
  refresh[Plugin_refresh]
  userRules[User_Rules_installed]
  e2e[E2E_Savepoint_persistence]
  phase5[Phase5_consumer_cleanup]
  consumerPRs[One_PR_per_repo]

  prereq --> phase2
  phase2 --> merge2 --> refresh --> userRules --> e2e
  e2e --> phase5 --> consumerPRs
```

- **Hard gate (consumer cleanup):** Do not start `consumer-cleanup` until marketplace implementation is **merged**, team-harness plugin is installed/refreshed, vendored canonical skills are readable in the installed plugin, engineering invariants are installed in global Cursor User Rules, and **end-to-end Savepoint persistence** is verified through the installed plugin (not only `node_modules` in a dev checkout).
- **Target semver:** `2.0.0` (breaking: packaged Notion destination removed; explicit-integration tier added).

### Relationship to savepoints-lite OSS work

[PR #13](https://github.com/multipliers-dev/savepoints-lite/pull/13) and follow-on PRs **#14–#17** completed OSS readiness and publish. Do not reopen that work from this plan.

This plan supersedes the archived OSS plan’s **pre-2.0.0 seven-consumer `.agents` migration** with **consumer cleanup after marketplace + User Rules + verified plugin integration**.

### Architectural boundaries (marketplace slice)

| Rule | Detail |
| --- | --- |
| Canonical behavior | Savepoints Lite npm package / vendored `vendor/savepoints-lite/` — router, provider, precedence, fail-open |
| Wrapper scope | `plugins/team-harness/skills/savepoints/SKILL.md` — Cursor discovery, delegation, explicit Notion `data_source_id` from User Rules into instruction context only |
| No duplication | No duplicate event-detection or Notion mapping logic in the marketplace |
| No runtime `node_modules` | Installed Cursor plugin must not depend on `npm install` for skills |
| No upstream edits | Do not modify the published Savepoints Lite package from marketplace work |
| No package-wide default | Do not add a maintainer destination default to the team-harness plugin for all consumers |

---

## Slice — marketplace-distribution

**Recommended authority:** Open PR only

**Repositories:** `multipliers-dev/cursor-team-marketplace` (read/write)

**Prerequisite:** Completed prerequisites (§ above) — `@2.0.0` on npm and verified.

**Rationale:** Cursor installs plugin content from Git without `npm install`; canonical skills must be committed under `vendor/` with sync/verify against the pinned release, plus a thin wrapper and User Rules destination handoff.

**Agent instruction:** Marketplace repo only; do not implement `consumer-cleanup`. Mark `marketplace-distribution` `completed` in this plan’s frontmatter in the **same** PR. Stop after opening the PR.

**Goal:**

- Pin `@multipliers-dev/savepoints-lite@2.0.0` as a root **build-time** `devDependency`.
- Deterministically copy canonical published skills into `plugins/team-harness/vendor/savepoints-lite/` (sync + verify scripts; CI detects vendor drift vs pinned npm release).
- Commit vendored artifacts (plugin install does not run `npm install`).
- Thin discoverable `plugins/team-harness/skills/savepoints/SKILL.md` wrapper: carry explicit Notion destination from global Cursor User Rules (engineering invariants) through vendored router → provider **instruction context**; provider **does not** read User Rules.
- Update [`docs/engineering-invariants.md`](docs/engineering-invariants.md) and relevant integration documentation (personal `data_source_id` only in User Rules, not vendor/canonical package).
- Bump team-harness plugin version to **`1.15.0`**.

**Acceptance:** `verify:savepoints-vendor` (or equivalent script name), `npm test`, `npm run validate:plans`, `scripts/check.sh`; frontmatter `marketplace-distribution` → `completed`; PR opened (Open PR only).

---

## Slice — gate-consumer-prereqs

**Recommended authority:** Manual verification gate

**Rationale:** Consumer cleanup must not run before global integration is live and proven.

**Agent instruction:** Verify prerequisites only; no consumer repo edits. Stop with pass/fail report. Mark `gate-consumer-prereqs` `completed` in plan frontmatter when all checks pass (same session docs commit acceptable).

**Acceptance:**

- Marketplace `marketplace-distribution` merged to `main`.
- Team-harness plugin refreshed in Cursor; vendored `vendor/savepoints-lite/skills/` readable under installed plugin cache.
- Engineering invariants Savepoints section present in **global Cursor User Rules**.
- End-to-end Savepoint write confirmed via installed plugin path (Notion MCP + wrapper → vendored router/provider).

---

## Slice — consumer-cleanup

**Recommended authority:** Open PR only

**Prerequisite:** `gate-consumer-prereqs` passed.

**Repositories (inventory):** `multipliers-dev/savepoints-lite`, `multipliers-dev/cursor-team-marketplace`, `multipliers-dev/editorial-workflow`, `multipliers-dev/renovate-workflow`, `multipliers-dev/codenames-ai-guesser`, `mastermichaelt/resumes`, `mastermichaelt/portfolio` — extend if grep finds more.

**Rationale:** Redundant per-repo npm deps, `.agents` Savepoints config, and `AGENTS.md` activation are obsolete once team-harness + User Rules provide global Savepoints.

**Agent instruction:** One repo per PR; do not merge. Stop after opening required PRs. Do not remove savepoints-lite canonical package files or the marketplace root build-time devDependency.

**Goal:** Remove redundant consumer `savepoints-lite` npm dependencies, `AGENTS.md` Savepoints Lite activation sections, and obsolete `.agents` Savepoints YAML where appropriate. Record no-change repos.

**Exclusions:** No hooks, monitoring, or reliability improvements.

**Acceptance:** Per-repo verification; PRs opened (Open PR only). Mark `consumer-cleanup` `completed` when inventory is recorded (typically in `plan-closure` prep).

---

## Slice — plan-closure

**Recommended authority:** Open PR only

**Rationale:** Archive completed multi-slice plan per repository planning standards.

**Agent instruction:** Docs-only PR; do not merge. Stop after opening the PR.

**Acceptance:** Plan moved to `.cursor/plans/archive/` with `# Shipped` note; `plan-closure` todo completed; consumer inventory links captured if not already in plan body.

---

## Phase — Verification (marketplace slice)

| Acceptance criterion | How |
| --- | --- |
| Wrapper discoverable | `scripts/check.sh` includes `skills/savepoints/SKILL.md` |
| Canonical skills readable | `vendor/savepoints-lite/skills/` |
| Wrapper handoff | Destination carried through delegation; provider not told to read User Rules |
| Vendor matches registry | `npm run verify:savepoints-vendor` (or named verify script from slice) |
| Installed plugin | Inspect `~/.cursor/plugins/cache/.../team-harness/<sha>/` after refresh |

---

## Final completion checklist

- [ ] `marketplace-distribution` merged; team-harness **1.15.0** available; vendor sync/verify in CI
- [ ] Plugin refreshed; vendored skills readable; wrapper skill on discovery path
- [ ] User Rules include engineering invariants Savepoints destination
- [ ] E2E Savepoint persistence verified through installed plugin
- [ ] `gate-consumer-prereqs` marked completed
- [ ] Consumer cleanup PRs opened (or no-change recorded) per inventory
- [ ] `plan-closure` archive PR opened with `# Shipped` note

---

## Agent prompts (copy/paste for Cursor)

### plan-review

```text
@.cursor/plans/2026-10-27-savepoints-marketplace-distribution.plan.md

Implement slice plan-review only.

Authority: Plan-only PR — do not implement other slices. Stop after opening the PR.

Topology: branch from latest origin/main in multipliers-dev/cursor-team-marketplace; PR base main.

Deliverables: commit .cursor/plans/2026-10-27-savepoints-marketplace-distribution.plan.md only.

Verification: npm run validate:plans. Mark plan-review completed in frontmatter in the same PR.
```

### marketplace-distribution

```text
@.cursor/plans/2026-10-27-savepoints-marketplace-distribution.plan.md

Implement slice marketplace-distribution only.

Authority: Open PR only — do not merge.

Repositories: multipliers-dev/cursor-team-marketplace only.

Prerequisite: @multipliers-dev/savepoints-lite@2.0.0 published (completed prerequisites). Stop only if registry pin is missing.

Topology: branch from origin/main; PR base main.

Deliverables: root devDependency @2.0.0; vendor sync/verify scripts + committed plugins/team-harness/vendor/savepoints-lite/; thin plugins/team-harness/skills/savepoints/SKILL.md (User Rules destination → router/provider instruction context); docs/engineering-invariants.md + integration docs; team-harness version 1.15.0. Preserve architectural boundaries in plan (no duplicate Notion logic, no runtime node_modules in plugin, no upstream package edits). Do not implement consumer-cleanup.

Verification: npm run verify:savepoints-vendor (or slice script), npm test, npm run validate:plans, sh scripts/check.sh. Mark marketplace-distribution completed in plan frontmatter in this PR.
```

### gate-consumer-prereqs

```text
@.cursor/plans/2026-10-27-savepoints-marketplace-distribution.plan.md

Implement slice gate-consumer-prereqs only.

Authority: Manual verification gate — no consumer repo edits.

Topology: N/A (operator + filesystem + Notion checks).

Deliverables: pass/fail report for marketplace merge, plugin refresh, vendored skills readable, User Rules engineering invariants, end-to-end Savepoint persistence via installed plugin.

Verification: git log origin/main for marketplace merge; inspect ~/.cursor/plugins/cache/.../team-harness for vendor skills; confirm User Rules; one successful Savepoint write through plugin path. Mark gate-consumer-prereqs completed in plan frontmatter when all pass. Stop before consumer-cleanup if any fail.
```

### consumer-cleanup

```text
@.cursor/plans/2026-10-27-savepoints-marketplace-distribution.plan.md

Implement slice consumer-cleanup only.

Authority: Open PR only — one PR per repo; do not merge.

Prerequisite: gate-consumer-prereqs passed. Stop if not.

Repositories: inventory in plan; prove checkout identity per repo.

Topology: each consumer repo branches from origin/main; PR base main; one slice per PR.

Deliverables: remove redundant savepoints-lite consumer deps, AGENTS.md Savepoints activation, obsolete .agents Savepoints YAML; preserve marketplace build-time devDep and savepoints-lite canonical package/skills; record no-change repos.

Verification: per-repo npm test/check as documented. Do not edit this marketplace plan from consumer repos unless marking consumer-cleanup completed in a marketplace follow-up.
```

### plan-closure

```text
@.cursor/plans/2026-10-27-savepoints-marketplace-distribution.plan.md

Implement slice plan-closure only.

Authority: Open PR only — docs-only. Do not merge.

Topology: branch from origin/main in cursor-team-marketplace; PR base main.

Deliverables: verify slice todos, add # Shipped closure note, consumer inventory if missing, move plan to .cursor/plans/archive/2026-10-27-savepoints-marketplace-distribution.plan.md, mark plan-closure completed.

Verification: npm run validate:plans. No production code changes.
```
