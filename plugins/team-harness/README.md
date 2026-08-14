# team-harness

Cursor plugin: portable **planning methodology**, **new-repo bootstrap**, and **Cloud-hooks** primitive.

## Skills

| Skill                   | Invoke                   | Role                                                                          |
| ----------------------- | ------------------------ | ----------------------------------------------------------------------------- |
| `planning-methodology`  | `/planning-methodology`  | Full staged-plan / merge-safe procedure (canonical copy)                      |
| `new-repo-bootstrap`    | `/new-repo-bootstrap`    | 5-minute checklist: what the team layer already provides vs what to add in-repo |
| `cloud-hooks-bootstrap` | `/cloud-hooks-bootstrap` | One-time Husky Cloud wiring using scripts in `scripts/`                       |

## Scripts (portable primitive)

Copy into a target repo (or invoke paths from this plugin after install) during one-time bootstrap:

| Script                                | Purpose                                                                                                    |
| ------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `scripts/prepare-git-hooks.sh`        | Cloud-aware `prepare`: install Husky on Cursor Cloud even when `CI=true`; skip Vercel / GHA / non-Cloud CI |
| `scripts/ensure-hooks.sh`             | Bridge Cloud `agent-hooks` dispatcher → `~/.cursor/husky-bridge` → current repo `.husky/*`                 |
| `scripts/session-ensure-git-hooks.sh` | `sessionStart` rechain when `agent-hooks` appears after late prepare                                       |

**Default On does not wire `package.json` `prepare` or `.husky/` contents.** See `/cloud-hooks-bootstrap`.
