# team-harness

Cursor plugin: **merge-safe planning methodology** (cross-client) plus **repo bootstrap** and **Cloud-hooks bootstrap** skills (Cursor-dependent).

Package surface vs per-skill portability: [docs/layers.md](docs/layers.md). Version alignment: [docs/versioning.md](docs/versioning.md).

## Skills

| Skill | Invoke | Portability | Role |
| --- | --- | --- | --- |
| `planning-methodology` | `/planning-methodology` | **Cross-client** | Full staged-plan / merge-safe procedure (canonical copy) |
| `repo-bootstrap` | `/repo-bootstrap` | **Cursor-dependent** | One-shot empty-directory → pre-wired greenfield repo (tsx run/dev + Vitest + hooks + CI + GitHub) |
| `cloud-hooks-bootstrap` | `/cloud-hooks-bootstrap` | **Cursor-dependent** | One-time Husky Cloud wiring + `environment.json` lifecycle using scripts in `scripts/` |

Agent Plugins discovery exposes all three skills under `skills/`. That does **not** make `repo-bootstrap` or `cloud-hooks-bootstrap` cross-client portable — see [layers.md](docs/layers.md).

## Scripts (portable primitive)

Copy into a target repo during one-time bootstrap — locate scripts in the installed **team-harness** plugin (see `/cloud-hooks-bootstrap` and `/repo-bootstrap`; stop if the plugin files are not on disk). Or run `repo-bootstrap.sh` to copy the greenfield preset plus the hook allowlist automatically:

| Script                                | Purpose                                                                                                    |
| ------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `scripts/repo-bootstrap.sh` | Bootstrap an empty directory into a pre-wired greenfield repo (template + hook allowlist + GitHub remote)   |
| `scripts/prepare-git-hooks.sh`        | Cloud-aware `prepare`: install/repair Husky shims, verify (non-fatal under `set -e`), then ensure-hooks last — ensure-hooks always runs after Husky even when verify fails; prepare still exits non-zero on bad shims |
| `scripts/verify-git-hooks.sh`         | Fail when any repo-defined Git hook under `.husky/<hook>` lacks an executable `.husky/_/<hook>` shim; helpers like `common.sh` are ignored |
| `scripts/ensure-hooks.sh`             | Bridge Cloud `agent-hooks` dispatcher → `~/.cursor/husky-bridge` → current repo `.husky/*`; wait/require fail closed on Cloud |
| `scripts/husky-shim-repair.sh`        | Shared shim detection + husky re-run (sourced by prepare and sessionStart)                                 |
| `scripts/session-ensure-git-hooks.sh` | `sessionStart`: wait-rechain on Cloud, verify runnable shims, repair/warn (fail-open session)              |
| `scripts/format-after-edit.sh`        | Optional Layer 2a: fail-open Prettier on agent edits (copy to `.cursor/hooks/format.sh`)                 |
| `scripts/cloud-agent-session-path.sh` | Prepend `/usr/local/bin` on `PATH` (idempotent)                                                            |
| `scripts/cloud-agent-install.sh`      | Node-from-`.nvmrc` major → full prefix under `/usr/local`; persist PATH; run declared dependency command |
| `scripts/cloud-agent-start.sh`        | Session PATH + Node probe log + blocking `ensure-hooks` (wait mode, default 120s)                          |

**Plugin install alone does not wire `package.json` `prepare`, `.husky/` contents, or `.cursor/environment.json`.** When Cloud Agents are expected, wiring includes committed `environment.json` lifecycle and, when `.nvmrc` pins a newer major, Node-from-`.nvmrc` Build/session PATH — not only `prepare`. See `/cloud-hooks-bootstrap`.
