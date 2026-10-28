# Savepoints Lite integration (team-harness)

Distribute **instruction-only** session Savepoints through the team-harness Cursor plugin without a runtime `node_modules` dependency in the installed plugin.

| Layer | Location | Role |
| --- | --- | --- |
| **Build-time pin** | Root `package.json` `devDependencies["@multipliers-dev/savepoints-lite"]` | Exact semver for sync/verify against npm |
| **Committed vendor** | `plugins/team-harness/vendor/savepoints-lite/skills/` | Canonical router + Notion provider skills at plugin install |
| **Discovery wrapper** | `plugins/team-harness/skills/savepoints/SKILL.md` | `/savepoints` — User Rules → tier-1 `destination` handoff |
| **Personal destination** | Global Cursor **User Rules** ([engineering invariants](https://github.com/multipliers-dev/cursor-team-marketplace/blob/main/docs/engineering-invariants.md) **Session log** section) | `savepoints_lite.destination.data_source_id` only — not in vendor or npm defaults (`@2.0.0`) |
| **Persistence** | Consumer Notion MCP | Provider skill performs `notion-create-pages` |

## User Rules → tier-1 destination mapping

Operators configure the Notion data source in **User Rules** (engineering invariants), nested under `savepoints_lite`:

```yaml
savepoints_lite:
  destination:
    data_source_id: "<NOTION_DATA_SOURCE_ID>"
```

The [`/savepoints` wrapper](../skills/savepoints/SKILL.md) **unwraps** `savepoints_lite.destination` and passes **only** the inner block to the canonical router as tier-1 integration context:

```yaml
destination:
  data_source_id: "<same value as in User Rules>"
```

Rules:

- Preserve the configured `data_source_id` value; do not invent or hardcode ids in the plugin or vendor tree.
- Do **not** pass the outer `savepoints_lite` namespace to the canonical router or provider.
- Do **not** change canonical configuration precedence inside vendored skills.
- If User Rules omit `savepoints_lite`, omit `destination`, or `data_source_id` is missing/empty/unusable → **no** tier-1 block, **no** Notion persistence attempt for that Savepoint (fail open).

## Maintainer workflow (this repository)

```bash
npm ci
npm run sync:savepoints-vendor    # after bumping the devDependency pin
npm run verify:savepoints-vendor  # CI + pre-merge check
```

`verify:savepoints-vendor` requires the **full** `skills/` file inventory under vendor to match the pinned npm package (no missing or extra files), asserts every path in the independent manifest exists, and **byte-compares every file** in the matched inventory. Drift fails CI until `sync:savepoints-vendor` is run and committed.

`sh scripts/verify-savepoints-marketplace-layout.sh` verifies the repo plugin tree (wrapper, vendored router/provider, wrapper-relative paths, install-root and destination-handoff contract). When a team-harness install at the **same version as this repo** exists under `~/.cursor/plugins/cache/.../<marketplace>/team-harness/<sha>/` (discovered with portable `find` on `*/team-harness/*/skills/savepoints/SKILL.md` under `SAVEPOINTS_PLUGIN_CACHE_ROOT` or the default `~/.cursor/plugins/cache`), the same checks run against that cache. Older cached versions are ignored (not treated as proof). If no matching-version cache exists, the script reports **installed-cache verification not run** while repo structural checks still pass. Discovery failures (unreadable cache root) exit non-zero and are not treated as an empty cache.

## Operator workflow (consumers)

1. Install or refresh the **team-harness** plugin from this marketplace.
2. Paste [engineering invariants](https://github.com/multipliers-dev/cursor-team-marketplace/blob/main/docs/engineering-invariants.md) into Cursor **User Rules** (global), not only in a single repo. Set your personal `savepoints_lite.destination.data_source_id` under **Destination** in that paste (see **User Rules → tier-1 destination mapping** and the **Session log** section in engineering invariants).
3. Connect **Notion MCP** with write access to your Savepoints data source.
4. Invoke `/savepoints` for manual verification, or rely on ongoing session logging when the **Session log** section is present in User Rules (see **Ongoing logging authorization**).

### Ongoing logging authorization

Installing the plugin or connecting Notion MCP does **not** alone authorize production Notion writes. **Opt-in** = the **Session log** section from engineering invariants present in **User Rules** (or explicit per-session operator consent for manual verification). Once opted in, agents should maintain the session log without asking for separate authorization before each entry, subject to Notion MCP permissions. If activation is absent or consent is unclear, do not write; fail open without claiming persistence.

Capture triggers, required entry fields, and fail-open behavior for standing agent instructions live in engineering invariants **Session log**; this document owns adoption steps and implementation boundaries.

Per-repo `AGENTS.md` activation and `node_modules` skill paths are **deprecated** after consumer cleanup (see marketplace distribution plan); until then, follow the activation model documented in each repo.

## Vendored README vs marketplace distribution

Files under `vendor/savepoints-lite/skills/` (including [`skills/README.md`](../vendor/savepoints-lite/skills/README.md)) are **unchanged** upstream copies. That README correctly tells standalone consumers to install via npm and not vendor skills locally.

**In team-harness, that guidance is superseded:** the marketplace **commits** a vendored copy for plugin install, and the [`/savepoints` wrapper](../skills/savepoints/SKILL.md) defines the **package-equivalent install root** and path precedence over canonical `node_modules` wording. Operators and agents should follow the wrapper + this document, not the vendored README’s install/distribution notes.

## Architectural boundaries

- **No duplicate logic** in the marketplace — router/provider behavior stays in vendored canonical skills copied from `@multipliers-dev/savepoints-lite`.
- **No upstream edits** from this repo — bump the pin and re-sync vendor when releasing new package versions.
- **No package-wide default destination** in the plugin for all consumers — tier-1 ids come from each operator’s User Rules only.

Configuration precedence inside canonical skills: integration tier-1 `destination` → optional consumer `.agents/savepoints-notion.yml` → packaged defaults (no id in `@2.0.0`). See [savepoints-lite architecture](https://github.com/multipliers-dev/savepoints-lite/blob/main/docs/architecture.md).
