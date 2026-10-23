# Centralized plan validation (consumption)

How consuming repositories run the **canonical** plan validator in `multipliers-dev/cursor-team-marketplace` without copying `plugins/team-harness/scripts/` into the consumer.

Two supported surfaces:

| Surface | Where it runs | Best for |
| --- | --- | --- |
| **Plugin + shell wrapper** | Developer machine or Cloud Agent with team-harness installed | Ad-hoc agent runs, local pre-push |
| **Reusable GitHub Actions workflow** | Caller repo CI | Deterministic gates on every PR |

Do **not** vendor validator TypeScript into consumer repos. If the plugin path is unavailable, use the reusable workflow (or a one-off `actions/checkout` of the marketplace at a pinned SHA plus `npm ci` there)—not a source copy.

---

## How Cursor exposes installed plugin files

Sources are [Cursor Plugins](https://cursor.com/docs/plugins), [Plugins reference](https://cursor.com/docs/reference/plugins), and [Agent Skills](https://cursor.com/docs/skills). Behavior below is verified only where noted.

### Install locations

| Scope | Documented / observed | Verified in this repo |
| --- | --- | --- |
| Local development | `~/.cursor/plugins/local/<plugin-name>/` after “Test plugins locally” | **Unverified** on Cloud Agents |
| Marketplace install | Customize → Plugins → Install (project or user scope) | **Unverified** exact filesystem path on desktop vs Cloud Agent |
| Team marketplace | Git-backed plugin tree indexed from `multipliers-dev/cursor-team-marketplace` | **Verified**: marketplace ships `plugins/team-harness/` in git |
| Project skills | `.cursor/skills/<name>/SKILL.md` in the repo | **Verified**: loaded from repo checkout |
| User skills | `~/.cursor/skills/` | **Verified** in docs; **not** auto-synced to Cloud Agents without explicit sync |

Cursor docs state that a running Cloud Agent keeps plugin versions from when it **started**; start a new agent after marketplace updates ([Plugins — Keep plugins up to date](https://cursor.com/docs/plugins)).

### Skills vs bundled scripts

- Skills are discovered from `skills/<skill-name>/SKILL.md` (Agent Plugins package layout) or paths declared in `.cursor-plugin/plugin.json` ([Plugins reference — Plugin structure](https://cursor.com/docs/reference/plugins)).
- Cursor Plugins may include a top-level `scripts/` directory for hooks and utilities ([Plugins reference](https://cursor.com/docs/reference/plugins)). **team-harness** ships `scripts/validate-plans.ts` and `scripts/run-plan-validate.sh` there.
- Agent Skills may include optional `scripts/` next to `SKILL.md` ([Agent Skills](https://cursor.com/docs/skills)). The planning-methodology skill does **not** duplicate the validator; it points agents at the plugin `scripts/` entrypoint.

**Can a skill reference its own bundled script path?** Yes for skills that colocate scripts under the skill folder. For team-harness, the validator lives in **plugin** `scripts/`, not under `skills/planning-methodology/scripts/`. Agents should resolve the installed **team-harness** plugin root (same pattern as `/cloud-hooks-bootstrap` and `/repo-bootstrap`) and run `scripts/run-plan-validate.sh` from that root.

**`${CURSOR_PLUGIN_ROOT}` / `${PLUGIN_ROOT}`:** Cursor docs recommend `${CURSOR_PLUGIN_ROOT}` for MCP in Cursor Plugins; Agent Plugins `${PLUGIN_ROOT}` is **not** expanded in `mcp.json` ([Plugins — Agent Plugins standard](https://cursor.com/docs/plugins)). Whether Cloud Agent shells export `CURSOR_PLUGIN_ROOT` for hook scripts is **unverified**—the wrapper supports `TEAM_HARNESS_PLUGIN_ROOT` explicitly.

### Runtime on a consumer checkout

| Requirement | Plugin wrapper path | Reusable workflow path |
| --- | --- | --- |
| Node.js | Required (20+ typical) | Provided (`setup-node` 22) |
| `tsx` | Fetched via `npx -p tsx` | From marketplace `npm ci` |
| `yaml` | Fetched via `npx -p yaml` | From marketplace `npm ci` |
| Consumer `npm ci` | **Not** required | **Not** required |

The wrapper uses `npx --yes -p tsx -p yaml tsx …` so consumers do not need marketplace `node_modules` on disk.

---

## Plugin-side invocation

### Tell whether team-harness is installed

1. **Customize → Plugins / Skills:** look for **team-harness** or skills `planning-methodology`, `repo-bootstrap`, `cloud-hooks-bootstrap`.
2. **On disk:** locate `validate-plans.ts` under an installed plugin tree, or set `TEAM_HARNESS_PLUGIN_ROOT` manually.

If the plugin is **not** installed:

- Install **team-harness** from the team marketplace (Customize), **or**
- For CI only, skip the plugin and use the reusable workflow below, **or**
- For a one-off agent run without the plugin, checkout `multipliers-dev/cursor-team-marketplace` at a pinned SHA in a **separate directory**, run `npm ci` there, and invoke `validate-plans.ts` with `--repo-root` pointing at the consumer repo—**do not** copy sources into the consumer.

### Command (consumer repo root)

From the **consumer repository** root (prove with `pwd` and `git remote get-url origin` in the same shell as the command):

```bash
sh /path/to/installed/team-harness/scripts/run-plan-validate.sh --repo-root "$(pwd)" --allow-empty
```

Strict template profile (when the consumer maintains a template path):

```bash
sh "$TEAM_HARNESS_PLUGIN_ROOT/scripts/run-plan-validate.sh" \
  --repo-root "$(pwd)" \
  --profile template \
  .cursor/plans/_template.plan.md
```

When the wrapper lives in a git clone of the marketplace (development), `run-plan-validate.sh` resolves the plugin root relative to itself.

**Failure behavior:** missing plugin, missing Node/npx, or validator diagnostics → non-zero exit; stderr explains the failure. No silent fallback to copied validator source.

---

## Reusable GitHub Actions workflow

**Path:** `.github/workflows/validate-plans.yml` in `multipliers-dev/cursor-team-marketplace`.

**Permissions (caller job):** `contents: read` only. The reusable workflow does not mutate the caller repository.

### Version pinning

Pin the **same commit SHA** on both the `uses:` line and (optionally) `marketplace_ref`:

```yaml
permissions:
  contents: read

jobs:
  validate-plans:
    uses: multipliers-dev/cursor-team-marketplace/.github/workflows/validate-plans.yml@<FULL_COMMIT_SHA>
    with:
      marketplace_ref: <FULL_COMMIT_SHA>
      allow_empty: true
      # template_path: .cursor/plans/_template.plan.md   # optional strict template gate
```

Why both?

- The `@<sha>` on `uses:` selects the **workflow definition** ([Reusing workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)).
- `marketplace_ref` selects the **validator source tree** checked out to `marketplace-validator/` (defaults by parsing `github.workflow_ref` after `@` when omitted).

For `./.github/workflows/validate-plans.yml` **same-repo** calls (marketplace CI), `github.workflow_ref` has no `@sha` suffix—pass `marketplace_ref: ${{ github.sha }}` explicitly.

Prefer **full commit SHA** over floating branches. Protected tags are acceptable when your org treats them as immutable.

### Inputs

| Input | Type | Default | Purpose |
| --- | --- | --- | --- |
| `marketplace_ref` | string | (parse `workflow_ref`) | Validator git ref |
| `template_path` | string | (empty) | Optional `--profile template` on caller-relative path |
| `allow_empty` | boolean | `true` | Pass `--allow-empty` for repos with no active plans |

### What the workflow does

1. Check out the **caller** repo to `${{ github.workspace }}/caller`.
2. Check out **cursor-team-marketplace** at `marketplace_ref` to `marketplace-validator/`.
3. Run guard steps so plan discovery uses `--repo-root` = caller, never the marketplace checkout alone.
4. `npm ci` in `marketplace-validator/` only.
5. Run `validate-plans.ts` against the caller root.

### Updates

Bump the SHA (and `marketplace_ref`) in consumer workflow files when adopting validator fixes. Document the pin in the consumer README or plan-status PR (see plan slice `consumer-adoption`).

### Failure behavior

- Misconfigured ref → workflow fails at checkout or ref resolution.
- Plan issues → validator exit `1` with diagnostics on stderr.
- No active plans with `allow_empty: true` → exit `0` with skip message (same as local CLI).

---

## Permissions and cross-owner callers

- Marketplace repository is **public**; `workflow_call` from `mastermichaelt/*` (and other owners) is supported subject to GitHub Actions policy.
- Caller workflows should declare minimal permissions (`contents: read`).
- No `GITHUB_TOKEN` write scopes are required for validation.

---

## Smoke evidence (resumes)

Production smoke for plugin + reusable workflow on `mastermichaelt/resumes` runs in a **separate** Cloud Agent session after the marketplace PR is open. See the marketplace PR body section **Smoke evidence: pending (separate resumes session)**.

---

## Related

- Validator CLI: `plugins/team-harness/scripts/validate-plans.ts`
- Wrapper: `plugins/team-harness/scripts/run-plan-validate.sh`
- Planning skill: `plugins/team-harness/skills/planning-methodology/SKILL.md` (Plan validation subsection)
- Version alignment when shipping consumption surfaces: [versioning.md](versioning.md)
