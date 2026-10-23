# Plan validation

Deterministic structural checks for committed `.cursor/plans/*.plan.md` files. Canonical implementation: [`plugins/team-harness/scripts/`](../scripts/) (`lib/plan-validate.ts`, `validate-plans.ts`), packaged for consumers as [`@multipliers-dev/plan-validator`](../../../packages/plan-validator/). The validator enforces the planning-methodology **envelope** (frontmatter, authority table, slice blocks, agent prompts). It does **not** judge merge-safety semantics, verification sufficiency, or cross-repo completion correctness — those stay with humans and review tools.

## Three surfaces (do not conflate)

| Surface | Role | Configures consumer CI? |
| --- | --- | --- |
| **team-harness plugin** | Methodology skills (`/planning-methodology`), hook/bootstrap scripts | **No** |
| **npm CLI** `@multipliers-dev/plan-validator` | Agents and local runs (exact semver pin) | Only if you wire it yourself |
| **Reusable workflow** [`.github/workflows/validate-plans.yml`](../../../.github/workflows/validate-plans.yml) | GitHub CI on the **caller** checkout | **Yes**, when referenced from the consumer repo |

**Do not** copy validator TypeScript into consumer repos (copy-only vendoring is deprecated). Use the published npm CLI and/or the reusable workflow — see [centralized-consumption.md](centralized-consumption.md).

Quick start and npm package README: [`packages/plan-validator/README.md`](../../../packages/plan-validator/README.md).

## Consumer adoption (verified)

After **consumer-adoption** rollout (2026-10-23), six repositories **adopt** pinned CI:

- **npm:** `@multipliers-dev/plan-validator@0.1.0` via workflow input `validator_version: "0.1.0"`
- **Workflow:** `uses: multipliers-dev/cursor-team-marketplace/.github/workflows/validate-plans.yml@plan-validator-workflow-v1.0.0`

Examples: [mastermichaelt/resumes PR 217](https://github.com/mastermichaelt/resumes/pull/217), [mastermichaelt/portfolio PR 83](https://github.com/mastermichaelt/portfolio/pull/83), [multipliers-dev/editorial-workflow PR 27](https://github.com/multipliers-dev/editorial-workflow/pull/27), [multipliers-dev/renovate-workflow PR 56](https://github.com/multipliers-dev/renovate-workflow/pull/56), [multipliers-dev/codenames-ai-guesser PR 633](https://github.com/multipliers-dev/codenames-ai-guesser/pull/633), [multipliers-dev/savepoints PR 87](https://github.com/multipliers-dev/savepoints/pull/87). **Excluded:** `mastermichaelt/mastermichaelt` (no methodology use). Full matrix: [plan file adoption evidence](../../../.cursor/plans/2026-10-23-plan-validator.plan.md).

Package **`0.1.1`** adds npm README only and is **unpublished**; keep consumer pins at **`0.1.0`** until publish.

## Version pinning (independent)

| Artifact | How consumers pin | Current |
| --- | --- | --- |
| Reusable workflow | Git tag `plan-validator-workflow-vX.Y.Z` on `uses:` | `plan-validator-workflow-v1.0.0` (immutable tag; ruleset blocks moves/deletes) |
| npm CLI | Exact `validator_version` / `@multipliers-dev/plan-validator@x.y.z` | **`0.1.0`** on registry |

Bump workflow tag when workflow YAML changes; bump npm version when validator rules/CLI change. They are **not** the same version number.

## Run the CLI (consumers)

From the **consumer repository** root (Node **≥ 22**):

```bash
npm exec --yes --package=@multipliers-dev/plan-validator@0.1.0 -- \
  plan-validator --repo-root "$(pwd)" --allow-empty
```

With no path arguments, the CLI **discovers** plan files (see [Discovery and excludes](#discovery-and-excludes)). Pass explicit paths to validate only those files:

```bash
npm exec --yes --package=@multipliers-dev/plan-validator@0.1.0 -- \
  plan-validator --repo-root "$(pwd)" .cursor/plans/my-feature.plan.md
```

Options:

| Flag | Effect |
| --- | --- |
| `--profile default` | Strict placeholder checks (default). |
| `--profile template` | Same rules; allows ellipsis placeholders (`…`, `....`) in Deliverables, Verification, and slice **Acceptance** for boilerplate. |
| `--include-archive` | Stops excluding `.cursor/plans/archive/**` from discovery. Other exclude globs still apply. |
| `--allow-empty` | When discovery finds **zero** files, exit **0** and print a skip message instead of `discovery.empty`. Does **not** apply when you pass explicit paths. Invalid plans, missing explicit paths, and config read errors still fail. |
| `--repo-root <path>` | Repository root for discovery, config, and relative paths (default: `process.cwd()`). |

Success prints `ok plan validation (...)` on stdout. Failures print one line per issue on stderr:

```text
path/to/plan.plan.md:42: [prompts.missing] Actionable todo "slice-a" missing ### slice-a agent prompt heading
```

## GitHub CI (reusable workflow)

Caller job needs `contents: read` only. Example:

```yaml
permissions:
  contents: read

jobs:
  validate-plans:
    uses: multipliers-dev/cursor-team-marketplace/.github/workflows/validate-plans.yml@plan-validator-workflow-v1.0.0
    with:
      validator_version: "0.1.0"
      allow_empty: true
      template_path: ".cursor/plans/_template.plan.md"  # optional
```

Inputs match [validate-plans.yml](../../../.github/workflows/validate-plans.yml): required `validator_version` (exact `x.y.z`), optional `template_path`, optional `allow_empty` (default true). Validation runs against the **caller** checkout (`path: caller`), not marketplace plans.

**Failure behavior:** validation issues fail the job (non-zero CLI exit **1**). Misconfigured workflow inputs or npm install failures surface as job failure (CLI exit **2** or step error).

## npm scripts (this marketplace only)

Developers working in **cursor-team-marketplace** use the TypeScript CLI via root [`package.json`](../../../package.json):

| Script | Command | Role |
| --- | --- | --- |
| `validate:plans` | `tsx` CLI with `--allow-empty` | CI gate on **active** discovered plans. |
| `validate:plans:template` | `--profile template` on `skills/planning-methodology/_template.plan.md` | Blocking template gate. |

Consumers should use **`npm exec`** with the published package (or the reusable workflow), not `tsx` against marketplace source.

This marketplace runs both scripts in [`.github/workflows/ci.yml`](../../../.github/workflows/ci.yml) after tests.

## Profiles

- **`default`**: Actionable slice **Acceptance** and prompt **Deliverables** / **Verification** cannot be ellipsis-only placeholders. Use for real plans under `.cursor/plans/`.
- **`template`**: Relaxes placeholder checks only. Frontmatter, headings, authority structure, and prompt fences are unchanged. Used for `_template.plan.md`.

## Discovery and excludes

Default discovery glob: `.cursor/plans/**/*.plan.md`.

Default exclude globs (paths relative to repo root):

- `.cursor/plans/archive/**`
- `**/_template.plan.md`
- `**/planning-methodology/_template.plan.md`

Override or extend via `.cursor/plan-validator.json` (`plansGlobs`, `excludeGlobs`).

## Configuration

Optional file: `.cursor/plan-validator.json`

```json
{
  "integrationBranch": "main",
  "plansGlobs": [".cursor/plans/**/*.plan.md"],
  "excludeGlobs": [".cursor/plans/archive/**", "**/_template.plan.md"],
  "requireRepoDefaultLine": true,
  "repoDefaultHint": "Open PR only"
}
```

| Field | Purpose |
| --- | --- |
| `plansGlobs` | Glob patterns for automatic discovery (default: `.cursor/plans/**/*.plan.md`). |
| `excludeGlobs` | Paths to skip after discovery (defaults include archive and template paths above). |
| `requireRepoDefaultLine` | When not `false`, require a plan-level `Repo default:` line. |
| `repoDefaultHint` | Documentation-only hint for authors; not validated as an exact string match. |
| `integrationBranch` | Reserved for future checks; documented for consuming repos. |

Malformed JSON or unreadable config causes the CLI to exit **2** (runtime error), not a validation issue.

## Actionable todos and agent prompts

A todo is **actionable** when `status` is `pending` or `in_progress`.

| Todo status | Slice section required | `### <todo-id>` prompt required |
| --- | --- | --- |
| `pending`, `in_progress` | Yes (canonical heading) | Yes, with fenced `text` block and labeled lines |
| `completed`, `cancelled` | No | No (may omit prompt) |

Rules for the **Agent prompts (copy/paste for Cursor)** section:

- Every actionable todo needs exactly one `### <todo-id>` heading (id copied from frontmatter).
- **Orphan** headings (`###` id not in frontmatter) → `prompts.orphan`.
- **Duplicate** headings for the same id → `prompts.duplicate`.
- Headings inside fenced code blocks are ignored for structure scans; labeled lines are read from the fenced `text` block under each `###` heading.

Required labeled lines in each actionable prompt fence: `Authority:`, `Topology:`, `Deliverables:`, `Verification:`.

## Canonical slice headings

Outside fenced blocks, actionable todos must have a matching `##` slice section:

| Form | Maps to todo id |
| --- | --- |
| `## Slice — <todo-id>` | `<todo-id>` (em dash `—`, en dash `–`, or ASCII `-` after `Slice`) |
| `## Plan closure` or `## Plan closure (docs-only PR)` | `plan-closure` |

Non-canonical titles (for example `## Slice 1 — slice-a prose title`) do **not** match; the validator reports `slice.missing`.

Per-slice body fields for actionable todos: **Recommended authority**, **Rationale**, **Agent instruction**, and **Acceptance** (except exemptions below).

**Acceptance exemptions** (slice block only): todo id `plan-closure`, or slice authority **Plan-only PR** / **Manual verification gate**.

## Authority consistency

Known authority labels: **Plan-only PR**, **Open PR only**, **Merge granted**, **Manual verification gate**. The validator normalizes aliases (for example plan-only phrasing) where implemented in code.

For actionable todos, the plan-level **Recommended execution authority** table must include exactly one row per todo (no missing rows, no duplicate rows for the same id). Slice **Recommended authority**, table row, and prompt **Authority:** line must agree after normalization (`authority.mismatch`).

## Rule ids

Issues use stable `rule` ids:

| Rule | Meaning |
| --- | --- |
| `frontmatter.delimiter` | Missing or unclosed `---` frontmatter |
| `frontmatter.yaml` | YAML parse error |
| `frontmatter.schema` | Required frontmatter fields / types |
| `frontmatter.todos` | Todo array shape, duplicate ids, multi-slice must end with `plan-closure` |
| `frontmatter.todo-status` | Status not in `pending`, `in_progress`, `completed`, `cancelled` |
| `plan.authority-table` | Missing `## Recommended execution authority` |
| `plan.repo-default` | Missing `Repo default:` when required |
| `authority.table.missing-row` | Actionable todo missing from authority table |
| `authority.table.duplicate-row` | Duplicate table row for same todo id |
| `authority.table.unknown-todo` | Table row for unknown id |
| `authority.table.unrecognized-label` | Unrecognized authority in table |
| `authority.mismatch` | Slice, table, or prompt authority disagree |
| `slice.missing` | No canonical slice section for actionable todo |
| `slice.recommended-authority` | Missing slice authority field |
| `slice.rationale` | Missing **Rationale:** |
| `slice.agent-instruction` | Missing **Agent instruction:** |
| `slice.acceptance` | Missing or ellipsis-only **Acceptance:** (default profile) |
| `slice.authority-label` | Unrecognized slice authority |
| `prompts.section` | Missing agent prompts section |
| `prompts.missing` | Actionable todo missing `###` prompt |
| `prompts.orphan` | `###` id not in frontmatter |
| `prompts.duplicate` | Duplicate `###` heading |
| `prompts.fence-missing` | Heading without fenced block |
| `prompts.fence-unclosed` | Unclosed fence |
| `prompts.labeled-lines` | Missing required labeled line in fence |
| `prompts.authority-label` | Unrecognized prompt authority |
| `prompts.placeholder` | Ellipsis-only Deliverables/Verification (default profile) |
| `discovery.empty` | No files discovered (automatic discovery, no `--allow-empty`) |
| `io.not-found` | Explicit path missing |
| `io.error` | Read/parse failure for a file |

## Exit codes

| Code | When |
| --- | --- |
| `0` | All validated files pass, or `--allow-empty` skip (no discovered files) |
| `1` | One or more validation issues (or `discovery.empty` without `--allow-empty`) |
| `2` | Unknown CLI flag/profile, or uncaught runtime error (for example invalid config JSON) |

## Deterministic vs semantic review

| Validator | Humans / Bugbot |
| --- | --- |
| Frontmatter schema, todo statuses, prompt/slice structure | Merge-safety of acceptance criteria |
| Authority table ↔ slice ↔ prompt alignment | Whether verification steps are sufficient |
| Canonical headings and fences | Diagram preservation, product semantics |
| Placeholder ellipses in strict profile | Cross-repo completion actually merged |

Run validation locally before opening plan or implementation PRs that touch `.cursor/plans/` (`npm exec` in consumers; `npm run validate:plans` in this marketplace). Fix structural issues first; keep semantic review in PR description and review threads.

## Related docs

- Consumption model: [centralized-consumption.md](centralized-consumption.md)
- npm package README: [`packages/plan-validator/README.md`](../../../packages/plan-validator/README.md)
- Methodology: [`skills/planning-methodology/SKILL.md`](../skills/planning-methodology/SKILL.md)
- Template skeleton: [`skills/planning-methodology/_template.plan.md`](../skills/planning-methodology/_template.plan.md)
- Regression fixtures: [`scripts/fixtures/plan-validate/`](../../../scripts/fixtures/plan-validate/) in this marketplace repo
