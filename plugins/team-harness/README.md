# team-harness

Cursor plugin: portable **planning methodology**, **repo bootstrap**, and **Cloud-hooks** primitive.

## Skills

| Skill                     | Invoke                     | Role                                                                          |
| ------------------------- | -------------------------- | ----------------------------------------------------------------------------- |
| `planning-methodology`    | `/planning-methodology`    | Full staged-plan / merge-safe procedure (canonical copy)                      |
| `repo-bootstrap`          | `/repo-bootstrap`          | One-shot empty-directory → pre-wired greenfield repo (tsx run/dev + Vitest + hooks + CI + GitHub) |
| `cloud-hooks-bootstrap`   | `/cloud-hooks-bootstrap`   | One-time Husky Cloud wiring + `environment.json` lifecycle using scripts in `scripts/` |

## Scripts (portable primitive)

Copy into a target repo during one-time bootstrap — locate scripts in the installed **team-harness** plugin (see `/cloud-hooks-bootstrap` and `/repo-bootstrap`; stop if the plugin files are not on disk). Or run `repo-bootstrap.sh` to copy the greenfield preset plus the hook allowlist automatically:

| Script                                | Purpose                                                                                                    |
| ------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `scripts/repo-bootstrap.sh` | Bootstrap an empty directory into a pre-wired greenfield repo (template + hook allowlist + GitHub remote)   |
| `scripts/prepare-git-hooks.sh`        | Cloud-aware `prepare`: install/repair Husky shims, verify (non-fatal under `set -e`), then ensure-hooks last — ensure-hooks always runs after Husky even when verify fails; prepare still exits non-zero on bad shims |
| `scripts/verify-git-hooks.sh`         | Fail when any repo-defined Git hook under `.husky/<hook>` lacks an executable `.husky/_/<hook>` shim; helpers like `common.sh` are ignored |
| `scripts/ensure-hooks.sh`             | Bridge Cloud `agent-hooks` dispatcher → `~/.cursor/husky-bridge` → current repo `.husky/*`                 |
| `scripts/session-ensure-git-hooks.sh` | `sessionStart` rechain when `agent-hooks` appears after late prepare                                       |
| `scripts/cloud-agent-session-path.sh` | Prepend `/usr/local/bin` on `PATH` (idempotent)                                                            |
| `scripts/cloud-agent-install.sh`      | Node-from-`.nvmrc` major → full prefix under `/usr/local`; persist PATH; run declared dependency command |
| `scripts/cloud-agent-start.sh`        | Session PATH + Node probe log + `ensure-hooks.sh`                                                          |

**Plugin install alone does not wire `package.json` `prepare`, `.husky/` contents, or `.cursor/environment.json`.** When Cloud Agents are expected, wiring includes committed `environment.json` lifecycle and, when `.nvmrc` pins a newer major, Node-from-`.nvmrc` Build/session PATH — not only `prepare`. See `/cloud-hooks-bootstrap`.
