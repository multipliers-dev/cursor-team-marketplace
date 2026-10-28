---
name: savepoints
description: >-
  Team-harness Savepoints Lite integration — session logging via vendored router
  and Notion provider skills. Supplies tier-1 Notion destination from global Cursor
  User Rules (engineering invariants) into router/provider instruction context.
  Use when maintaining append-only session Savepoints through Notion MCP.
---

# Savepoints (team-harness integration)

Thin **marketplace wrapper** around canonical Savepoints Lite skills vendored in this plugin. Event detection, schema, configuration precedence, Notion mapping, and MCP writes live in the **vendored package copy** — not in this file.

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
| `node_modules must exist` | **Do not apply.** Do not look for Savepoints skills in the consumer repository’s `node_modules`. After consumer cleanup, session logging uses **only** this vendor tree via the installed plugin. |
| `defaults.yml` / `schema.md` | Resolve next to the vendored router (`vendor/savepoints-lite/skills/savepoints/`), not under consumer `node_modules`. |

Load and follow canonical router/provider **behavior** from the vendored paths above. Ignore canonical **path/install** lines that contradict this table.

## Activation and authorization

- **Global User Rules:** paste and maintain [engineering invariants](https://github.com/multipliers-dev/cursor-team-marketplace/blob/main/docs/engineering-invariants.md) in Cursor **User Rules** (standing Savepoints authorization + personal `savepoints_lite.destination.data_source_id`). Operator install steps: [savepoints-integration.md](../docs/savepoints-integration.md).
- **Notion MCP:** must be connected with permission to create pages in that data source when a valid destination is configured.
- **Opt-in:** session logging runs when engineering invariants (User Rules) authorize ongoing logging — not from installing the plugin alone.

## Tier-1 destination handoff (wrapper only)

Read the Savepoints Lite section in **global Cursor User Rules** (engineering invariants). Operators store the Notion destination under the `savepoints_lite` namespace:

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

## Delegation

1. Follow activation/authorization and the **package-equivalent install root** table above.
2. Map `savepoints_lite.destination` → tier-1 `destination` when valid; otherwise skip Notion persistence for that Savepoint.
3. Load and follow the vendored **router** skill for when to Savepoint, schema, `storage.provider` resolution, and provider delegation (vendor paths only).
4. When `storage.provider` is `notion`, load the vendored **Notion provider** from the vendor tree (not consumer `node_modules`).

Do not duplicate router/provider logic here. Do not add marketplace-specific Notion property mapping or MCP call sequences.

## References

- Integration guide: [`docs/savepoints-integration.md`](../../docs/savepoints-integration.md)
- Upstream architecture: [savepoints-lite `docs/architecture.md`](https://github.com/multipliers-dev/savepoints-lite/blob/main/docs/architecture.md)
