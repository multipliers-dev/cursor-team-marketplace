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

## Activation and authorization

- **Global User Rules:** paste and maintain [`docs/engineering-invariants.md`](../../../../docs/engineering-invariants.md) (repo root) in Cursor **User Rules**, including the Savepoints Lite section and your personal Notion `data_source_id`.
- **Notion MCP:** must be connected with permission to create pages in that data source.
- **Opt-in:** session logging runs when engineering invariants (User Rules) authorize ongoing logging — not from installing the plugin alone.

## Tier-1 destination handoff (wrapper only)

Before delegating to the vendored router, read the Savepoints Lite section in **global Cursor User Rules** (engineering invariants). When it defines a Notion destination for session Savepoints, pass this block **unchanged** in the router’s instruction/delegation context:

```yaml
destination:
  data_source_id: "<YOUR_NOTION_DATA_SOURCE_ID from User Rules>"
```

Substitute the actual id from User Rules — never invent or hardcode maintainer ids in repo files, vendor trees, or this skill.

The **Notion provider skill does not read User Rules.** Only this wrapper (and other integration layers) may lift `data_source_id` from User Rules into tier-1 instruction context.

## Delegation

1. Follow activation/authorization above.
2. Load and follow the vendored **router** skill for when to Savepoint, schema, `storage.provider` resolution, and provider delegation.
3. Include the tier-1 `destination` block when User Rules supply `data_source_id`.
4. Load the vendored **Notion provider** from the router’s relative path when `storage.provider` is `notion`.

Do not duplicate router/provider logic here. Do not add marketplace-specific Notion property mapping or MCP call sequences.

## References

- Integration guide: [`docs/savepoints-integration.md`](../../docs/savepoints-integration.md)
- Upstream architecture: [savepoints-lite `docs/architecture.md`](https://github.com/multipliers-dev/savepoints-lite/blob/main/docs/architecture.md)
