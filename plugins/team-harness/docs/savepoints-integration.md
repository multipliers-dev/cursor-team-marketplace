# Savepoints Lite integration (team-harness)

Distribute **instruction-only** session Savepoints through the team-harness Cursor plugin without a runtime `node_modules` dependency in the installed plugin.

| Layer | Location | Role |
| --- | --- | --- |
| **Build-time pin** | Root `package.json` `devDependencies["@multipliers-dev/savepoints-lite"]` | Exact semver for sync/verify against npm |
| **Committed vendor** | `plugins/team-harness/vendor/savepoints-lite/skills/` | Canonical router + Notion provider skills at plugin install |
| **Discovery wrapper** | `plugins/team-harness/skills/savepoints/SKILL.md` | `/savepoints` — User Rules destination → tier-1 instruction context |
| **Personal destination** | Global Cursor **User Rules** ([`docs/engineering-invariants.md`](../../../docs/engineering-invariants.md) Savepoints section) | `data_source_id` only here — not in vendor, not in canonical npm defaults (`@2.0.0`) |
| **Persistence** | Consumer Notion MCP | Provider skill performs `notion-create-pages` |

## Maintainer workflow (this repository)

```bash
npm ci
npm run sync:savepoints-vendor    # after bumping the devDependency pin
npm run verify:savepoints-vendor  # CI + pre-merge check
```

`verify:savepoints-vendor` byte-compares vendored skills to the pinned npm install. Drift fails CI until `sync:savepoints-vendor` is run and committed.

## Operator workflow (consumers)

1. Install or refresh the **team-harness** plugin from this marketplace.
2. Paste [`docs/engineering-invariants.md`](../../../docs/engineering-invariants.md) into Cursor **User Rules**; set your Notion Savepoints `data_source_id` in that Savepoints section.
3. Connect Notion MCP.
4. Invoke `/savepoints` (or follow wrapper delegation when User Rules require ongoing session logging).

Per-repo `AGENTS.md` activation and `node_modules` skill paths are **deprecated** after consumer cleanup (see marketplace distribution plan); until then, follow the activation model documented in each repo.

## Architectural boundaries

- **No duplicate logic** in the marketplace — router/provider behavior stays in vendored canonical skills copied from `@multipliers-dev/savepoints-lite`.
- **No upstream edits** from this repo — bump the pin and re-sync vendor when releasing new package versions.
- **No package-wide default destination** in the plugin for all consumers — tier-1 ids come from each operator’s User Rules only.

Configuration precedence inside canonical skills: integration tier-1 `destination` → optional consumer `.agents/savepoints-notion.yml` → packaged defaults (no id in `@2.0.0`). See [savepoints-lite architecture](https://github.com/multipliers-dev/savepoints-lite/blob/main/docs/architecture.md).
