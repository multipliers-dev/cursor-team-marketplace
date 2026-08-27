# cursor-team-marketplace

Public Team Marketplace for [multipliers-dev](https://github.com/multipliers-dev): one plugin that ships four capabilities with different portability semantics.

| Component | After install | Meaning |
| --- | --- | --- |
| **Planning methodology skill** | Skill available in Agent chats | Single canonical planning procedure for every repo |
| **New-repo bootstrap skill** | `/new-repo-bootstrap` | 5-minute checklist: inherited team layer vs in-repo adds |
| **Interview repo bootstrap** | `/interview-repo-bootstrap` + `interview-repo-bootstrap.sh` | One-shot empty-directory → pre-wired interview repo (tsx run/dev + verify + enforce; no product decisions) |
| **Cloud-hooks primitive** | Scripts + bootstrap skill available | **Not** automatic Cloud-safety — each Husky repo still needs one-time `prepare` / wiring; when Cloud Agents are expected, also commit `environment.json` lifecycle (and Node-from-`.nvmrc` wrappers when `.nvmrc` pins a newer major). The interview preset ships this wiring automatically; use `/cloud-hooks-bootstrap` for existing repos. |

## Install

Not a listing on the public Cursor Marketplace.

1. Customize (sidebar) → **Plugins** → **+ Add** → **From GitHub Repository** → paste `https://github.com/multipliers-dev/cursor-team-marketplace`
2. If you already have a checkout: **+ Add** → **From Local Repository** and select `plugins/team-harness` (the folder that contains `.cursor-plugin/plugin.json`).

## Engineering invariants

Installing `team-harness` does **not** install Cursor rules. Rules are a separate surface from the plugin.

Customize (sidebar) → **Rules** → **User** → **+ New** → paste [docs/engineering-invariants.md](docs/engineering-invariants.md).

## Layout

```text
.
├── .cursor-plugin/marketplace.json
├── docs/engineering-invariants.md
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

- This package does not install Cursor rules — see [Engineering invariants](#engineering-invariants) and [docs/engineering-invariants.md](docs/engineering-invariants.md)
- No product checklists (API/board/client-state, resumes research, portfolio routes)
- No product harness copy-paste recipe (use `/new-repo-bootstrap` instead)

## License

MIT — see [LICENSE](LICENSE).
