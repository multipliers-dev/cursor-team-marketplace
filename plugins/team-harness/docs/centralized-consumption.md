# Centralized plan validation (consumption)

Consuming repositories run the **canonical** plan validator without copying TypeScript from `plugins/team-harness/scripts/`.

| Surface | Mechanism |
| --- | --- |
| **Agents / local** | Published npm CLI `@multipliers-dev/plan-validator` (exact version pin) |
| **GitHub CI** | Reusable workflow `.github/workflows/validate-plans.yml` (same CLI version) |
| **Methodology** | team-harness **plugin** (skills, docs — does **not** ship the executable) |

---

## Architectural decision (2026-10-23): npm CLI supersedes plugin execution

**Supersedes:** plugin-installed bundles (`dist/validate-plans.mjs`), `run-plan-validate.sh`, filesystem discovery heuristics, and `TEAM_HARNESS_PLUGIN_ROOT` / `CURSOR_PLUGIN_ROOT` assumptions.

**Why abandoned:**

- Cursor plugin install paths on disk remain **unverified** for Cloud Agents ([Cursor Plugins](https://cursor.com/docs/plugins)).
- Env-based plugin root (`CURSOR_PLUGIN_ROOT`) is **unverified** in agent shells.
- `npx -p tsx -p yaml` failed to resolve `yaml` for bundled TS in CI/resumes smoke (dynamic `require("process")` / module resolution).
- A committed plugin `.mjs` duplicate added **artifact drift** burden separate from source.

**Replacement:** one npm package (`@multipliers-dev/plan-validator@0.1.0`, not published in the marketplace PR slice) built with esbuild from the same TS source; consumers pin an **exact semver**.

---

## Canonical source (single implementation)

| Layer | Path |
| --- | --- |
| Library + CLI source | `plugins/team-harness/scripts/lib/plan-validate.ts`, `validate-plans.ts` |
| npm package wrapper | `packages/plan-validator/` (build only — no second validator logic) |
| Build output | `packages/plan-validator/dist/plan-validator.mjs` (generated at build/pack time, not a second committed artifact under `plugins/`) |

**Layout choice:** source stays under `plugins/team-harness/scripts/` so existing Vitest fixtures and marketplace `validate:plans` scripts keep working; the package **consumes** that entrypoint via esbuild.

**yaml:** bundled inside the distributable JS (self-contained CLI, zero production dependencies). Avoids consumer `node_modules` resolution issues that broke the plugin `npx` path.

**Node:** `engines.node >= 22` for the published package (esbuild target `node22`). Reusable workflow uses Node 22.

---

## Local / agent usage (after publish)

From the **consumer repository** root:

```bash
npm exec --yes --package=@multipliers-dev/plan-validator@0.1.0 -- \
  plan-validator --repo-root "$(pwd)" --allow-empty
```

Template profile:

```bash
npm exec --yes --package=@multipliers-dev/plan-validator@0.1.0 -- \
  plan-validator --repo-root "$(pwd)" --profile template .cursor/plans/_template.plan.md
```

Installing the **team-harness** Cursor plugin does **not** install this npm package or configure CI.

---

## Reusable GitHub Actions workflow

**Path:** `multipliers-dev/cursor-team-marketplace/.github/workflows/validate-plans.yml`

**Permissions:** caller job `contents: read` only.

### Inputs

| Input | Required | Purpose |
| --- | --- | --- |
| `validator_version` | **yes** | Exact semver `x.y.z` of `@multipliers-dev/plan-validator` (no ranges/tags/latest) |
| `pre_publish_tarball` | no | **Marketplace-internal:** build/install from repo tarball instead of registry (pre-publication CI) |
| `template_path` | no | Optional `--profile template` on caller-relative path |
| `allow_empty` | no (default true) | `--allow-empty` |

There is **no** `marketplace_ref` and **no** `github.workflow_ref` parsing.

### Caller snippet (post-publication)

```yaml
permissions:
  contents: read

jobs:
  validate-plans:
    uses: multipliers-dev/cursor-team-marketplace/.github/workflows/validate-plans.yml@<WORKFLOW_SHA>
    with:
      validator_version: "0.1.0"
      allow_empty: true
```

Pin **`validator_version`** to the published npm version. Pin the workflow **`uses:@<sha>`** to the marketplace commit that defines the workflow file you trust.

**Not testable in registry mode until `0.1.0` is published.** Marketplace CI uses `pre_publish_tarball: true` to exercise the same CLI via `npm pack` + local install.

### Behavior

1. Check out **caller** to `${{ github.workspace }}/caller`.
2. Run `plan-validator --repo-root` against the caller only.
3. Normal mode: `npm exec --package=@multipliers-dev/plan-validator@<version> -- plan-validator …`
4. Pre-publish mode: build tarball from marketplace checkout, install, run bin.

---

## Package build, verify, publish

| Command | Where |
| --- | --- |
| `npm run build:plan-validator` | Marketplace root (workspace) |
| `npm run verify:plan-validator` | build + `npm pack --dry-run` |
| `sh scripts/plan-validator-package-smoke.sh` | Tarball install + fixture smoke (CI) |

**Publish (not run in this slice):** `.github/workflows/publish-plan-validator.yml` — `workflow_dispatch` (confirm version) or tag `plan-validator-v*`, `id-token: write`, `npm publish --provenance --access public` ([npm trusted publishers](https://docs.npmjs.com/generating-provenance-statements#about-trusted-publishers)).

### One-time npm prerequisites (maintainer)

1. Create npm org **`@multipliers-dev`** (if it does not exist) and grant publish access to maintainers.
2. Configure **trusted publisher** on npm for package `@multipliers-dev/plan-validator`: GitHub repo `multipliers-dev/cursor-team-marketplace`, workflow file `.github/workflows/publish-plan-validator.yml`, environment (if used).
3. First publish may require org scope ownership; trusted publishing avoids long-lived `NPM_TOKEN` when OIDC is configured ([npm docs](https://docs.npmjs.com/trusted-publishers)).

**Availability check (2026-10-23):** `npm view @multipliers-dev/plan-validator` → **404 Not Found** (name available). Could not verify org existence without npm login (`npm view @multipliers-dev` is not a valid query).

---

## Version updates

Bump `packages/plan-validator/package.json` version, publish via authorized workflow, then update consumer `validator_version` pins and reusable workflow `uses:@sha` when workflow logic changes.

---

## Smoke evidence (historical)

**Superseded marketplace-checkout reusable workflow** (pin `f1ca17c`, `marketplace_ref` + committed plugin `.mjs`): [39877373830](https://github.com/mastermichaelt/resumes/actions/runs/39877373830) valid pass, [39877507980](https://github.com/mastermichaelt/resumes/actions/runs/39877507980) invalid `[authority.table.missing-row]`, [39877627036](https://github.com/mastermichaelt/resumes/actions/runs/39877627036) allow-empty skip — caller paths under `/home/runner/work/resumes/resumes/caller/`. **Does not validate the npm-backed workflow.**

**Plugin wrapper:** abandoned (yaml resolution / install-path uncertainty).

**Remaining:** publish `0.1.0` + consumer smoke of **published** CLI and registry-mode reusable workflow.

---

## Related

- Source: `plugins/team-harness/scripts/validate-plans.ts`
- Package: `packages/plan-validator/`
- Planning skill: `plugins/team-harness/skills/planning-methodology/SKILL.md`
