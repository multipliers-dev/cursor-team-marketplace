---
name: Savepoints marketplace distribution
overview: Distribute @multipliers-dev/savepoints-lite@2.0.0 through team-harness (vendored canonical skills, thin wrapper, engineering invariants destination handoff), then consumer cleanup after verified global integration. Open PR only throughout.
todos:
  - id: plan-review
    content: "Plan-only PR — commit this plan; do not implement slices"
    status: completed
  - id: marketplace-distribution
    content: "cursor-team-marketplace PR: vendor sync/verify, savepoints wrapper skill, engineering invariants, docs, version 1.15.0; mark completed in same PR; Open PR only"
    status: completed
  - id: gate-consumer-prereqs
    content: "Manual gate: read-only verification + pass/fail report (no commits/PRs/plan edits); todo reconciled at plan-closure from recorded evidence"
    status: pending
  - id: consumer-cleanup
    content: "Seven-repo inventory incl. savepoints-lite hub: remove redundant activation; hub keeps package verify + registry artifact checks; marketplace keeps build-time devDep + vendor; inventory at plan-closure"
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
| gate-consumer-prereqs | Manual verification gate | Read-only verification; pass/fail report with evidence. No commit, no PR, no tracked plan edits. Stop after the report. |
| consumer-cleanup | Open PR only | **Prerequisite:** `gate-consumer-prereqs` **passed**. Seven-repo activation cleanup (incl. savepoints-lite hub); preserve hub package verification and marketplace vendor pin. One repo per PR. Do not edit this marketplace plan. |
| plan-closure | Open PR only | Docs-only archive PR after merge verification (§ plan-closure). Reconcile gate + slice todos; `# Shipped` evidence; archive. Do not merge. |

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
| Marketplace implementation PR opened/merged | Mark `marketplace-distribution` `completed` and link the merged PR in **the same implementation PR** (frontmatter + optional `# Progress` note in plan body). |
| `gate-consumer-prereqs` | **Not** in tracked files during the gate. Operator/agent keeps a pass/fail report with evidence (chat, operator notes, or allowed gitignored artifacts only). `gate-consumer-prereqs` → `completed` is reconciled in the **`plan-closure`** PR from that evidence. |
| Consumer cleanup | Each consumer repo: its own Open PR only (merge to that repo’s `main` before closure). **Never** edit this marketplace plan from consumer repos. Inventory (repo → merged PR link or “no change”) is recorded in the **`plan-closure`** PR (`# Shipped` + plan body). `consumer-cleanup` → `completed` in frontmatter during **`plan-closure`** only. |
| Initiative complete | `plan-closure` docs-only PR: verify merges and gate evidence (§ plan-closure); reconcile todos; `# Shipped`; archive; mark `plan-closure` completed. |

Implementation PRs in **other** repositories **must not** edit this marketplace plan. No separate `plan-status-*` PRs.

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

- **Hard gate (consumer cleanup):** Do not start `consumer-cleanup` until `gate-consumer-prereqs` **passes** (documented pass/fail report with evidence — not inferred from plan todo status). Prerequisites: marketplace implementation **merged** to `main`; team-harness plugin installed/refreshed; vendored canonical skills readable in the installed plugin; engineering invariants in global Cursor User Rules; **end-to-end Savepoint persistence** through the installed plugin (not only `node_modules` in a dev checkout).
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

### Activation vs verification (consumer cleanup)

| Concern | After global integration |
| --- | --- |
| **Activation** (session logging instructions, per-repo npm install for skills, `.agents` destination YAML) | **One mechanism:** team-harness marketplace plugin + global User Rules (engineering invariants). Remove redundant per-repo activation from all **seven** inventory repos, including **`multipliers-dev/savepoints-lite`**. |
| **Verification** (package development, release tooling, tarball layout, registry artifact checks) | **Unchanged obligation** on the Savepoints Lite hub: canonical `skills/`, templates, `npm run verify` (workspace release candidate), and **independent** checks against the **published** npm artifact (file manifest, version-specific expected paths). Removing hub **activation** does not remove hub **verification**. |
| **Marketplace distribution** | Keeps root build-time `@multipliers-dev/savepoints-lite@2.0.0` and committed `vendor/savepoints-lite/` for plugin install — not “consumer activation” cleanup. |

Do not weaken package invariant or registry dogfood tests to make a dependency removable. If the hub self-`devDependency` is removed, replace it with an equivalent isolated install or package-fetch path that still asserts the registry tarball independently of the workspace release candidate.

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

**Agent instruction:** Read-only verification only. Produce a **pass/fail report** with supporting evidence (commands run, paths inspected, Notion write outcome, links to merged marketplace PR on GitHub). **Do not** commit, open a PR, or modify tracked plan frontmatter or other tracked files. Allowed outputs: chat report and gitignored operator artifacts if the slice names them. Stop after the report. Reconcile `gate-consumer-prereqs` → `completed` in frontmatter during **`plan-closure`** when evidence proves pass.

**Acceptance (report must evidence each item):**

- Marketplace `marketplace-distribution` implementation PR **merged** to `cursor-team-marketplace` `main` (GitHub merge status / `gh pr view`).
- Team-harness plugin refreshed in Cursor; vendored `vendor/savepoints-lite/skills/` readable under installed plugin cache (path cited in report).
- Engineering invariants Savepoints section present in **global Cursor User Rules** (summary in report).
- End-to-end Savepoint write confirmed via installed plugin path (Notion MCP + wrapper → vendored router/provider; Savepoint URL or id in report).

**Verdict:** `pass` only if all items evidenced; otherwise `fail` — do not start `consumer-cleanup`.

---

## Slice — consumer-cleanup

**Recommended authority:** Open PR only

**Prerequisite:** `gate-consumer-prereqs` **passed** per gate report evidence (not plan todo status alone).

**Repositories (inventory — seven):** `multipliers-dev/savepoints-lite`, `multipliers-dev/cursor-team-marketplace`, `multipliers-dev/editorial-workflow`, `multipliers-dev/renovate-workflow`, `multipliers-dev/codenames-ai-guesser`, `mastermichaelt/resumes`, `mastermichaelt/portfolio` — extend if grep finds more. Final inventory table is recorded in **`plan-closure`**.

**Rationale:** Redundant per-repo **activation** (npm skill install path, `AGENTS.md` Savepoints Lite session-log section, obsolete `.agents` Savepoints YAML) is obsolete once team-harness + User Rules provide global Savepoints for **every** inventory repo, including the Savepoints Lite hub. Package **verification** on the hub remains required (§ Activation vs verification).

**Agent instruction:** One repo per PR; each PR touches **only** that repository. Do not merge. Do not edit `cursor-team-marketplace` plan files or frontmatter. Stop after opening required PRs (or documenting no-change repos in operator notes for later `plan-closure`).

**Goal (all inventory repos — activation only):**

- Remove redundant Savepoints Lite **activation** from root `AGENTS.md` (and host-specific rules that duplicate it). Preserve unrelated `AGENTS.md` instructions.
- Remove obsolete `.agents/savepoints-notion.yml` (and related Savepoints consumer YAML) when destination now comes from global User Rules via marketplace integration.
- Remove per-repo `dependencies` / `devDependencies` on `@multipliers-dev/savepoints-lite` when skills are no longer loaded from that repo’s `node_modules` for session logging.
- Rely on the globally installed team-harness Savepoints integration for session logging (after gate evidence).

**Goal — `multipliers-dev/savepoints-lite` hub (required migration, not exempt):**

- Apply the same **activation** removal as other consumers (hub `AGENTS.md` Savepoints Lite session-log section; obsolete `.agents` Savepoints config).
- **May** remove the self-`devDependency` on `@multipliers-dev/savepoints-lite@2.0.0` **only if** registry artifact verification remains equivalent (see below).
- **Must preserve:** git `skills/`, templates, publish workflow, `npm run verify` (workspace `npm pack --dry-run` vs `expected-package-paths.txt`), and tests that detect missing/unexpected/modified packaged files **without** deriving expected contents from the artifact under test.
- **Must preserve independent registry verification:** layout and version-specific manifests (e.g. `expected-package-paths-registry-dogfood-<version>.txt`) against an install from the **public registry**, not the workspace tree. Prefer a simple isolated `npm install` / pack-fetch in test or CI over weakening or deleting dogfood invariants.
- Session logging for hub work uses marketplace activation (User Rules + plugin), not `node_modules` router skills for dogfooding instructions.

**Repository-specific preservation (not “no change”):**

| Repository | Remove | Preserve |
| --- | --- | --- |
| `multipliers-dev/savepoints-lite` | Per-repo activation; optional self-`devDependency` only with verification replacement | Canonical package source, release tooling, workspace + registry verification (above) |
| `multipliers-dev/cursor-team-marketplace` | Redundant `AGENTS.md` Savepoints activation only | Root build-time `devDependency` `@2.0.0`, `vendor/savepoints-lite/`, sync/verify scripts |
| Other inventory repos | Redundant deps + activation + obsolete `.agents` | Unrelated repo tooling |

**Exclusions:** No hooks, monitoring, or reliability improvements. No reopening Savepoints Lite OSS publish work. Do not remove marketplace vendored skills or marketplace build-time pin as part of other repos’ cleanup.

**Acceptance:**

- Per-repo: `npm test` / `npm run verify` / `npm run check` (or repo-documented equivalent) **pass** on the PR branch.
- **savepoints-lite hub:** `npm test` and `npm run verify` still enforce workspace tarball layout **and** independent published-artifact checks at least as strong as pre-cleanup (no gate weakening).
- PRs opened (Open PR only). Completion proven by **merged** consumer PRs (or documented no-change) verified again at `plan-closure` — not by opened PRs alone.

---

## Slice — plan-closure

**Recommended authority:** Open PR only

**Rationale:** Archive completed multi-slice plan per repository planning standards.

**Agent instruction:** Docs-only PR in `cursor-team-marketplace` only. **Before** editing the plan to archive: verify prerequisites with GitHub and repository state (`gh pr view`, merged commits on each repo’s `main`). If any check fails, **stop** with a blocker report — do not archive. When all pass: reconcile frontmatter (`marketplace-distribution`, `gate-consumer-prereqs`, `consumer-cleanup`, `plan-closure` → `completed` as applicable), add `# Shipped` with evidence (merged PR links, gate report summary, consumer inventory), move plan to `.cursor/plans/archive/`. Do not merge the closure PR.

**Pre-archive verification (all required):**

1. **Marketplace distribution** — implementation PR **merged** into `multipliers-dev/cursor-team-marketplace` `main` (not open/draft).
2. **Gate** — `gate-consumer-prereqs` **passed**; cite evidence: installed plugin path, User Rules, readable vendored skills, successful E2E Savepoint persistence (from gate report).
3. **Consumer cleanup** — every **seven** inventory repos either has a cleanup PR **merged** to that repo’s `main` or is documented **no change**; no required cleanup PR still open. For **`savepoints-lite`**, merged cleanup must show hub activation removed **and** package verification still passing (`npm test`, `npm run verify`) with independent registry artifact checks preserved.
4. **No open implementation work** — no remaining required slices or unmerged PRs for this initiative.

Do not infer completion from opened PRs or previously pending todos alone.

**Acceptance:** Blocker report if any prerequisite unmet. Otherwise: archive path correct; `# Shipped` includes cross-repo merged PR links + gate + inventory; frontmatter todos reconciled; `npm run validate:plans` passes; closure PR opened (Open PR only).

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

- [ ] `marketplace-distribution` PR **merged** to marketplace `main`; team-harness **1.15.0**; vendor sync/verify in CI
- [ ] `gate-consumer-prereqs` **pass** report with evidence (no tracked plan edit during gate)
- [ ] Consumer cleanup: all **seven** repos — merged PRs (incl. savepoints-lite hub activation migration + verification preserved) or **no change** documented
- [ ] `plan-closure` verifies merges + gate evidence; reconciles todos; `# Shipped`; archive PR opened

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

Authority: Manual verification gate — read-only. No commit, no PR, no tracked plan or repo edits. No consumer repo implementation.

Topology: N/A (operator + filesystem + Notion checks).

Deliverables: pass/fail report with evidence for: marketplace distribution PR merged to main (gh pr view); plugin refreshed; vendored skills readable under ~/.cursor/plugins/cache/.../team-harness; User Rules engineering invariants; end-to-end Savepoint persistence via installed plugin.

Verification: cite commands/paths/URLs in the report. Do not update plan frontmatter. Stop before consumer-cleanup on fail. Todo reconciliation happens in plan-closure when evidence is archived in # Shipped.
```

### consumer-cleanup

```text
@.cursor/plans/2026-10-27-savepoints-marketplace-distribution.plan.md

Implement slice consumer-cleanup only.

Authority: Open PR only — one PR per repo; do not merge.

Prerequisite: gate-consumer-prereqs passed. Stop if not.

Repositories: inventory in plan; prove checkout identity per repo.

Topology: each consumer repo branches from origin/main; PR base main; one slice per PR.

Deliverables: For all seven inventory repos (including savepoints-lite hub): remove redundant Savepoints activation (AGENTS.md session-log section, obsolete .agents Savepoints YAML, savepoints-lite npm dep when only used for activation). Use global team-harness + User Rules for session logging.

savepoints-lite hub only: preserve skills/, templates, publish tooling, npm run verify (workspace tarball), and independent registry artifact tests (version-specific expected manifests; isolated npm install if self-devDependency removed). Do not weaken package invariants. cursor-team-marketplace only: remove AGENTS activation; preserve root devDependency @2.0.0 and vendor/savepoints-lite/. Note no-change repos for plan-closure (operator notes — not marketplace plan edits).

Verification: per-repo npm test/verify/check. Hub must still pass npm test and npm run verify with registry verification equivalent or stronger. Do not edit cursor-team-marketplace plan files from consumer repos.
```

### plan-closure

```text
@.cursor/plans/2026-10-27-savepoints-marketplace-distribution.plan.md

Implement slice plan-closure only.

Authority: Open PR only — docs-only. Do not merge.

Topology: branch from origin/main in cursor-team-marketplace; PR base main.

Deliverables: If prerequisites unmet, blocker report only — do not archive. If met: reconcile frontmatter (marketplace-distribution, gate-consumer-prereqs, consumer-cleanup, plan-closure completed); # Shipped with merged PR links, gate evidence summary, consumer inventory (merged PR or no change per repo); move plan to .cursor/plans/archive/2026-10-27-savepoints-marketplace-distribution.plan.md.

Verification: gh pr view (merged) for marketplace distribution PR and each required consumer cleanup PR (all seven inventory repos); for savepoints-lite merged PR confirm CI-equivalent npm test + npm run verify on main with registry artifact checks intact; confirm gate pass evidence; confirm no open required PRs. npm run validate:plans. No production code changes.
```
