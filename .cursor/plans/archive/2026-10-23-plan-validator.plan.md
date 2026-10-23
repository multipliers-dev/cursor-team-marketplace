---
name: Plan validator
overview: Add a canonical TypeScript plan validator under team-harness, wire marketplace CI, establish centralized consumption (@multipliers-dev/plan-validator npm CLI + reusable workflow), roll out to applicable consumer repos without vendoring source, then document verified adoption—no duplicated validator source; npm publish is a separate authorized step after the marketplace PR.
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
  - id: centralized-consumption
    content: "PR: @multipliers-dev/plan-validator package + reusable GHA workflow; tarball verification; publish workflow (no publish in PR); consumer smoke after publication"
    status: completed
  - id: consumer-adoption
    content: "Cross-repo: inventory consumers, per-repo workflow PRs, adoption matrix; plan-status PR when rollout complete"
    status: completed
  - id: docs-skill
    content: "PR: plan-validation.md; align SKILL.md item 7 todo/prompt rule with validator; README scripts table; adoption docs for both consumption paths"
    status: completed
  - id: plan-closure
    content: "Docs-only PR after last slice: add # Shipped note, move plan to .cursor/plans/archive/2026-10-23-plan-validator.plan.md"
    status: completed
isProject: false
---

# Shipped

**Date:** 23 Oct 2026

Deterministic plan validation (team-harness) — all slices merged; npm `@multipliers-dev/plan-validator` and reusable workflow adopted across six consumer repositories.

### Marketplace PRs

| Slice | PR |
| --- | --- |
| plan-review | [#57](https://github.com/multipliers-dev/cursor-team-marketplace/pull/57) |
| plan-validate-lib | [#58](https://github.com/multipliers-dev/cursor-team-marketplace/pull/58) |
| fixtures-tests | [#59](https://github.com/multipliers-dev/cursor-team-marketplace/pull/59) |
| ci-npm | [#60](https://github.com/multipliers-dev/cursor-team-marketplace/pull/60) |
| centralized-consumption (implementation) | [#63](https://github.com/multipliers-dev/cursor-team-marketplace/pull/63) |
| centralized-consumption (plan-status) | [#64](https://github.com/multipliers-dev/cursor-team-marketplace/pull/64) |
| consumer-adoption (plan-status Phase B) | [#65](https://github.com/multipliers-dev/cursor-team-marketplace/pull/65) |
| docs-skill | [#66](https://github.com/multipliers-dev/cursor-team-marketplace/pull/66) (merge `9f35719`) |
| plan-closure | (this PR) |

### npm package and publish

- **docs-skill** completed: PR [#66](https://github.com/multipliers-dev/cursor-team-marketplace/pull/66) merged at `9f357193ee149ecbf514f73f95de2d6d0ef8217e`.
- **`@multipliers-dev/plan-validator@0.1.1`** published 2026-10-23 via manual workflow [Publish plan-validator (manual)](https://github.com/multipliers-dev/cursor-team-marketplace/actions/runs/39898524547) (OIDC trusted publishing with provenance; built from `9f35719`). Registry: dist-tag `latest` = `0.1.1`; `npm audit signatures` shows verified registry signature and verified attestation (SLSA provenance v1); tarball contains `package/package.json`, `package/README.md`, `package/dist/plan-validator.mjs`; homepage/bugs set; `engines.node` `>=22`. CLI smoke on Node 22: no plans → exit 1 (`discovery.empty`); `--allow-empty` → exit 0; unknown option → exit 2; invalid plan → exit 1 (`frontmatter.todos`).
- **`0.1.0`** was a local bootstrap publish with `--no-provenance`; **`0.1.1`** is the first trusted-publishing release (README/metadata-focused relative to `0.1.0`).
- **Consumer pins:** six adopt repositories still use `validator_version: "0.1.0"` and reusable workflow `uses: …@refs/tags/plan-validator-workflow-v1.0.0` (protected by ruleset **Protect plan-validator workflow releases**, id `25695885`). Bumping consumers to `0.1.1` is optional follow-up, not part of this plan.

### Consumer adoption (Phase A merges + pins)

| Repository | Decision | Adoption PR |
| --- | --- | --- |
| mastermichaelt/mastermichaelt | EXCLUDE | — (profile README only) |
| multipliers-dev/renovate-workflow | ADOPT | [#56](https://github.com/multipliers-dev/renovate-workflow/pull/56) |
| multipliers-dev/editorial-workflow | ADOPT | [#27](https://github.com/multipliers-dev/editorial-workflow/pull/27) |
| multipliers-dev/codenames-ai-guesser | ADOPT | [#633](https://github.com/multipliers-dev/codenames-ai-guesser/pull/633) |
| mastermichaelt/portfolio | ADOPT | [#83](https://github.com/mastermichaelt/portfolio/pull/83) |
| mastermichaelt/resumes | ADOPT | [#217](https://github.com/mastermichaelt/resumes/pull/217) |
| multipliers-dev/savepoints | ADOPT | [#87](https://github.com/multipliers-dev/savepoints/pull/87) |

**Workflow tag:** `plan-validator-workflow-v1.0.0` → annotated tag `6dcfe2a462ebfacc9825df3ecf95886961748802` (peels to `9b16a15835bffec3f6e5e9d5bd071c99db74b188`).

### Optional follow-ups (not executed in this plan)

- Bump consumer `validator_version` pins from `0.1.0` to `0.1.1` when desired.
- Delete disposable smoke branch `smoke/plan-validator-0.1.0` on `mastermichaelt/resumes` when no longer needed.

---

# Deterministic plan validation (team-harness)

## Recommended execution authority

| Slice                    | Recommended authority | Agent instruction                                      |
| ------------------------ | --------------------- | ------------------------------------------------------ |
| plan-review              | Plan-only PR          | Do not implement. Stop after opening the plan-only PR. |
| plan-validate-lib        | Open PR only          | Do not merge. Stop after opening the PR.               |
| fixtures-tests           | Open PR only          | Do not merge. Stop after opening the PR.               |
| ci-npm                   | Open PR only          | Do not merge. Stop after opening the PR.               |
| centralized-consumption  | Open PR only          | Do not merge. Stop after opening the PR.               |
| consumer-adoption        | Open PR only          | Do not merge. Stop after opening the PR.               |
| docs-skill               | Open PR only          | Do not merge. Stop after opening the PR.               |
| plan-closure             | Open PR only          | Do not merge. Stop after opening the PR.               |

Repo default: **Open PR only** (see team skill `/planning-methodology`).

## Repository topology (default)

Multi-slice plans stack execution order, not Git branches. Integration branch is `main`.

**Before implementation:** start from latest `origin/main`.

**Before opening the PR:** branch represents only this slice — prior-slice work is on the integration branch, not via branch ancestry.

**After opening the PR:** GitHub PR base is `main`; diff excludes prior-slice work except through merged `main`.

The authoritative plan file lives in **`multipliers-dev/cursor-team-marketplace`**. Slices through `ci-npm` are same-repo. **`centralized-consumption`** requires one consumer repository **selected and explicitly authorized by Michael** for **smoke verification only** (see that slice); marketplace implementation and consumer smoke may run in **separate** Cloud Agent sessions. **`consumer-adoption`** rolls out workflow configuration across applicable repositories via **separate per-repo PRs** plus a **plan-status PR** in this repo. Do not assume GitHub App access means required repositories are checked out—Cloud Agents launched against one repository receive credentials for that repository only; each consumer repo needs its own launch, preflight, and checkout identity proof before edits.

### Repository inventory

| Role | Repository |
| --- | --- |
| **Canonical source** | `multipliers-dev/cursor-team-marketplace` |
| **Candidate consumers** (inspect in **`consumer-adoption`**; smoke target in **`centralized-consumption`**) | See list below |

**Candidate consumers:**

- `mastermichaelt/resumes` — proposed smoke-test consumer for **`centralized-consumption`** (subject to Michael’s explicit authorization, access, and checkout preflight)
- `mastermichaelt/portfolio`
- `mastermichaelt/mastermichaelt`
- `multipliers-dev/editorial-workflow`
- `multipliers-dev/renovate-workflow`
- `multipliers-dev/codenames-ai-guesser`
- `multipliers-dev/savepoints`

Both GitHub accounts (`mastermichaelt`, `multipliers-dev`) may be reachable via the connected GitHub integration, but **GitHub API / App access alone is not proof of a local checkout**. Each repository still requires its own checkout and identity preflight (`pwd`, `git remote get-url origin`) in the environment that executes work for that repo.

---

## Context from reconnaissance

| Area | Current state |
| --- | --- |
| Methodology | Canonical procedure in [`plugins/team-harness/skills/planning-methodology/SKILL.md`](../../plugins/team-harness/skills/planning-methodology/SKILL.md), skeleton in [`_template.plan.md`](../../plugins/team-harness/skills/planning-methodology/_template.plan.md) |
| Consuming repos (planned, post-`centralized-consumption`) | Target: pinned `@multipliers-dev/plan-validator` npm CLI (agents/local) plus reusable workflow for CI—**no** validator source copy |
| Marketplace CI | [`scripts/check.sh`](../../scripts/check.sh) + Vitest; `validate:plans` / `validate:plans:template` on `main` |
| Prior art | Resumes `validate:lifecycle` pattern; plan validator shipped in `plan-validate-lib` through `ci-npm` |

```mermaid
flowchart LR
  canonical["plugins/team-harness/scripts/plan-validate"]
  marketplaceCI["cursor-team-marketplace CI"]
  fixtures["scripts/fixtures/plan-validate"]
  npmPkg["@multipliers-dev/plan-validator npm CLI"]
  reusableWF["Reusable GHA workflow in marketplace"]
  consumerPlans["Consuming repository .cursor/plans"]

  canonical --> marketplaceCI
  fixtures --> marketplaceCI
  canonical --> npmPkg
  canonical --> reusableWF
  npmPkg --> consumerPlans
  reusableWF --> consumerPlans
```

**Motivation:** recurring planning-conformance defects in consuming repos (authority, acceptance/verification, todo/prompt mismatch, topology, structural contradictions). Catch structural violations deterministically; keep semantic merge-safety review (Bugbot, humans).

---

## Architectural decisions

### 2026-10-23 — Centralized consumption (no copy vendoring)

Copy-only vendoring of validator TypeScript is **no longer desired**. The validator and planning methodology stay centrally maintained in `cursor-team-marketplace`. Consumers must not copy validator source or maintain independent validator implementations.

Two consumption paths, both using the **same canonical validator implementation** in this repository:

1. **Published npm CLI:** `@multipliers-dev/plan-validator` (exact semver pin) for agents and local runs.
2. **Centralized CI:** reusable GitHub Actions workflow in `cursor-team-marketplace`, invoking the same npm CLI version.

The team-harness **plugin** distributes methodology/skills; it does **not** replace installing or pinning the npm CLI. Installing the plugin does **not** configure consumer CI. Rollout pins are **`consumer-adoption`**; **`docs-skill`** documents verified adoption (PR 61).

#### 2026-10-23 (later) — npm package supersedes plugin-execution distribution

**Supersedes** (historical): plugin-bundled `dist/validate-plans.mjs`, `run-plan-validate.sh`, plugin path heuristics, and reusable-workflow `marketplace_ref` checkout of TypeScript sources.

**Reason:** unverified plugin install paths, unverified env vars, `npx`/yaml resolution failures, and duplicate artifact drift.

**Current model:** `packages/plan-validator/` builds from `plugins/team-harness/scripts/`; consumers pin npm version + workflow `validator_version`. Publishing requires separate authorization (not in the marketplace implementation PR).

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

## Slice — centralized-consumption

**Recommended authority:** Open PR only

**Rationale:**

- Validator on `main` is proven in marketplace CI; consumers need **centralized** execution paths without copying source
- Plugin and reusable-workflow surfaces must be implemented and smoke-tested before **`consumer-adoption`** rollout and **`docs-skill`**
- Marketplace implementation is a **single merge-safe PR** in this repo; **production rollout** across consumers belongs to **`consumer-adoption`**, not this slice

**Agent instruction:** Do not merge. Open the marketplace PR only after required smoke evidence exists (see Completion recording)—smoke may be produced in a separate session before the PR is presented as ready. Stop after opening the PR.

**Goal:** Establish centralized validator execution via a published npm CLI (package + publish workflow in-repo; **no publish in this PR**) and a reusable GitHub Actions workflow—without distributing source-code copies.

**Topology:**

- **Implementation PR** in `multipliers-dev/cursor-team-marketplace`: `packages/plan-validator/`, reusable workflow (`validator_version` pin), tarball-based marketplace CI verification, manual publish workflow (OIDC).
- **Post-publication smoke** on **`mastermichaelt/resumes`** (registry-mode CLI + reusable workflow)—separate session after Michael authorizes npm publish; not required to open the marketplace PR.
- Do **not** assume one environment holds checkouts for marketplace and consumer repos.

**Feasibility note (verified in PR evolution):**

- `cursor-team-marketplace` is **public**; consumers can call reusable workflows cross-owner (`mastermichaelt/*`).
- Caller workflows use minimal `permissions` (`contents: read`).
- **`marketplace_ref` / plugin install paths were abandoned** in favor of npm CLI pinning (see Architectural decisions).

**Deliverables:**

- `@multipliers-dev/plan-validator@0.1.0` package (build from canonical TS; tarball verify; publish workflow defined, not executed).
- Reusable workflow invoking pinned npm CLI (registry-only); marketplace tarball verification via CI job/scripts only (not callable from consumer repos).
- [`centralized-consumption.md`](../../plugins/team-harness/docs/centralized-consumption.md) (npm model, abandoned plugin path, pinning, publish prerequisites).
- Narrow planning-methodology SKILL invocation notes (npm exec; plugin ≠ npm package).
- Mark `centralized-consumption` **completed** only after **published** CLI smoke on authorized consumer—**not** in this PR if publish has not happened.

**Required repositories:**

- `multipliers-dev/cursor-team-marketplace` — implementation PR, read/write.
- **`mastermichaelt/resumes`** — post-publish smoke (when authorized); historical reusable-workflow smoke at `f1ca17c` applies to superseded implementation only.

**Acceptance:**

- Single canonical TS source; npm package builds distributable CLI (esbuild; yaml bundled).
- Reusable workflow: exact `validator_version` semver; caller checkout isolation; no `github.workflow_ref` / `marketplace_ref` parsing.
- Tarball install smoke + parity tests without consumer `node_modules` on resolution path.
- Preserve validator contract (`--repo-root`, `--profile template`, `--allow-empty`, exit codes).
- Document publish prerequisites; do **not** publish in this slice.

**Verification:**

- Marketplace PR: `npm ci`; `typecheck`; `npm test`; `validate:plans`; `validate:plans:template`; `sh scripts/check.sh`; `npm run verify:plan-validator`; tarball smoke script.
- Reusable workflow registry mode **not** fully testable until publish; marketplace CI uses `plan-validator-tarball-ci` job + tarball scripts (not exposed via `workflow_call`).
- Plan file passes `validate:plans`.

**Prerequisites:**

- `ci-npm` merged.

**Status:** completed (2026-10-23 plan-status PR).

**Evidence (2026-10-23):**

- npm registry: `@multipliers-dev/plan-validator@0.1.0` is public. bin `{"plan-validator":"dist/plan-validator.mjs"}`, tarball https://registry.npmjs.org/@multipliers-dev/plan-validator/-/plan-validator-0.1.0.tgz, integrity `sha512-6+Zmg1zMkb6XgZiDnuHNA/7a293+dbAyXnmGdR9K9v+vw0bPlueUZhgTNMJ70KxUO1pTT4Wk4wqm0kBMWrQsTQ==`. Bootstrap publish was manual with --no-provenance (expected for the first release); later releases go through publish-plan-validator.yml with OIDC.
- Published CLI via `npm exec --yes --package=@multipliers-dev/plan-validator@0.1.0 -- plan-validator`, run with a fresh npm cache on Node v22.23.4 / npm 10.9.9: valid plan exit 0 (`ok plan validation`); invalid plan exit 1 (`[prompts.section]`); `--bad-flag` exit 2 (`error: unknown option --bad-flag`); empty discovery with `--allow-empty` exit 0 (`skip plan validation`). The npx cache `.bin/plan-validator` symlinks to `dist/plan-validator.mjs`, and the lockfile integrity matches the registry dist.integrity.
- Reusable workflow smoke test in mastermichaelt/resumes on the disposable branch `smoke/plan-validator-0.1.0` (no PR, main untouched). It calls `multipliers-dev/cursor-team-marketplace/.github/workflows/validate-plans.yml@9b16a15835bffec3f6e5e9d5bd071c99db74b188` with validator_version 0.1.0, allow_empty true, contents: read:
  - No active plans: success, https://github.com/mastermichaelt/resumes/actions/runs/39883621444 (9e71667)
  - Valid plan: success, https://github.com/mastermichaelt/resumes/actions/runs/39883735697 (9f2c7ba)
  - Invalid plan: failure as expected with `[prompts.section]` on `/home/runner/work/resumes/resumes/caller/.cursor/plans/2026-10-23-plan-validator-smoke-valid.plan.md`, https://github.com/mastermichaelt/resumes/actions/runs/39883785379 (b3d0ca1)
  - Logs show `CALLER_ROOT: /home/runner/work/resumes/resumes/caller` and only resumes plan paths, so it validated the caller checkout and not marketplace plans. One intermediate run (39883681181, fac3ff3) failed on a bad local edit (`[frontmatter.delimiter]`) and is excluded.

---

## Slice — consumer-adoption

**Recommended authority:** Open PR only

**Rationale:**

- Centralized plugin and reusable workflow must exist on `main` before configuring consumers
- Each consumer repository is an independent merge-safe PR; completion is recorded via **plan-status PR** in this repo (cross-repo slice)
- GitHub App access to a repository does **not** prove it is checked out in the active Cloud Agent environment

**Agent instruction:** Do not merge. Open per-repo adoption PRs in consumer repositories and **stop**—do not merge adoption PRs. **Never** mark `consumer-adoption` completed from a consumer repo or while adoption PRs are still open. After Michael merges the adoption PR(s), a **separate** plan-status PR in `cursor-team-marketplace` records the adoption matrix and marks `consumer-adoption` completed (planning-methodology item 5, cross-repo completion).

**Goal:** Roll out the centrally maintained plan validator to all applicable repositories that consume team-harness / planning-methodology, without vendoring validator source code.

**Topology:**

- **Phase A — adoption PRs:** per-consumer implementation PR(s) in each **adopt** repository (workflow reference, permissions, any repo-specific config)—one PR per repo, independently merge-safe, **Open PR only**; agent stops after opening.
- **Phase B — plan-status PR (later):** in `multipliers-dev/cursor-team-marketplace` **after** adoption PR(s) are **merged** by Michael: record matrix, links, pins, deferrals/exclusions; mark `consumer-adoption` completed—do **not** edit the plan from consumer repos.

**Deliverables:**

- **Phase A:** inspection notes and draft **adoption matrix** (seven candidates); open one configuration PR per **adopt** repository (links recorded; PRs remain open until Michael merges)
- **Phase B (after merges):** plan-status PR in `cursor-team-marketplace` with final adoption matrix (decision + rationale per repo, PR links, pinned validator versions, deferrals, exclusions) and frontmatter `consumer-adoption` → `completed`

**Required repositories:**

- `multipliers-dev/cursor-team-marketplace` — plan owner, reusable workflow host, plan-status PR target, read/write.
- **Each of the seven candidate consumer repositories** listed under Repository inventory — inspect with read-only preflight when not editing; read/write only when opening that repo’s adoption PR and only when that repo is a **real checkout** in the agent environment with identity proved via preflight (not App/API access alone). Launch one Cloud Agent (or session) per consumer repo as needed.

**Acceptance:**

1. Inspect **all seven candidate consumers** from the Repository inventory to determine which actually use planning methodology / team-harness, their active-plan conventions (plan paths, `archive/`, template usage), GitHub Actions configuration, and whether centralized validation is appropriate.
2. Produce an adoption matrix with a **decision and rationale per repository** (**adopt** / **defer** / **exclude**), plus pins and PR links once known. Do **not** automatically exclude a repository because it has no current active plans—the validator supports `--allow-empty` for that case.
3. Confirm that **`@multipliers-dev/plan-validator`** and the reusable GitHub Actions workflow were implemented and verified in **`centralized-consumption`** (including post-publish consumer smoke) before beginning adoption.
4. Configure each **adopt** repository to invoke the reusable workflow with pinned **`validator_version`** (exact semver) and pinned workflow `uses:@sha`.
5. Preserve existing repository-specific CI checks, permissions and branch protection.
6. Do not copy validator TypeScript files or duplicate the planning methodology (use published npm CLI pins).
7. Test each **adopt** repository independently, covering valid plans, invalid plans, and repositories without active plans (`--allow-empty`).
8. Open a **separate implementation PR for each adopt repository**. Do not merge automatically.
9. Record adoption status, PR links, pinned validator versions, deferrals, and deliberate exclusions in the matrix.
10. After Michael merges consumer adoption PR(s), record completion through a **separate** plan-status PR in `cursor-team-marketplace` (do not combine with Phase A in one agent stop).

**Verification:**

- Preflight: for each candidate inspected or edited, prove checkout exists, `pwd` and `git remote get-url origin` match expected owner/name, and minimum capability for declared role before edits
- Phase A: each opened adoption PR runs reusable workflow against **that** repo’s checkout; evidence for valid-plan pass, invalid-plan fail, and `--allow-empty` / no-active-plans behavior where applicable; plan file **not** edited in consumer repos
- Phase B: plan-status PR only after adoption PR merges; frontmatter marks `consumer-adoption` completed; matrix lists **all seven** candidates with decision, rationale, pins, and PR links (or documented defer/exclude)

**Notes (deferred from centralized-consumption smoke, 2026-10-23):**

- Delete the smoke branch `smoke/plan-validator-0.1.0` once it's no longer needed.

**Prerequisite:** `centralized-consumption` merged.

**Status:** completed (2026-10-23 plan-status PR).

**Evidence (2026-10-23):**

- **Consumer pins (all adopt repositories):** `validator_version: "0.1.0"` (`@multipliers-dev/plan-validator@0.1.0`). Reusable workflow `uses: multipliers-dev/cursor-team-marketplace/.github/workflows/validate-plans.yml@refs/tags/plan-validator-workflow-v1.0.0`. Workflow tags and npm versions are versioned independently.
- **Seven-repository adoption matrix (Phase A):**

| Repository | Methodology / plans | Active plans / template | CI / tooling | Decision | Rationale | Template / plan fixes | Adoption PR | Phase A smoke runs |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| mastermichaelt/mastermichaelt | No | None, no `.cursor/plans` | No workflows, no Node tooling | EXCLUDE | Profile README only repo, no methodology use or plausible future use | N/A | N/A | N/A (local CLI with `--allow-empty`, exit 0) |
| multipliers-dev/renovate-workflow | Yes, `.cursor/plans` with 6 archived plans and team-harness hooks | No active plans, no template | npm, Node 22.22.1, Husky; ci/release/renovate/validate-renovate-config/agent-plugins-spec-drift | ADOPT | Past methodology use; `--allow-empty` covers zero active plans | None | [PR 56](https://github.com/multipliers-dev/renovate-workflow/pull/56) | empty pass [39891836112](https://github.com/multipliers-dev/renovate-workflow/actions/runs/39891836112), invalid fail [39891932607](https://github.com/multipliers-dev/renovate-workflow/actions/runs/39891932607) `[prompts.section]`, valid pass [39891976475](https://github.com/multipliers-dev/renovate-workflow/actions/runs/39891976475) (workflow_dispatch 403, so smoke branches used push triggers) |
| multipliers-dev/editorial-workflow | Yes, methodology-shaped plans and team-harness hooks | No active plans, 4 archived, no template | ci.yml, Node 22, npm ci/test/typecheck, Husky | ADOPT | Uses the methodology plan layout; allow_empty covers the empty set | None | [PR 27](https://github.com/multipliers-dev/editorial-workflow/pull/27) | empty pass [39891868111](https://github.com/multipliers-dev/editorial-workflow/actions/runs/39891868111), invalid fail [39891938591](https://github.com/multipliers-dev/editorial-workflow/actions/runs/39891938591) `[prompts.section]`, valid pass [39891998030](https://github.com/multipliers-dev/editorial-workflow/actions/runs/39891998030) (dispatch 403, so push on smoke branches) |
| multipliers-dev/codenames-ai-guesser | Yes, planning-standards, big archive, team-harness refs | No active plans; `.cursor/plans/_template.plan.md` | npm workspaces, Node 24, path-aware Husky plus ci.yml | ADOPT | Staged planning is established here; an empty active set is normal between initiatives | Template failed strict profile; minimal fix (Slice headings; removed a nested fenced Merge-granted example that caused authority.mismatch) | [PR 633](https://github.com/multipliers-dev/codenames-ai-guesser/pull/633) | empty+template pass [39891914856](https://github.com/multipliers-dev/codenames-ai-guesser/actions/runs/39891914856), invalid fail [39891968950](https://github.com/multipliers-dev/codenames-ai-guesser/actions/runs/39891968950) `[prompts.section]`, valid pass [39892026965](https://github.com/multipliers-dev/codenames-ai-guesser/actions/runs/39892026965) |
| mastermichaelt/portfolio | Yes, active plan plus archive, template, planning-standards, merge-safe rule | Active: `2026-10-08-assistant-grounded-rag-generation.plan.md`; `_template.plan.md` | npm, Node 24, Husky; ci.yml and Renovate | ADOPT | Staged planning in active use | Template: slice headings and nested fence. ACTIVE PLAN edited mechanically (slice headings, plan-closure Rationale, operational-acceptance Verification line) | [PR 83](https://github.com/mastermichaelt/portfolio/pull/83) | valid pass [39891932142](https://github.com/mastermichaelt/portfolio/actions/runs/39891932142), invalid fail [39892016529](https://github.com/mastermichaelt/portfolio/actions/runs/39892016529) (temporary commit on the PR branch, then reverted), post-revert pass [39892063341](https://github.com/mastermichaelt/portfolio/actions/runs/39892063341), empty via local CLI only |
| mastermichaelt/resumes | Yes, archive plus template, merge-safe, planning-standards, AGENTS.md | No active plans; `_template.plan.md` | Node 24; ci.yml (npm run check plus visual regression); Husky | ADOPT | Known methodology consumer; allow_empty | Template failed strict profile: slice headings fixed, HTML examples moved before Agent prompts (fixes authority.mismatch) | [PR 217](https://github.com/mastermichaelt/resumes/pull/217) | empty+template pass [39891925647](https://github.com/mastermichaelt/resumes/actions/runs/39891925647), invalid fail [39892084356](https://github.com/mastermichaelt/resumes/actions/runs/39892084356) `[prompts.section]`, valid pass [39892141663](https://github.com/mastermichaelt/resumes/actions/runs/39892141663) |
| multipliers-dev/savepoints | Yes, methodology-shaped plans and team-harness hooks | No active plans; no template | npm, Node, Husky; ci.yml | ADOPT | Past methodology use; empty active set between initiatives | Archived plans use legacy slice headings (all todos completed, so not validated under strict profile) | [PR 87](https://github.com/multipliers-dev/savepoints/pull/87) | Phase A smoke on PR branch; post-merge validate run recorded below |

- **Resumes template deferral (from centralized-consumption):** resolved in [resumes PR 217](https://github.com/mastermichaelt/resumes/pull/217) (strict template profile now passes with slice headings and HTML examples moved before Agent prompts).
- **Six merged adoption PRs** (merge commits on each repo’s `main`, merged 2026-10-23 by Michael’s authorization). Post-retag validate runs use `Uses: multipliers-dev/cursor-team-marketplace/.github/workflows/validate-plans.yml@refs/tags/plan-validator-workflow-v1.0.0 (6dcfe2a462ebfacc9825df3ecf95886961748802)`:
  - resumes [217](https://github.com/mastermichaelt/resumes/pull/217): merge `e3e456053eeb2373daf89115e0eea9084994a523` (head `7d24d1e`), run [39894344869](https://github.com/mastermichaelt/resumes/actions/runs/39894344869)
  - portfolio [83](https://github.com/mastermichaelt/portfolio/pull/83): merge `e27f22ee825314ebeafc9ee0d0018253fe58db47` (head `cb0c27d`), run [39894350131](https://github.com/mastermichaelt/portfolio/actions/runs/39894350131)
  - editorial-workflow [27](https://github.com/multipliers-dev/editorial-workflow/pull/27): merge `f2a9b74e781060f1339ef7252eac8bd50d416320` (head `e523253`), run [39894334086](https://github.com/multipliers-dev/editorial-workflow/actions/runs/39894334086)
  - renovate-workflow [56](https://github.com/multipliers-dev/renovate-workflow/pull/56): merge `5fa7b90683dd2ad220825718bc0418ac5b6ce56a` (head `cfcc53c`), run [39894341982](https://github.com/multipliers-dev/renovate-workflow/actions/runs/39894341982)
  - codenames-ai-guesser [633](https://github.com/multipliers-dev/codenames-ai-guesser/pull/633): merge `b17df54d447880f5e78ade7b30d93d4ef3eeabf2` (head `907b6c3`), run [39894373000](https://github.com/multipliers-dev/codenames-ai-guesser/actions/runs/39894373000)
  - savepoints [87](https://github.com/multipliers-dev/savepoints/pull/87): merge `f15888ed487079b03246138e4ecaddcac739c7ef` (head `ae30b5b`), run [39894360531](https://github.com/multipliers-dev/savepoints/actions/runs/39894360531)
- **Post-merge Validate plans on `main` (API):** this agent token could confirm `multipliers-dev/renovate-workflow` run [39895210275](https://github.com/multipliers-dev/renovate-workflow/actions/runs/39895210275) (`conclusion: success`, `head_sha: 5fa7b90683dd2ad220825718bc0418ac5b6ce56a`) on the merge commit. Check runs / workflow-run APIs returned **404** for `mastermichaelt/*` repos and for several other consumer repos from this credential scope—could not independently confirm each merge-commit run via API here; post-retag run URLs above are the recorded evidence from Phase A merges.
- **Workflow tag `plan-validator-workflow-v1.0.0`:** annotated tag object `6dcfe2a462ebfacc9825df3ecf95886961748802`, peels to commit `9b16a15835bffec3f6e5e9d5bd071c99db74b188` ([PR 63](https://github.com/multipliers-dev/cursor-team-marketplace/pull/63) merge). Re-verified:

```text
$ git ls-remote origin 'refs/tags/plan-validator-workflow-v1.0.0*'
6dcfe2a462ebfacc9825df3ecf95886961748802	refs/tags/plan-validator-workflow-v1.0.0
9b16a15835bffec3f6e5e9d5bd071c99db74b188	refs/tags/plan-validator-workflow-v1.0.0^{}
$ git rev-parse 'plan-validator-workflow-v1.0.0:.github/workflows/validate-plans.yml'
9b931cd15e52bdecb9e3fd213ba863a587d095b4
```

  - `validate-plans.yml` at tag: git blob `9b931cd15e52bdecb9e3fd213ba863a587d095b4`, sha256 `b0bf1b673c095a5fd75ec64ab404494dd59f05ebb68b52af9efd51458f652c4e`.
- **Tag protection:** active ruleset **Protect plan-validator workflow releases** (id `25695885`), target `tag`, `refs/tags/plan-validator-workflow-v*`, rules `deletion`, `non_fast_forward`, `update` (restrict updates and deletions); `current_user_can_bypass: never`. Immutable releases not enabled.

---

## Slice — docs-skill

**Recommended authority:** Open PR only

**Rationale:**

- **Verified real-world adoption** (`consumer-adoption`) must precede installation and adoption documentation
- **Normative skill text must match validator** (actionable vs completed/cancelled prompt headings)
- Open [PR 61](https://github.com/multipliers-dev/cursor-team-marketplace/pull/61) (`cursor/docs-skill-1253`) holds independently valid docs/methodology work; **keep and rebase/update** it after `consumer-adoption` completes—do not discard—then extend with adoption guidance grounded in the adoption matrix and both consumption paths

**Agent instruction:** Do not merge. Stop after opening the PR.

**Goal:** Document centralized adoption (plugin + reusable CI) and align planning-methodology with the enforced contract.

**Acceptance:**

- New [`plugins/team-harness/docs/plan-validation.md`](../../plugins/team-harness/docs/plan-validation.md): distinguish (a) plugin availability and agent-side execution, (b) GitHub CI enforcement via reusable workflow reference, (c) consumer-specific configuration; version pinning, permissions, updates, failure behavior; **do not** recommend copy-only vendoring or npm install of the validator
- Extend/reconcile with PR 61 content (`plan-validation.md`, SKILL item 7, Plan validation subsection, `reference.md` / `_template.plan.md`, README scripts row) after rebasing on `main` post-`consumer-adoption`; cite verified rollout examples from the adoption matrix where applicable
- [`planning-methodology/SKILL.md`](../../plugins/team-harness/skills/planning-methodology/SKILL.md):
  - **Revise item 7** (and any duplicate wording in staged authoring): require `### <todo-id>` for **actionable** todos (`pending`, `in_progress`); **completed** and **cancelled** todos may omit prompts; any existing `###` under Agent prompts must reference a known todo id (no orphans/duplicates)
  - Add **Plan validation** subsection (when to run `validate:plans`, deterministic vs semantic review, how consumers invoke validation without copying source)
- Mirror the todo/prompt rule in [`reference.md`](../../plugins/team-harness/skills/planning-methodology/reference.md) and boilerplate note in [`_template.plan.md`](../../plugins/team-harness/skills/planning-methodology/_template.plan.md) if they still say every todo requires a heading
- [`team-harness/README.md`](../../plugins/team-harness/README.md) scripts table updated

**Verification:**

- `sh scripts/check.sh`
- `npm test`
- Read/grep confirms SKILL item 7 matches validator todo/prompt rules and docs describe both consumption paths without implying plugin install configures CI automatically

**Prerequisite:** `consumer-adoption` merged (consumer PRs merged and plan-status PR recorded completion).

**Notes (deferred from centralized-consumption, 2026-10-23):**

- The npm package has no README; docs-skill adds one with 0.1.1 or later.

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
- **Target consumption model (after centralized-consumption):**
  - **(a) Agents/local:** `npm exec` with exact `@multipliers-dev/plan-validator` version pin.
  - **(b) CI:** reusable workflow with exact `validator_version` and marketplace workflow `uses:@sha`; validation runs in the **caller’s** checkout.
  - **(c) Methodology:** team-harness plugin for planning skills; does **not** install the npm CLI or CI.
- **Not recommended:** copy-only vendoring of validator source, forked implementations, or unpinned `latest` npm versions.
- Applicable-repo rollout is **`consumer-adoption`**; smoke verification in **`centralized-consumption`** is not a substitute for the adoption matrix.

---

## Slice — plan-closure

**Recommended authority:** Open PR only

**Rationale:**

- Docs-only archival; human review of closure checklist
- Must confirm **`centralized-consumption`**, **`consumer-adoption`** (including merged consumer PRs and plan-status PR), and **`docs-skill`** actually merged, with documented exceptions for repos not adopting the validator

**Agent instruction:** Do not merge. Stop after opening the PR.

After `centralized-consumption`, `consumer-adoption`, and `docs-skill` merge:

1. Verify implementation PRs are actually merged to each target repository’s integration branch (`main`) — do not trust frontmatter `completed` alone. Include marketplace PR(s), **each merged consumer adoption PR**, the **consumer-adoption plan-status PR**, and **`docs-skill`**; follow **multi-repo environment preflight** and **checkout identity** when verifying linked repos.
2. Verify the adoption matrix documents any repositories **deliberately excluded** from validator CI (with rationale)
3. Verify remaining todos are `completed` or `cancelled`
4. Verify Manual verification gate verdicts / allowed artifacts when applicable
5. Add `# Shipped` with date, PR links across all repos touched, pinned validator versions, adoption exceptions, deferred work
6. Move to `.cursor/plans/archive/2026-10-23-plan-validator.plan.md`
7. Mark `plan-closure` completed; update agent prompt references to the archived path
8. No production behavior changes

**Prerequisite:** `docs-skill` merged.

---

## Agent prompts (copy/paste for Cursor)

Use a **fresh Agent-mode chat** per slice. Headings use frontmatter `id` values exactly.

### plan-review

```text
@.cursor/plans/archive/2026-10-23-plan-validator.plan.md

Execute only plan-review. Do not start plan-validate-lib or later slices.

Authority: Plan-only PR — commit the plan artifact only; do not implement. Stop after opening the plan-only PR.

Topology: start from latest origin/main; branch represents only the plan artifact; PR base must be main.

Deliverables: commit .cursor/plans/2026-10-23-plan-validator.plan.md; mark plan-review completed in plan frontmatter in this PR.

Verification: plan satisfies planning-methodology envelope (frontmatter, authority table, topology, per-slice blocks, agent prompts, plan-closure); mermaid distribution diagram preserved; no validator implementation in this PR.
```

### plan-validate-lib

```text
@.cursor/plans/archive/2026-10-23-plan-validator.plan.md

Implement slice plan-validate-lib only. Prerequisite: plan-review merged. Do not start fixtures-tests or later. Do not archive the plan.

Authority: Open PR only — implement and open the PR; do not merge.

Topology: start from latest origin/main; branch represents only this slice; PR base must be main.

Deliverables: canonical validator lib + CLI under plugins/team-harness/scripts; extend scripts/tsconfig (or dedicated config) so typecheck covers plugins/team-harness/scripts/**/*.ts; yaml + lockfile; minimal merge-safe validator tests; Parser and CLI behavior table; valid + invalid smoke fixtures for CLI. Mark plan-validate-lib completed in plan frontmatter in this PR.

Verification: npm ci; npm run typecheck (includes plugins/team-harness/scripts/**/*.ts); npm test (new validator tests run, not only existing tests); CLI smoke on valid fixture (exit 0) and invalid fixture (non-zero + diagnostics).
```

### fixtures-tests

```text
@.cursor/plans/archive/2026-10-23-plan-validator.plan.md

Implement slice fixtures-tests only. Prerequisite: plan-validate-lib merged. Do not start ci-npm or later. Do not archive the plan.

Authority: Open PR only — implement and open the PR; do not merge.

Topology: start from latest origin/main; branch represents only this slice; PR base must be main.

Deliverables: scripts/fixtures/plan-validate/* and scripts/plan-validate.test.ts per slice acceptance. Mark fixtures-tests completed in plan frontmatter in this PR.

Verification: npm test.
```

### ci-npm

```text
@.cursor/plans/archive/2026-10-23-plan-validator.plan.md

Implement slice ci-npm only. Prerequisite: fixtures-tests merged. Do not start centralized-consumption, consumer-adoption, docs-skill, or plan-closure. Do not archive the plan.

Authority: Open PR only — implement and open the PR; do not merge.

Topology: start from latest origin/main; branch represents only this slice; PR base must be main.

Deliverables: validate:plans npm scripts only; ci.yml and optional check.sh template validation; plugin/marketplace version bump from main (no new dependencies). Mark ci-npm completed in plan frontmatter in this PR.

Verification: npm ci; npm run typecheck; npm test; npm run validate:plans:template.
```

### centralized-consumption

```text
@.cursor/plans/archive/2026-10-23-plan-validator.plan.md

Implement slice centralized-consumption only. Prerequisites: ci-npm merged; Michael explicitly authorizes mastermichaelt/resumes as smoke-test consumer before you start. Do not start consumer-adoption, docs-skill, or plan-closure. Do not archive the plan.

Authority: Open PR only — implement and open the PR; do not merge.

Topology: marketplace implementation PR on latest origin/main (branch = this slice only; PR base main). Required smoke on mastermichaelt/resumes—not full rollout (consumer-adoption). Implementation and consumer smoke may use separate Cloud Agent launches; do not assume both repos are available in one environment.

Repositories: multipliers-dev/cursor-team-marketplace (implementation, read/write); mastermichaelt/resumes (required smoke, read/write in the smoke session once Michael authorized)—verify access and real checkout with pwd and git remote get-url origin in the same command as smoke work; hard-stop and escalate to Michael if missing or identity-mismatched—do not substitute another repo. Do not assume App/API access equals checkout.

Deliverables: packages/plan-validator (@multipliers-dev/plan-validator 0.1.0); registry-only reusable GHA workflow (validator_version pin); marketplace tarball CI job/scripts; publish workflow (workflow_dispatch + OIDC only, not executed); centralized-consumption.md; narrow SKILL npm invocation notes. Do not npm-publish in this PR. Do not duplicate validator source or perform multi-repo rollout. Mark centralized-consumption completed only after published CLI + consumer smoke (separate authorized publish + resumes session).

Verification: npm ci; typecheck; npm test; validate:plans; validate:plans:template; check.sh; verify:plan-validator; tarball smoke + marketplace tarball gates; plan validates; plan-validator-tarball-ci job green. Registry-mode consumer smoke after publish.
```

### consumer-adoption

```text
@.cursor/plans/archive/2026-10-23-plan-validator.plan.md

Execute slice consumer-adoption only. Prerequisite: centralized-consumption merged. Do not start docs-skill or plan-closure. Do not archive the plan.

Authority: Open PR only — Phase A: open per-repo adoption PRs and stop (do not merge). Phase B (separate run after Michael merges adoption PRs): plan-status PR in cursor-team-marketplace only—do not merge automatically.

Topology: Phase A — one implementation PR per adopt repo on that repo’s main; stop after opening. Phase B — plan-status PR in cursor-team-marketplace after adoption PRs merged. Do not edit the plan from consumer repos.

Repositories: multipliers-dev/cursor-team-marketplace (Phase B plan-status, read/write); all seven candidate consumers from Repository inventory (mastermichaelt/resumes, mastermichaelt/portfolio, mastermichaelt/mastermichaelt, multipliers-dev/editorial-workflow, multipliers-dev/renovate-workflow, multipliers-dev/codenames-ai-guesser, multipliers-dev/savepoints)—preflight each checkout inspected or edited (pwd, git remote get-url origin, role capability); hard-stop if missing or identity-mismatched. GitHub App/API access is not a checkout; Cloud Agents only get credentials for the repo they were launched against—launch per consumer repo.

Deliverables: Phase A — inspect all seven candidates; draft matrix with adopt/defer/exclude + rationale (do not exclude solely for no active plans); open per-adopt-repo workflow PRs (pinned validator_version semver + workflow uses:@sha); test evidence in each PR (valid, invalid, --allow-empty); do not mark consumer-adoption completed. Phase B — after Michael merges adoption PRs, plan-status PR with final matrix and mark consumer-adoption completed in this repo only.

Verification: Phase A — preflight for every candidate inspected or edited; each opened adoption PR CI validates that repo’s plans. Phase B — plan-status PR after merges; matrix covers all seven candidates with decisions, links, and pins.
```

### docs-skill

```text
@.cursor/plans/archive/2026-10-23-plan-validator.plan.md

Implement slice docs-skill only. Prerequisite: consumer-adoption merged (consumer PRs merged and plan-status PR recorded). Do not start plan-closure. Do not archive the plan.

Authority: Open PR only — implement and open the PR; do not merge.

Topology: start from latest origin/main; branch represents only this slice; PR base must be main.

Deliverables: rebase/update open PR 61 work (keep, do not discard): plan-validation.md plus SKILL.md item 7 / Plan validation subsection / reference.md / _template.plan.md / README scripts row; extend adoption docs using verified consumer-adoption matrix for npm CLI + reusable workflow CI without copy vendoring or implying plugin install configures CI. Mark docs-skill completed in plan frontmatter in this PR.

Verification: sh scripts/check.sh; npm test; read/grep confirms SKILL item 7 matches validator todo/prompt rules and both consumption paths are documented with real rollout examples where applicable.
```

### plan-closure

```text
@.cursor/plans/archive/2026-10-23-plan-validator.plan.md

Execute only plan-closure.

Authority: Open PR only — docs-only archive PR; do not merge.

Prerequisites: plan-validate-lib through docs-skill actually merged (centralized-consumption, consumer-adoption with merged consumer PRs + plan-status PR, docs-skill)—not merely frontmatter completed. Verify documented exceptions for repos not adopting the validator. Use multi-repo preflight and checkout identity when verifying linked repos.

Topology: start from latest origin/main; branch represents only this slice; PR base must be main.

Deliverables: verify slice todos and linked PRs across repos including adoption matrix; add # Shipped note with pins and exclusions; move plan to .cursor/plans/archive/2026-10-23-plan-validator.plan.md; mark plan-closure completed; update agent prompt references to the archived path.

Verification: confirm all prerequisite implementation PRs are merged, consumer-adoption matrix is complete, and slice todos are completed before archiving.
```
