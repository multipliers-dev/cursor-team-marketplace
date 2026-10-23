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
| `validator_version` | **yes** | Exact release semver `x.y.z` only (intentionally **no** prerelease/build suffixes, ranges, or dist-tags) |
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

**Registry mode is not testable in consumer CI until `0.1.0` is published.** External callers cannot enable tarball mode — the public reusable workflow has no tarball or marketplace-checkout inputs.

### Behavior (registry-only)

1. Check out **caller** to `${{ github.workspace }}/caller` (no marketplace checkout).
2. `npm exec --package=@multipliers-dev/plan-validator@<exact-version> -- plan-validator --repo-root <caller> …`

### Marketplace-only pre-publication CI (not reusable)

Before publish, marketplace CI validates the tarball locally (not exposed to consumer repos):

| Step | Script / job |
| --- | --- |
| Isolated tarball fixture smoke | `scripts/plan-validator-package-smoke.sh` |
| Marketplace-as-caller gates | `scripts/plan-validator-marketplace-tarball-gates.sh` |
| CI job | `plan-validator-tarball-ci` in `.github/workflows/ci.yml` |

---

## Package build, verify, publish

| Command | Where |
| --- | --- |
| `npm run build:plan-validator` | Marketplace root (workspace) |
| `npm run verify:plan-validator` | build + `npm pack --dry-run` |
| `sh scripts/plan-validator-package-smoke.sh` | Tarball install + fixture smoke |
| `sh scripts/plan-validator-marketplace-tarball-gates.sh` | Tarball + allow-empty/template on repo root |

**Publish (separate maintainer authorization; not run in the marketplace implementation PR):** `.github/workflows/publish-plan-validator.yml` — **`workflow_dispatch` only** on **`main`** (`if: github.ref == 'refs/heads/main'`); input `confirm_version` (whitespace-trimmed) must match `package.json`; `id-token: write`; installs **`npm@11.15.0`** globally (OIDC trusted publishing requires npm CLI **≥ 11.5.1** per [npm trusted publishing](https://docs.npmjs.com/trusted-publishers/)); then `npm publish --provenance --access public`.

### First publish bootstrap (verified against npm docs)

Trusted publisher settings live on **each package’s** npmjs.com **Settings** page ([trusted publishing — Step 1](https://docs.npmjs.com/trusted-publishers/)). That page does **not** exist until the package has been published at least once. **`npm trust` CLI likewise requires the package to already exist on the registry** ([`npm trust` prerequisites](https://docs.npmjs.com/cli/v11/commands/npm-trust/)).

**Order:**

1. Create npm org **`@multipliers-dev`** if needed (unverified whether it already exists — requires npm login).
2. **One-time manual first publish** by a maintainer with org access (typically `npm login` + 2FA, then from `packages/plan-validator/` after `npm run build`: `npm publish --access public`). Alternative: a **short-lived granular access token** with publish scope for this single bootstrap publish only — revoke after use. **Unverified:** exact org policy for scoped first publish.
3. On npmjs.com → **Packages → `@multipliers-dev/plan-validator` → Settings → Trusted publishing**, add GitHub Actions publisher: org/user `multipliers-dev`, repository `cursor-team-marketplace`, workflow filename `publish-plan-validator.yml` ([trusted publishing](https://docs.npmjs.com/trusted-publishers/)).
4. Complete a successful OIDC publish via `workflow_dispatch` within **2 days** of creating the trusted publisher config, or the config expires ([configuration expiry](https://docs.npmjs.com/trusted-publishers/#trusted-publisher-configuration-expiry)).
5. Optional hardening: **Publishing access → disallow tokens** after trusted publishing works ([recommended restriction](https://docs.npmjs.com/trusted-publishers/#recommended-restrict-token-access-when-using-trusted-publishers)).

Subsequent releases: bump `package.json` version → authorized `workflow_dispatch` with matching `confirm_version`.

**Availability (2026-10-23):** `npm view @multipliers-dev/plan-validator` → **404** (name available).

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
