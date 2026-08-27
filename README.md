# cursor-team-marketplace

Public Cursor plugin for [multipliers-dev](https://github.com/multipliers-dev): one plugin that ships four capabilities with different portability semantics.

| Component | After install | Meaning |
| --- | --- | --- |
| **Planning methodology skill** | Skill available in Agent chats | Single canonical planning procedure for every repo |
| **New-repo bootstrap skill** | `/new-repo-bootstrap` | 5-minute checklist: User Rules / plugin skills vs in-repo adds |
| **Interview repo bootstrap** | `/interview-repo-bootstrap` + `interview-repo-bootstrap.sh` | One-shot empty-directory → pre-wired interview repo (tsx run/dev + verify + enforce; no product decisions) |
| **Cloud-hooks primitive** | Scripts + bootstrap skill available | **Not** automatic Cloud-safety — each Husky repo still needs one-time `prepare` / wiring; when Cloud Agents are expected, also commit `environment.json` lifecycle (and Node-from-`.nvmrc` wrappers when `.nvmrc` pins a newer major). The interview preset ships this wiring automatically; use `/cloud-hooks-bootstrap` for existing repos. |

## Install

Not a listing on the public Cursor Marketplace.

Customize (sidebar) → **Plugins** → **+ Add** → **From GitHub Repository** → paste `https://github.com/multipliers-dev/cursor-team-marketplace`.

## Engineering invariants

Installing `team-harness` does **not** install Cursor rules. Rules are a separate surface from the plugin.

Customize (sidebar) → **Rules** → **User** → **+ New** → paste [docs/engineering-invariants.md](docs/engineering-invariants.md).

## License

MIT — see [LICENSE](LICENSE).
