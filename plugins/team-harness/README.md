# team-harness

Cursor plugin: portable **planning methodology**, **new-repo bootstrap**, **interview repo bootstrap**, and **Cloud-hooks** primitive.

## Skills

| Skill                     | Invoke                     | Role                                                                          |
| ------------------------- | -------------------------- | ----------------------------------------------------------------------------- |
| `planning-methodology`    | `/planning-methodology`    | Full staged-plan / merge-safe procedure (canonical copy)                      |
| `new-repo-bootstrap`      | `/new-repo-bootstrap`      | 5-minute checklist: inherited team layer vs in-repo adds (optional thin GitHub PR template) |
| `interview-repo-bootstrap`| `/interview-repo-bootstrap`| One-shot empty-directory → pre-wired interview repo (tsx run/dev + Vitest + hooks + CI + GitHub) |
| `cloud-hooks-bootstrap`   | `/cloud-hooks-bootstrap`   | One-time Husky Cloud wiring + `environment.json` lifecycle using scripts in `scripts/` |

## Scripts (portable primitive)

Copy into a target repo (or invoke paths from this plugin after install) during one-time bootstrap — or run `interview-repo-bootstrap.sh` to copy the interview preset plus the hook allowlist automatically:

| Script                                | Purpose                                                                                                    |
| ------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `scripts/interview-repo-bootstrap.sh` | Bootstrap an empty directory into a pre-wired interview repo (template + hook allowlist + GitHub remote)   |
| `scripts/prepare-git-hooks.sh`        | Cloud-aware `prepare`: install/repair Husky shims, verify, then ensure-hooks last (Cloud agent-hooks path restored after Husky) |
| `scripts/verify-git-hooks.sh`         | Fail when any defined `.husky/<hook>` lacks an executable `.husky/_/<hook>` shim |
| `scripts/ensure-hooks.sh`             | Bridge Cloud `agent-hooks` dispatcher → `~/.cursor/husky-bridge` → current repo `.husky/*`                 |
| `scripts/session-ensure-git-hooks.sh` | `sessionStart` rechain when `agent-hooks` appears after late prepare                                       |
| `scripts/cloud-agent-session-path.sh` | Prepend `/usr/local/bin` on `PATH` (idempotent)                                                            |
| `scripts/cloud-agent-install.sh`      | Node-from-`.nvmrc` major → full prefix under `/usr/local`; persist PATH; run declared dependency command |
| `scripts/cloud-agent-start.sh`        | Session PATH + Node probe log + `ensure-hooks.sh`                                                          |

**Default On does not wire `package.json` `prepare`, `.husky/` contents, or `.cursor/environment.json`.** When Cloud Agents are expected, wiring includes committed `environment.json` lifecycle and, when `.nvmrc` pins a newer major, Node-from-`.nvmrc` Build/session PATH — not only `prepare`. See `/cloud-hooks-bootstrap`.
