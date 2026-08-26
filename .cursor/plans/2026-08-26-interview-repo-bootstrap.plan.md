---
name: Interview repo bootstrap
overview: Add team-harness skill and script to bootstrap an empty directory into a pre-wired agentic SDLC repo (TypeScript + Vitest + minimal AGENTS.md + pre-commit + minimal GitHub Actions CI + GitHub remote) — universal execution, verification, and enforcement; no product decisions.
todos:
  - id: plan-review
    content: "Plan-only PR — commit plan artifact and open PR for review; do not implement"
    status: completed
  - id: interview-repo-bootstrap
    content: "PR: templates/interview-repo preset, interview-repo-bootstrap.sh, skill, docs, check.sh; hook+CI smoke; plugin 1.5.0"
    status: pending
  - id: plan-closure
    content: "Docs-only PR after last slice: add # Shipped note, move plan to .cursor/plans/archive/2026-08-26-interview-repo-bootstrap.plan.md"
    status: pending
isProject: false
---

# Interview repo bootstrap skill

## Recommended execution authority

| Slice | Recommended authority | Agent instruction |
| --- | --- | --- |
| plan-review | Plan-only PR | Do not implement. Stop after opening the plan-only PR. |
| interview-repo-bootstrap | Open PR only | Do not merge. Stop after opening the PR. |
| plan-closure | Open PR only | Do not merge. Stop after opening the PR. |

Repo default: **Open PR only** (see team skill `/planning-methodology`).

## Repository topology

Multi-slice plans stack execution order, not Git branches. Integration branch is `main`.

**Before implementation:** start from latest `origin/main`.

**Before opening the PR:** branch represents only this slice — prior-slice work is on the integration branch, not via branch ancestry.

**After opening the PR:** GitHub PR base is `main`; diff excludes prior-slice work except through merged `main`.

---

## Plan review

**Recommended authority:** Plan-only PR

**Rationale:**

- Capture interview bootstrap scope, five-layer model, shared primitives, and operational sequence before implementation
- Expected diff is plan artifact only

**Agent instruction:** Do not implement. Stop after opening the plan-only PR.

---

## Slice — interview-repo-bootstrap

**Recommended authority:** Open PR only

**Rationale:**

- Single merge-safe plugin feature: minimal interview preset composed from shared hook primitives
- Distinct from `/new-repo-bootstrap` (production harness) and `/cloud-hooks-bootstrap` (manual hook wiring into existing repos)

**Agent instruction:** Do not merge. Stop after opening the PR.

**Prerequisite:** `plan-review` merged (or plan reviewed).

**Goal:** Add `/interview-repo-bootstrap` — in-place script + skill that copies shared templates and canonical hook scripts, runs hook smoke, creates GitHub remote.

### Problem

Timed technical interviews require a clean-slate GitHub repo, but minutes are lost on `git init`, `gh repo create`, TypeScript tooling, agent instructions, hooks, and CI. The interview scenario is often: **dropped into an empty directory** — not “create me a folder under `~/code`.”

Relevance failure modes:

1. Savepoints instructions in README instead of `AGENTS.md` — agent did not inherit intended behavior.
2. Pre-commit hook unreliable in the environment — debugging hook infrastructure mid-build.

### Design principle

**Preconfigure universal execution, verification, and enforcement. Leave architecture and product decisions empty.**

**Five-layer model** (conceptual center of the skill):

```
AGENTS.md              instruct
      ↓
Vitest + TypeScript    verify
      ↓
pre-commit             enforce locally
      ↓
GitHub Actions         enforce remotely
      ↓
Git + GitHub           persist/share
```

**Scope test:** *Would I want this capability regardless of what technical problem the interviewer gives me?*

| Yes (include) | No (exclude) |
| --- | --- |
| Vitest, typechecking, `AGENTS.md` | React, Savepoints, database |
| Cloud-hooks primitive, minimal CI | PR templates, Bugbot, plans |
| Reliable pre-commit (`test` + `typecheck`) | ESLint, Prettier, lint-staged, deploy |

### Shared primitives (no duplicated hook logic)

```
team-harness/
├── scripts/                    ← canonical hook primitives (single source)
├── templates/interview-repo/   ← interview preset files only
└── skills/
    ├── cloud-hooks-bootstrap/
    ├── new-repo-bootstrap/
    └── interview-repo-bootstrap/
```

- `interview-repo-bootstrap.sh` **copies** from `templates/interview-repo/` and `scripts/` — no heredoc duplicates.
- One-shot; does **not** invoke `/cloud-hooks-bootstrap` as a skill step.
- Resolve plugin root from script location (`$(dirname "$0")/..`).

### Skill boundary

```
interview-repo-bootstrap → minimal preset → STOP
new-repo-bootstrap     → production/team harness
```

Do not chain into `/new-repo-bootstrap` or `/cloud-hooks-bootstrap` after success.

### Cursor + Husky wiring

Naive `husky` is not enough on Cursor Cloud. Copy canonical files from `plugins/team-harness/scripts/` plus template `.cursor/hooks.json` (`sessionStart` only — no `afterFileEdit`).

**Core invariants:**

- **`git init` before `npm install`** — Husky `prepare` expects a Git repository.
- `npm test` uses `vitest run --passWithNoTests` (green with zero tests; no sample `*.test.ts`).
- Hook smoke: direct `sh .husky/pre-commit`, then `git commit` must run the hook via Git — verified by a **sentinel assertion** (see Hook smoke verification below), not assumed from exit code alone.

### Empty-directory guard

The target directory must be **actually empty** before bootstrap writes anything.

- List every entry in the target directory (including dotfiles).
- **Refuse if any entry exists** — no allowlist, no “probably harmless” exceptions, no agent-invented permitted files.
- Error message must print the offending paths so the user can `--dir` elsewhere or remove files manually.
- Rationale: accidental overwrite in an interview is worse than forcing an explicit directory choice; macOS `.DS_Store` is not special-cased.

### Hook smoke verification

Do not treat a successful `git commit` as proof the hook ran — hooks can be bypassed or miswired.

**Sentinel in template `.husky/pre-commit`** (after `npm test` and `npm run typecheck` succeed):

```sh
echo "[interview-bootstrap] pre-commit verify"
```

**Bootstrap harness (steps 6–8):**

1. **Direct smoke:** `sh .husky/pre-commit` passes and stdout contains the sentinel line.
2. **Git path smoke:** run `git -c user.name="Interview Bootstrap" -c user.email="bootstrap@localhost" commit -m "Initial commit"` with output captured (stdout + stderr). Use `-m` and inline `-c user.*` so fresh VMs and non-interactive shells never block on editor or missing identity.
3. **Assert:** captured commit output contains `[interview-bootstrap] pre-commit verify`.
4. **Abort** if commit succeeds but the sentinel is absent — hook was bypassed or not wired.

Optional secondary check: if using a marker file instead of echo, document the exact path in the plan and assert it exists post-commit; prefer the echo sentinel for simplicity (no extra gitignored artifact).

### Operational sequence

```
guard empty directory          (actually empty — any entry → refuse)
  → git init -b main
  → copy preset + primitives
  → npm install
  → direct hook smoke            (sh .husky/pre-commit + sentinel)
  → git add .
  → git commit -m "Initial commit"   (inline user.name/email; capture output; assert sentinel)
  → abort if sentinel missing
  → gh repo create --push
  → print URLs (+ optional gh run watch)
```

**CLI:** `interview-repo-bootstrap.sh [--name NAME] [--dir DIR] [--public] [--dry-run]`

- Default: in-place (`$PWD`); `--dir` for create-elsewhere.
- Guards: not inside parent worktree; **directory must be actually empty** (any entry → list paths and refuse); no existing `.git/` before `git init`.
- `--dry-run`: check tooling exists; no `gh auth`; no writes.

### Deliverables

1. [`plugins/team-harness/templates/interview-repo/`](plugins/team-harness/templates/interview-repo/) — preset files (`.gitignore` with `node_modules/`, `dist/`, `.env*`, `.DS_Store`; AGENTS.md; README template; package.json with `--passWithNoTests`; tsconfig; src/index.ts; `.husky/pre-commit` with sentinel echo; `.cursor/hooks.json`; `.github/workflows/ci.yml`; vitest.config.ts only if ESM smoke requires). **`.gitignore` must be copied before `npm install`** so `git add .` never stages `node_modules/`.
2. [`plugins/team-harness/scripts/interview-repo-bootstrap.sh`](plugins/team-harness/scripts/interview-repo-bootstrap.sh)
3. [`plugins/team-harness/skills/interview-repo-bootstrap/SKILL.md`](plugins/team-harness/skills/interview-repo-bootstrap/SKILL.md)
4. Docs: team-harness README, root README; bump [`plugin.json`](plugins/team-harness/.cursor-plugin/plugin.json) to **1.5.0** (main is already 1.4.0 from cloud-env-bootstrap); align cloud-hooks-bootstrap + optional new-repo-bootstrap cross-refs
5. [`scripts/check.sh`](scripts/check.sh) — validate new script + templates exist

### Acceptance

- [ ] `./scripts/check.sh` passes
- [ ] `--dry-run` works without gh auth
- [ ] Empty-directory guard: any file (including `.DS_Store`) → refuse with listed paths
- [ ] Live smoke: direct pre-commit + non-interactive `git commit -m` with inline user identity; output contains `[interview-bootstrap] pre-commit verify`; abort if sentinel missing
- [ ] Optional CI green on first push
- [ ] No sample tests; no product harness; no duplicate hook logic
- [ ] Skill frontmatter `name` matches directory name

### Explicit non-goals

- No `.nvmrc` / `engines`; no interview provenance in README
- No lint-staged, formatting, build in hooks/CI; no product CI jobs
- No copying full harness from codenames/resumes/portfolio
- No changes to private `interview-technical-builds.md` in this slice (optional follow-up)

---

## Plan closure (docs-only PR)

**Recommended authority:** Open PR only

**Agent instruction:** Do not merge. Stop after opening the PR.

After `interview-repo-bootstrap` merges:

1. Verify slice todo `completed`
2. Add `# Shipped` closure note
3. Move to `.cursor/plans/archive/2026-08-26-interview-repo-bootstrap.plan.md`
4. Mark `plan-closure` completed; update agent prompt paths

---

## Agent prompts (copy/paste for Cursor)

Use a **fresh Agent-mode chat** per slice.

### plan-review

```text
@.cursor/plans/2026-08-26-interview-repo-bootstrap.plan.md

Execute only plan-review. Do not start implementation slices.

Authority: Plan-only PR — commit the plan artifact only; do not implement. Stop after opening the plan-only PR.

Topology: start from latest origin/main; branch represents only the plan artifact; PR base must be main.

Deliverables: plan file under .cursor/plans/; mark plan-review completed in frontmatter in the same PR.

Verification: plan satisfies planning-methodology envelope; no implementation changes included.
```

### interview-repo-bootstrap

```text
@.cursor/plans/2026-08-26-interview-repo-bootstrap.plan.md

Implement slice interview-repo-bootstrap only. Prerequisite: plan-review merged. Do not start plan-closure. Do not archive the plan.

Authority: Open PR only — implement and open the PR; do not merge.

Topology: start from latest origin/main; branch represents only this slice; PR base must be main.

Deliverables: templates/interview-repo/ (including .gitignore before npm install), interview-repo-bootstrap.sh, skill, docs, check.sh updates, plugin 1.5.0. Mark interview-repo-bootstrap completed in plan frontmatter in this PR.

Verification: ./scripts/check.sh; dry-run; live hook smoke (git init before npm install; direct pre-commit sentinel; non-interactive git commit with -m and inline user.name/email; commit output must contain `[interview-bootstrap] pre-commit verify`); optional gh run watch on first CI push.
```

### plan-closure

```text
@.cursor/plans/2026-08-26-interview-repo-bootstrap.plan.md

Execute only plan-closure.

Authority: Open PR only — docs-only archive PR; do not merge.

Prerequisites: interview-repo-bootstrap merged and marked completed in frontmatter.

Topology: start from latest origin/main; branch represents only this slice; PR base must be main.

Deliverables: verify slice todos, add # Shipped note, move plan to .cursor/plans/archive/2026-08-26-interview-repo-bootstrap.plan.md, mark plan-closure completed, update agent prompt references to archived path.

Verification: prerequisite implementation PR merged; slice todo completed before archiving.
```
