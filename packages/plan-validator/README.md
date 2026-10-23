# @multipliers-dev/plan-validator

Deterministic structural validator for committed Cursor staged plan files (`.cursor/plans/*.plan.md`). It enforces the [planning-methodology](https://github.com/multipliers-dev/cursor-team-marketplace/tree/main/plugins/team-harness/skills/planning-methodology) **envelope** (frontmatter, authority table, slice blocks, agent prompts). It does **not** judge merge-safety semantics, verification sufficiency, or cross-repo completion — those stay with humans and review tools.

**Canonical TypeScript source** lives in the marketplace repo under `plugins/team-harness/scripts/`; this package is a bundled CLI built from that source. The **team-harness** Cursor plugin distributes methodology skills only — it does **not** install this npm package or configure consumer CI.

## Quick start

**Requirements:** Node.js **≥ 22** (see `engines` in `package.json`).

From your **consumer repository** root:

```bash
npm exec --yes --package=@multipliers-dev/plan-validator@0.1.0 -- \
  plan-validator --repo-root "$(pwd)" --allow-empty
```

Install globally or as a devDependency with the same **exact semver pin** if you prefer a fixed local binary; `npm exec` is the usual agent/CI pattern.

Template profile (strict structure, relaxed ellipsis placeholders):

```bash
npm exec --yes --package=@multipliers-dev/plan-validator@0.1.0 -- \
  plan-validator --repo-root "$(pwd)" --profile template .cursor/plans/_template.plan.md
```

**Published versions:** consumers currently pin **`0.1.0`** on npm. Version **`0.1.1`** in this repo adds this README only and is **not published yet** — bump consumer pins after a separate authorized publish step.

## What it validates

- YAML frontmatter (`name`, `overview`, `todos`, `isProject`) and allowed todo statuses
- Plan-level `## Recommended execution authority` table and `Repo default:` line (when required)
- Per-slice canonical headings and fields for **actionable** todos (`pending`, `in_progress`)
- **Agent prompts** section: `### <todo-id>` headings, fences, and labeled lines for actionable todos only
- Authority alignment across table, slice, and prompt

Default discovery skips `.cursor/plans/archive/**` and `**/_template.plan.md`. Optional `.cursor/plan-validator.json` overrides globs and repo-default hints.

Full rule ids, profiles, and configuration: [plan-validation.md](https://github.com/multipliers-dev/cursor-team-marketplace/blob/main/plugins/team-harness/docs/plan-validation.md) in the team-harness plugin docs.

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

For CI, call the marketplace reusable workflow (validates the **caller** checkout only):

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

| Artifact | Pin | Current pair |
| --- | --- | --- |
| Reusable workflow | Git tag `plan-validator-workflow-vX.Y.Z` on `uses:` (immutable; protected by repo tag ruleset — never moved) | `plan-validator-workflow-v1.0.0` → commit `9b16a15` |
| npm CLI | Exact `validator_version` / `@multipliers-dev/plan-validator@x.y.z` | **`0.1.0`** published; **`0.1.1`** docs-only, unpublished |

Update both pins when workflow logic or validator rules change. Verified consumer adoption examples (pins, PR links, smoke runs): see [Consumer adoption (verified)](https://github.com/multipliers-dev/cursor-team-marketplace/blob/main/plugins/team-harness/docs/plan-validation.md#consumer-adoption-verified) in the team-harness docs.

## Related

- Detailed consumption model: [centralized-consumption.md](https://github.com/multipliers-dev/cursor-team-marketplace/blob/main/plugins/team-harness/docs/centralized-consumption.md)
- Methodology skill: [planning-methodology/SKILL.md](https://github.com/multipliers-dev/cursor-team-marketplace/blob/main/plugins/team-harness/skills/planning-methodology/SKILL.md)
