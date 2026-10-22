# Plan validation

Deterministic structural checks for committed `.cursor/plans/*.plan.md` files. The validator lives under [`plugins/team-harness/scripts/`](../scripts/) (`lib/plan-validate.ts`, `validate-plans.ts`). It enforces the planning-methodology **envelope** (frontmatter, authority table, slice blocks, agent prompts). It does **not** judge merge-safety semantics, verification sufficiency, or cross-repo completion correctness — those stay with humans and review tools.

## Install (copy-only vendoring)

Consuming repos copy the validator from the installed **team-harness** plugin (same pattern as Git hook scripts). No npm package is published from this marketplace.

1. Copy `plugins/team-harness/scripts/lib/plan-validate.ts` and `plugins/team-harness/scripts/validate-plans.ts` into your repo (for example `scripts/plan-validate/`).
2. Add devDependencies: `tsx`, `typescript`, `yaml`, and `@types/node` (versions compatible with your toolchain).
3. Ensure `typecheck` includes the copied TypeScript if you typecheck scripts.
4. Optionally add `.cursor/plan-validator.json` (see [Configuration](#configuration)).
5. Wire npm scripts (see [npm scripts](#npm-scripts-in-this-marketplace)) and CI.

Update by re-copying from a newer plugin version when you want new rules or fixes.

## Run the CLI

From the repository root (where `.cursor/plans/` lives):

```bash
tsx plugins/team-harness/scripts/validate-plans.ts
```

With no path arguments, the CLI **discovers** plan files (see [Discovery and excludes](#discovery-and-excludes)). Pass explicit paths to validate only those files:

```bash
tsx plugins/team-harness/scripts/validate-plans.ts .cursor/plans/my-feature.plan.md
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

## npm scripts (in this marketplace)

Root [`package.json`](../../../package.json):

| Script | Command | Role |
| --- | --- | --- |
| `validate:plans` | CLI with `--allow-empty` | CI gate on **active** discovered plans. Repos with no active plans (only archive + template) skip validation instead of failing `discovery.empty`. |
| `validate:plans:template` | `--profile template` on `skills/planning-methodology/_template.plan.md` | Always blocking; keeps the skill template structurally valid while allowing placeholder ellipses. |

The CLI **without** `--allow-empty` remains fail-closed on empty discovery — use that in repos that always expect at least one active plan.

## CI without the plugin

After vendoring scripts and dependencies:

```yaml
- run: npm ci
- run: npm run validate:plans:template   # if you copied the template path
- run: npm run validate:plans             # or tsx .../validate-plans.ts without --allow-empty
```

This marketplace runs both in [`.github/workflows/ci.yml`](../../../.github/workflows/ci.yml) after tests.

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

Run `npm run validate:plans` locally before opening plan or implementation PRs that touch `.cursor/plans/`. Fix structural issues first; keep semantic review in PR description and review threads.

## Related docs

- Methodology: [`skills/planning-methodology/SKILL.md`](../skills/planning-methodology/SKILL.md)
- Template skeleton: [`skills/planning-methodology/_template.plan.md`](../skills/planning-methodology/_template.plan.md)
- Regression fixtures: [`scripts/fixtures/plan-validate/`](../../../scripts/fixtures/plan-validate/) in this marketplace repo
