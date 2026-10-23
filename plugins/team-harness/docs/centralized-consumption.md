# Centralized plan validation (consumption)

How consuming repositories run the **canonical** plan validator in `multipliers-dev/cursor-team-marketplace` without copying TypeScript sources into the consumer.

Two supported surfaces execute the **same committed artifact** (`plugins/team-harness/dist/validate-plans.mjs`):

| Surface | Where it runs | Best for |
| --- | --- | --- |
| **Plugin + shell wrapper** | Developer machine or Cloud Agent with team-harness installed | Ad-hoc agent runs, local pre-push |
| **Reusable GitHub Actions workflow** | Caller repo CI | Deterministic gates on every PR |

Do **not** vendor validator TypeScript into consumer repos.

---

## Canonical source vs distribution artifact

| Layer | Path | Role |
| --- | --- | --- |
| **Source (edit here)** | `plugins/team-harness/scripts/validate-plans.ts`, `scripts/lib/plan-validate.ts` | Single canonical implementation |
| **Bundle (committed)** | `plugins/team-harness/dist/validate-plans.mjs` | Self-contained ESM for Node 20+; includes `yaml` |

**Rebuild:** `npm run build:validator` (esbuild 0.28.2, target `node20`, ESM + `createRequire` shim for bundled `yaml`, no minify, `legalComments: none`, static banner — deterministic output).

**Drift gate:** `npm run check:validator-bundle-drift` rebuilds and fails if `git diff` on the `.mjs` is non-empty (runs in marketplace CI after `npm ci`).

Marketplace development still uses `tsx` on the TypeScript CLI for `npm run validate:plans*`; parity tests assert bundled CLI matches TS CLI.

---

## Node.js requirement

**Minimum: Node.js 20** (LTS). Tested on Node 20 and 22 (marketplace CI uses 22).

Consumers need **only** the `node` binary — no `npm ci`, `tsx`, or plugin `node_modules` at runtime.

---

## How Cursor exposes installed plugin files

Sources are [Cursor Plugins](https://cursor.com/docs/plugins), [Plugins reference](https://cursor.com/docs/reference/plugins), and [Agent Skills](https://cursor.com/docs/skills). Behavior below is verified only where noted.

### Install locations

| Scope | Documented / observed | Verified in this repo |
| --- | --- | --- |
| Local development | `~/.cursor/plugins/local/<plugin-name>/` after “Test plugins locally” | **Unverified** on Cloud Agents |
| Marketplace install | Customize → Plugins → Install (project or user scope) | **Unverified** exact filesystem path on desktop vs Cloud Agent |
| Team marketplace | Git-backed plugin tree indexed from `multipliers-dev/cursor-team-marketplace` | **Verified**: ships `plugins/team-harness/` including `dist/validate-plans.mjs` |
| Project skills | `.cursor/skills/<name>/SKILL.md` in the repo | **Verified**: loaded from repo checkout |
| User skills | `~/.cursor/skills/` | **Verified** in docs; **not** auto-synced to Cloud Agents without explicit sync |

Cursor docs state that a running Cloud Agent keeps plugin versions from when it **started**; start a new agent after marketplace updates ([Plugins — Keep plugins up to date](https://cursor.com/docs/plugins)).

### Skills vs bundled scripts

- Skills live under `skills/<skill-name>/SKILL.md` ([Plugins reference](https://cursor.com/docs/reference/plugins)).
- **team-harness** ships `scripts/run-plan-validate.sh` and the committed **`dist/validate-plans.mjs`** bundle (validator logic is not duplicated under the skill folder).
- Agents resolve the installed **team-harness** plugin root (same pattern as `/cloud-hooks-bootstrap`) and run the wrapper.

**`${CURSOR_PLUGIN_ROOT}`:** documented for MCP ([Plugins](https://cursor.com/docs/plugins)); shell export on Cloud Agents is **unverified** — use `TEAM_HARNESS_PLUGIN_ROOT` when needed.

### Runtime on a consumer checkout

| Requirement | Plugin wrapper | Reusable workflow |
| --- | --- | --- |
| Node.js 20+ | Required | `setup-node` 22 |
| npm / tsx / yaml package | **Not** required | **Not** required |
| Committed `.mjs` in plugin | Required at `dist/validate-plans.mjs` | Checked out from pinned `marketplace_ref` |

---

## Plugin-side invocation

### Tell whether team-harness is installed

1. **Customize → Plugins / Skills:** **team-harness** (or planning-methodology / repo-bootstrap skills).
2. **On disk:** `dist/validate-plans.mjs` under the plugin root, or set `TEAM_HARNESS_PLUGIN_ROOT`.

If the plugin is **not** installed: install from the team marketplace, or use the reusable workflow — do **not** copy validator source into the consumer.

### Command (consumer repo root)

From the **consumer repository** root (prove with `pwd` and `git remote get-url origin` in the same shell):

```bash
sh /path/to/installed/team-harness/scripts/run-plan-validate.sh --repo-root "$(pwd)" --allow-empty
```

Or invoke the bundle directly:

```bash
node /path/to/installed/team-harness/dist/validate-plans.mjs --repo-root "$(pwd)" --allow-empty
```

Strict template profile (consumer template path):

```bash
sh "$TEAM_HARNESS_PLUGIN_ROOT/scripts/run-plan-validate.sh" \
  --repo-root "$(pwd)" \
  --profile template \
  .cursor/plans/_template.plan.md
```

**Failure behavior:** missing plugin, missing/outdated Node, missing bundle, or validator diagnostics → non-zero exit with stderr message. No silent fallback to copied source.

---

## Reusable GitHub Actions workflow

**Path:** `.github/workflows/validate-plans.yml` in `multipliers-dev/cursor-team-marketplace`.

**Permissions (caller job):** `contents: read` only.

### Version pinning

Pin the **same commit SHA** on `uses:` and **`marketplace_ref`** (required input):

```yaml
permissions:
  contents: read

jobs:
  validate-plans:
    uses: multipliers-dev/cursor-team-marketplace/.github/workflows/validate-plans.yml@<FULL_COMMIT_SHA>
    with:
      marketplace_ref: <FULL_COMMIT_SHA>
      allow_empty: true
      # template_path: .cursor/plans/_template.plan.md
```

- `@<sha>` selects the **workflow definition** ([Reusing workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)).
- `marketplace_ref` selects the marketplace commit that contains the matching **`dist/validate-plans.mjs`**.

**Do not omit `marketplace_ref`.** In reusable workflows, `github.workflow_ref` is the **caller** workflow ref — omitting `marketplace_ref` previously caused checkout of the caller branch against the marketplace repo ([resumes smoke run 39877373830](https://github.com/mastermichaelt/resumes/actions/runs/39877373830)).

Same-repo marketplace CI must pass `marketplace_ref: ${{ github.sha }}`.

Prefer **40-character commit SHA** equal to the `uses:@` pin. Simple immutable tags are accepted; `refs/heads/*` from the caller are rejected.

### Inputs

| Input | Type | Required | Purpose |
| --- | --- | --- | --- |
| `marketplace_ref` | string | **yes** | Marketplace SHA/tag for checkout |
| `template_path` | string | no | Optional `--profile template` on caller-relative path |
| `allow_empty` | boolean | no (default `true`) | `--allow-empty` when no active plans |

### What the workflow does

1. Check out the **caller** repo to `${{ github.workspace }}/caller`.
2. Check out **cursor-team-marketplace** at `marketplace_ref` to `marketplace-validator/` (no `npm ci`).
3. Guard that `--repo-root` is the caller checkout.
4. Run `node marketplace-validator/plugins/team-harness/dist/validate-plans.mjs` — same artifact as the plugin wrapper.

### Failure behavior

- Invalid/missing `marketplace_ref` → fail before validation.
- Plan issues → exit `1` with diagnostics.
- No active plans with `allow_empty: true` → exit `0` with skip message.

---

## Permissions and cross-owner callers

- Public marketplace repo; `workflow_call` from other owners (e.g. `mastermichaelt/*`) is supported.
- Caller workflows: `contents: read` only.

---

## Smoke evidence (resumes)

Reusable workflow smoke (pin `f1ca17c` era) is recorded in marketplace PR #63. **Plugin-side smoke** against the Node-only bundle should be re-run on a new head in a separate resumes session after this PR updates.

---

## Related

- Source CLI: `plugins/team-harness/scripts/validate-plans.ts`
- Bundle: `plugins/team-harness/dist/validate-plans.mjs`
- Wrapper: `plugins/team-harness/scripts/run-plan-validate.sh`
- Build: `npm run build:validator`; drift: `npm run check:validator-bundle-drift`
- Planning skill: `plugins/team-harness/skills/planning-methodology/SKILL.md`
- Versioning: [versioning.md](versioning.md) (1.13.0 consumption surfaces in this PR)
