# cursor-team-marketplace

Public Cursor plugin for [multipliers-dev](https://github.com/multipliers-dev): one plugin that ships three capabilities with different portability semantics.

| Component | After install | Portability | Meaning |
| --- | --- | --- | --- |
| **Planning methodology skill** | Skill available in Agent chats | **Cross-client** | Single canonical planning procedure for every repo |
| **Repo bootstrap** | `/repo-bootstrap` + `repo-bootstrap.sh` | **Cursor-dependent** | One-shot empty-directory → pre-wired greenfield repo (tsx run/dev + verify + enforce; no product decisions) |
| **Cloud-hooks primitive** | Scripts + bootstrap skill available | **Cursor-dependent** | **Not** automatic Cloud-safety — each Husky repo still needs one-time `prepare` / wiring; when Cloud Agents are expected, also commit `environment.json` lifecycle (and Node-from-`.nvmrc` wrappers when `.nvmrc` pins a newer major). The repo bootstrap preset ships this wiring automatically; use `/cloud-hooks-bootstrap` for existing repos. |

Agent Plugins discovery exposes all three skills under `skills/`. That does **not** make bootstrap or Cloud-hooks skills cross-client portable. See [plugins/team-harness/docs/layers.md](plugins/team-harness/docs/layers.md).

## Install

Not a listing on the public Cursor Marketplace.

Customize (sidebar) → **Plugins** → **+ Add** → **From GitHub Repository** → paste `https://github.com/multipliers-dev/cursor-team-marketplace`.

## Engineering invariants

Installing `team-harness` does **not** install Cursor rules. Rules are a separate surface from the plugin.

Customize (sidebar) → **Rules** → **User** → **+ New** → paste [docs/engineering-invariants.md](docs/engineering-invariants.md).

## License

MIT — see [LICENSE](LICENSE).
