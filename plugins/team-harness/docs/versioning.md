# Versioning

How versions are tracked in this repository. **This repo is not published to npm** and does not cut GitHub releases automatically.

## Aligned versions

Keep these in sync when bumping:

| File | Field | Current |
| --- | --- | --- |
| [`plugins/team-harness/plugin.json`](../plugin.json) (Agent Plugins 1.0 package) | `"version"` | `1.11.0` |
| [`plugins/team-harness/.cursor-plugin/plugin.json`](../.cursor-plugin/plugin.json) (Cursor overlay) | `"version"` | `1.11.0` |
| [`.cursor-plugin/marketplace.json`](../../../.cursor-plugin/marketplace.json) | `metadata.version` | `1.11.0` |

Unlike [`renovate-workflow`](https://github.com/multipliers-dev/renovate-workflow) (marketplace catalog has no version field), this team marketplace uses `metadata.version` as a **release signal** for the catalog. Bump it together with the plugin package and overlay.

`plugins/team-harness/plugin.json` is the portable [Agent Plugins 1.0](https://agent-plugins.org/specification) manifest (metadata only — skills at fixed `skills/`). `.cursor-plugin/plugin.json` is the Cursor extension overlay (`"skills": "./skills"`). See [layers.md](layers.md).

There is **no root `package.json`**. CI reads the package manifest at `plugins/team-harness/plugin.json` as the version source of truth.

## What we do not do (unless explicitly requested)

- `npm publish`
- `gh release create`
- Git tags or releases as part of routine PRs

Version bumps in this repo are documentation and manifest alignment only until a maintainer chooses to tag.
