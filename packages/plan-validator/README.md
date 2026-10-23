# @multipliers-dev/plan-validator

Deterministic structural validator for committed Cursor staged plan files (`.cursor/plans/*.plan.md`). It enforces the [planning-methodology](https://github.com/multipliers-dev/cursor-team-marketplace/tree/main/plugins/team-harness/skills/planning-methodology) **envelope** (frontmatter, authority table, slice blocks, agent prompts). It does **not** judge merge-safety semantics, verification sufficiency, or cross-repo completion — those stay with humans and review tools.

The **team-harness** Cursor plugin distributes methodology skills only — it does **not** install this npm package or configure consumer CI.

## Quick start

**Requirements:** Node.js **≥ 22** (see `engines` in `package.json`).

From your **repository** root, pin an **exact** published semver (never ranges or dist-tags). Runnable examples use **`0.1.0`**, a known published version on npm — check [npm](https://www.npmjs.com/package/@multipliers-dev/plan-validator) for newer releases, then pin the exact version you intend to run.

```bash
npm exec --yes --package=@multipliers-dev/plan-validator@0.1.0 -- \
  plan-validator --repo-root "$(pwd)" --allow-empty
```

`npm exec` is the usual agent/CI pattern; a devDependency with the same pin works for a local binary.

Template profile (strict structure, relaxed ellipsis placeholders):

```bash
npm exec --yes --package=@multipliers-dev/plan-validator@0.1.0 -- \
  plan-validator --repo-root "$(pwd)" --profile template .cursor/plans/_template.plan.md
```

## What it validates

- YAML frontmatter (`name`, `overview`, `todos`, `isProject`) and allowed todo statuses
- Plan-level `## Recommended execution authority` table and `Repo default:` line (when required)
- Per-slice canonical headings and fields for **actionable** todos (`pending`, `in_progress`)
- **Agent prompts** section: `### <todo-id>` headings, fences, and labeled lines for actionable todos only
- Authority alignment across table, slice, and prompt

Default discovery skips `.cursor/plans/archive/**`, `**/_template.plan.md`, and `**/planning-methodology/_template.plan.md`. Optional `.cursor/plan-validator.json` overrides globs and repo-default hints. See [Discovery and excludes](https://github.com/multipliers-dev/cursor-team-marketplace/blob/main/plugins/team-harness/docs/plan-validation.md#discovery-and-excludes).

Full rule ids, profiles, and configuration: [plan-validation.md](https://github.com/multipliers-dev/cursor-team-marketplace/blob/main/plugins/team-harness/docs/plan-validation.md).

## CLI flags

| Flag | Effect |
| --- | --- |
| `--profile default` | Strict placeholder checks (default). |
| `--profile template` | Same rules; allows ellipsis placeholders in Deliverables, Verification, and slice **Acceptance**. |
| `--include-archive` | Include `.cursor/plans/archive/**` in discovery. |
| `--allow-empty` | When discovery finds **zero** files, exit **0** with a skip message instead of `discovery.empty`. |
| `--repo-root <path>` | Repository root for discovery, config, and relative paths (default: `process.cwd()`). |

Pass explicit `.plan.md` paths to validate only those files (discovery rules do not apply).

## Exit codes

| Code | When |
| --- | --- |
| `0` | All validated files pass, or `--allow-empty` skip (no discovered files) |
| `1` | One or more validation issues (including `discovery.empty` without `--allow-empty`) |
| `2` | Unknown CLI flag/profile, or uncaught runtime error (for example invalid config JSON) |

## GitHub Actions (reusable workflow)

For CI, call the marketplace reusable workflow (validates the **caller** checkout only). Pin the workflow with a **protected version tag** `plan-validator-workflow-vX.Y.Z` on `uses:` (tag ruleset blocks updates and deletions; never move a tag after adoption). Pin **`validator_version`** to the same npm semver you use locally. The YAML example uses **`0.1.0`** for `validator_version` (known published); check npm for newer releases and pin exactly.

```yaml
permissions:
  contents: read

jobs:
  validate-plans:
    uses: multipliers-dev/cursor-team-marketplace/.github/workflows/validate-plans.yml@plan-validator-workflow-v1.0.0
    with:
      validator_version: "0.1.0"
      allow_empty: true
      # template_path: ".cursor/plans/_template.plan.md"  # optional
```

| Input | Required | Purpose |
| --- | --- | --- |
| `validator_version` | **yes** | Exact npm semver `x.y.z` for `@multipliers-dev/plan-validator` |
| `template_path` | no | Optional `--profile template` on a path relative to the caller repo |
| `allow_empty` | no (default `true`) | Pass `--allow-empty` when no active plans are discovered |

## Version pinning (workflow vs npm)

The **reusable workflow** and the **npm package** are versioned **independently**:

| Artifact | How to pin |
| --- | --- |
| Reusable workflow | Protected version tag `plan-validator-workflow-vX.Y.Z` on `uses:` (ruleset prevents tag updates/deletions; never moved after adoption) |
| npm CLI | Exact `validator_version` / `@multipliers-dev/plan-validator@x.y.z` |

When workflow YAML changes, adopt a new workflow tag. When validator rules or CLI behavior changes, bump the npm pin (and publish a new package version first). Update **both** when both surfaces change.

## Related

- Detailed consumption model: [centralized-consumption.md](https://github.com/multipliers-dev/cursor-team-marketplace/blob/main/plugins/team-harness/docs/centralized-consumption.md)
- Methodology skill: [planning-methodology/SKILL.md](https://github.com/multipliers-dev/cursor-team-marketplace/blob/main/plugins/team-harness/skills/planning-methodology/SKILL.md)
