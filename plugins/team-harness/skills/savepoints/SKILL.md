---
name: savepoints
description: >-
  Team-harness Savepoints Lite integration — session logging via vendored router
  and Notion provider skills. Supplies tier-1 Notion destination (and optional
  validation.post_write) from global Cursor User Rules (engineering invariants)
  into router/provider instruction context.
  Use when maintaining append-only session Savepoints through Notion MCP.
---

# Savepoints (team-harness integration)

Thin **marketplace wrapper** around canonical Savepoints Lite skills vendored in this plugin. Event detection, schema, configuration precedence, Notion mapping, MCP writes, and optional post-write CLI validation live in the **vendored package copy** — not in this file.

**Canonical router (installed plugin):** [`../../vendor/savepoints-lite/skills/savepoints/SKILL.md`](../../vendor/savepoints-lite/skills/savepoints/SKILL.md)

**Canonical Notion provider:** [`../../vendor/savepoints-lite/skills/savepoints-notion/SKILL.md`](../../vendor/savepoints-lite/skills/savepoints-notion/SKILL.md)

Cursor plugin install does **not** run `npm install`. Load router and provider skills from the paths above (relative to this wrapper), not from `node_modules`.

## Package-equivalent install root (marketplace — overrides canonical npm paths)

Vendored files under `vendor/savepoints-lite/` are a **byte-identical copy** of the published npm package’s `skills/` tree. Canonical router and provider skills still mention `node_modules` and “the same npm package install” — that wording describes **standalone** Savepoints Lite consumption only.

**When this wrapper is in scope** (team-harness installed from the marketplace), the following **take precedence** over any `node_modules` / `npm install` instructions inside those canonical skills:

| Topic | Marketplace behavior |
| --- | --- |
| Install root | `plugins/team-harness/vendor/savepoints-lite/` is the **package-equivalent install root** (same layout as `@multipliers-dev/savepoints-lite` inside `node_modules`, without requiring `npm ci` in the consumer repo). |
| Router skill | [`../../vendor/savepoints-lite/skills/savepoints/SKILL.md`](../../vendor/savepoints-lite/skills/savepoints/SKILL.md) — not `node_modules/@multipliers-dev/savepoints-lite/...`. |
| Notion provider | [`../../vendor/savepoints-lite/skills/savepoints-notion/SKILL.md`](../../vendor/savepoints-lite/skills/savepoints-notion/SKILL.md) — sibling under the same vendor `skills/` tree (equivalent to the router’s `../savepoints-notion/SKILL.md` relative link). |
| Optional validator CLI | [`../../vendor/savepoints-lite/skills/bin/savepoints-lite-validate.mjs`](../../vendor/savepoints-lite/skills/bin/savepoints-lite-validate.mjs) — self-contained under the vendor install root (Node ≥ 22 when invoked). |
| `schema.json` / `mapping.json` | Resolve under the vendor install root: `vendor/savepoints-lite/skills/savepoints/schema.json` and `vendor/savepoints-lite/skills/savepoints-notion/mapping.json` (CLI walk-up finds them from `skills/bin/`). |
| `node_modules must exist` | **Do not apply.** Do not look for Savepoints skills in the consumer repository’s `node_modules`. After consumer cleanup, session logging uses **only** this vendor tree via the installed plugin. |
| `defaults.yml` / `schema.md` | Resolve next to the vendored router (`vendor/savepoints-lite/skills/savepoints/`), not under consumer `node_modules`. |

Load and follow canonical router/provider **behavior** from the vendored paths above. Ignore canonical **path/install** lines that contradict this table.

## Activation and authorization

- **Global User Rules:** Use the generated `docs/engineering-invariants.local.md` as the copy-ready User Rules text when working from a marketplace checkout. Generate it using `npm run generate:engineering-invariants-local` after configuring your personal `savepoints_lite.destination.data_source_id`. Do **not** paste the committed `docs/engineering-invariants.md` directly; it contains a placeholder destination. Without a checkout, manually copy the standing instructions and configure your destination. See [savepoints-integration.md](../../docs/savepoints-integration.md) for operator setup.
- **Notion MCP:** must be connected with permission to create pages in that data source when a valid destination is configured.
- **Opt-in:** session logging runs when engineering invariants (User Rules) authorize ongoing logging — not from installing the plugin alone.

## Tier-1 destination handoff (wrapper only)

Read the **Session log** section in **global Cursor User Rules** (engineering invariants). Operators store the Notion destination under the `savepoints_lite` namespace:

```yaml
savepoints_lite:
  destination:
    data_source_id: "<NOTION_DATA_SOURCE_ID>"
```

**Mapping (required):** extract only the inner `destination` object from `savepoints_lite.destination`. Pass **that** block to the vendored router as tier-1 integration context. **Do not** pass the outer `savepoints_lite` key to the canonical router or provider.

Tier-1 block passed to the router (use the **actual** `data_source_id` from User Rules — never invent, hardcode, or substitute a placeholder):

```yaml
destination:
  data_source_id: "<NOTION_DATA_SOURCE_ID from savepoints_lite.destination>"
```

**Missing or invalid configuration:** if User Rules omit `savepoints_lite`, omit `destination`, or `data_source_id` is empty or unusable, **do not** synthesize a destination and **do not** delegate a Notion write for persistence. Continue primary work (fail open). Canonical router/provider precedence is unchanged — without a valid tier-1 block, the provider must not claim persistence.

The **Notion provider skill does not read User Rules.** Only this wrapper may read User Rules and perform the `savepoints_lite` → tier-1 `destination` mapping.

## Tier-1 validation handoff (optional — wrapper only)

Upstream router precedence already accepts labelled `validation` in the **integration instruction/delegation context** as highest tier for `validation.post_write` (then optional consumer `.agents/savepoints-lite.yml`, then packaged `false`). This wrapper maps User Rules onto that channel only — it does **not** invent a parallel precedence or override packaged defaults by other means.

Operators may optionally configure:

```yaml
savepoints_lite:
  destination:
    data_source_id: "<NOTION_DATA_SOURCE_ID>"
  # Optional — omit to fall through upstream precedence (defaults false
  # when no consumer .agents override exists)
  validation:
    post_write: true
```

**Mapping rules:**

| User Rules | Tier-1 YAML passed to the router |
| --- | --- |
| `savepoints_lite.validation.post_write` is an explicit boolean (`true` or `false`) | Include labelled `validation: { post_write: <bool> }` alongside `destination` when destination is valid |
| `validation` key absent / not an explicit boolean | **Omit** tier-1 `validation` entirely so router/provider fall through to upstream configuration precedence (optional consumer `.agents/savepoints-lite.yml`, then packaged default), which defaults to `false` when no other override exists |

Do **not** always inject `post_write: false` from this wrapper when the operator never configured validation (that would claim tier-1 when none was configured).

Example when both destination and explicit validation are present:

```yaml
destination:
  data_source_id: "<NOTION_DATA_SOURCE_ID from savepoints_lite.destination>"
validation:
  post_write: true
```

This wrapper adds **no** validation logic, MCP sequences, property mapping, or CLI invocation rules — those stay in the vendored router/provider. Bundling the CLI under the vendor install root does **not** by itself prove agents invoke it during Notion persistence.

## Delegation

1. Follow activation/authorization and the **package-equivalent install root** table above.
2. Map `savepoints_lite.destination` → tier-1 `destination` when valid; otherwise skip Notion persistence for that Savepoint and do **not** pass tier-1 `validation`.
3. Only when destination is valid **and** `savepoints_lite.validation.post_write` is an explicit boolean, also pass tier-1 `validation: { post_write: <bool> }`; if destination is valid but validation is absent / not an explicit boolean, omit `validation`.
4. Load and follow the vendored **router** skill for when to Savepoint, schema, `storage.provider` / `validation.post_write` resolution, and provider delegation (vendor paths only).
5. When `storage.provider` is `notion`, load the vendored **Notion provider** from the vendor tree (not consumer `node_modules`).

Do not duplicate router/provider logic here. Do not add marketplace-specific Notion property mapping or MCP call sequences.

## References

- Integration guide: [`docs/savepoints-integration.md`](../../docs/savepoints-integration.md)
- Upstream architecture: [savepoints-lite `docs/architecture.md`](https://github.com/multipliers-dev/savepoints-lite/blob/main/docs/architecture.md)
