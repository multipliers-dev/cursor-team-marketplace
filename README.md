# cursor-team-marketplace

Public Team Marketplace for [multipliers-dev](https://github.com/multipliers-dev): one plugin that ships four capabilities with different portability semantics.

| Component | After install | Meaning |
| --- | --- | --- |
| **Planning methodology skill** | Skill available in Agent chats | Single canonical planning procedure for every repo |
| **New-repo bootstrap skill** | `/new-repo-bootstrap` | 5-minute checklist: inherited team layer vs in-repo adds |
| **Interview repo bootstrap** | `/interview-repo-bootstrap` + `interview-repo-bootstrap.sh` | One-shot empty-directory → pre-wired interview repo (tsx run/dev + verify + enforce; no product decisions) |
| **Cloud-hooks primitive** | Scripts + bootstrap skill available | **Not** automatic Cloud-safety — each Husky repo still needs one-time `prepare` / wiring; when Cloud Agents are expected, also commit `environment.json` lifecycle (and Node-from-`.nvmrc` wrappers when `.nvmrc` pins a newer major). The interview preset ships this wiring automatically; use `/cloud-hooks-bootstrap` for existing repos. |

## Install

Clone or checkout this repo, then symlink the plugin locally — not a published Cursor Marketplace listing:

```bash
git clone https://github.com/multipliers-dev/cursor-team-marketplace.git
# or use an existing checkout — substitute your absolute path below
ln -sfn /absolute/path/to/cursor-team-marketplace/plugins/team-harness ~/.cursor/plugins/local/team-harness
# Reload Cursor window, then invoke /planning-methodology or /new-repo-bootstrap in any repo after reload
```

## Team engineering invariants

Installing `team-harness` does **not** install Cursor rules. Rules are a separate surface from the plugin.

Customize (sidebar) → **Rules** → **User** → **+ New** → paste [docs/team-engineering-invariants.md](docs/team-engineering-invariants.md).

## Layout

```text
.
├── .cursor-plugin/marketplace.json
├── docs/team-engineering-invariants.md
└── plugins/team-harness/
    ├── .cursor-plugin/plugin.json
    ├── skills/planning-methodology/
    ├── skills/new-repo-bootstrap/
    ├── skills/interview-repo-bootstrap/
    ├── skills/cloud-hooks-bootstrap/
    ├── templates/interview-repo/
    └── scripts/   # interview-repo-bootstrap.sh, prepare-git-hooks.sh, verify-git-hooks.sh, ensure-hooks.sh, session-ensure-git-hooks.sh, cloud-agent-*.sh
```

## Checks

The `Protect main` ruleset requires a GitHub check named **`test`**. Locally:

```bash
sh scripts/check.sh
```

## Explicit non-goals

- This package does not install Cursor rules — see [Team engineering invariants](#team-engineering-invariants) and [docs/team-engineering-invariants.md](docs/team-engineering-invariants.md)
- No product checklists (API/board/client-state, resumes research, portfolio routes)
- No product harness copy-paste recipe (use `/new-repo-bootstrap` instead)

## License

MIT — see [LICENSE](LICENSE).
