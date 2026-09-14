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

A minimal root `package.json` exists for **dev-tooling only** (Agent Plugins spec drift detection). It is private, not published to npm, and is not the plugin package surface. CI still reads `plugins/team-harness/plugin.json` as the package version source of truth.

## Agent Plugins spec version

This is separate from the package version (`1.11.0` above). The repo targets **Agent Plugins spec 1.0.0** via [`plugins/team-harness/plugin.json`](../plugin.json) `$schema`:

`https://agent-plugins.org/schemas/1.0.0/plugin.schema.json`

### Conformance (blocking, offline)

**Conformance** is enforced offline on every PR by `scripts/check.sh`. It validates closed portable manifest keys, the declared `$schema`, fixed skill layout, marketplace catalog alignment, and the Cursor overlay boundary. No network calls.

### Drift (advisory, optional network)

**Drift** detection compares the declared spec version against the latest **published** upstream Agent Plugins spec. It is advisory only and does not change blocking conformance or fail PR CI when a newer spec exists.

Run manually:

```bash
npm run check:agent-plugins-spec-drift -- --json
```

The check outputs a `relationship`:

| `relationship` | Meaning | `driftDetected` |
| --- | --- | --- |
| `behind` | Declared version is older than latest confirmed published upstream | `true` |
| `current` | Declared version matches latest confirmed published upstream | `false` |
| `ahead` | Declared version is newer than discovered published upstream | `false` |

A published upstream version is confirmed only when **both** signals agree:

1. [`specification.md`](https://agent-plugins.org/specification.md) reports `Status: Published` and a `Spec Version`
2. `https://agent-plugins.org/schemas/{version}/plugin.schema.json` returns HTTP **200**, and its document `$id` reports the same version

If those signals disagree (for example markdown says `1.1.0` Published but the schema URL 404s), the check fails as an upstream/check error — it does **not** report `behind`, `current`, or `ahead`.

The scheduled workflow [`.github/workflows/agent-plugins-spec-drift.yml`](../../../.github/workflows/agent-plugins-spec-drift.yml) runs weekly:

- `behind` → create or update a single deduplicated GitHub issue (assign maintainer on create)
- `current` → close any open drift issue
- `ahead` → workflow warning only (no issue create/update/close)

Upgrading to a newer Agent Plugins spec is **manual reviewed migration** — never automatic `$schema` bumps or migration PRs. Behavioral contract matches [`renovate-workflow`](https://github.com/multipliers-dev/renovate-workflow).

## What we do not do (unless explicitly requested)

- `npm publish`
- `gh release create`
- Git tags or releases as part of routine PRs

Version bumps in this repo are documentation and manifest alignment only until a maintainer chooses to tag.
