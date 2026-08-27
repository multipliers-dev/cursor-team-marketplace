# cursor-team-marketplace

Public Team Marketplace for [multipliers-dev](https://github.com/multipliers-dev): one plugin that ships four capabilities with different portability semantics.

| Component | After install | Meaning |
| --- | --- | --- |
| **Planning methodology skill** | Skill available in Agent chats | Single canonical planning procedure for every repo |
| **New-repo bootstrap skill** | `/new-repo-bootstrap` | 5-minute checklist: inherited team layer vs in-repo adds |
| **Interview repo bootstrap** | `/interview-repo-bootstrap` + `interview-repo-bootstrap.sh` | One-shot empty-directory → pre-wired interview repo (tsx run/dev + verify + enforce; no product decisions) |
| **Cloud-hooks primitive** | Scripts + bootstrap skill available | **Not** automatic Cloud-safety — each Husky repo still needs one-time `prepare` / wiring; when Cloud Agents are expected, also commit `environment.json` lifecycle (and Node-from-`.nvmrc` wrappers when `.nvmrc` pins a newer major). The interview preset ships this wiring automatically; use `/cloud-hooks-bootstrap` for existing repos. |

| Path | Who | How |
| --- | --- | --- |
| **Individual / local** | Personal Cursor — you cloned this repo or are following along from an article | Symlink the plugin under `~/.cursor/plugins/local/` (below) |
| **Team / Enterprise** | Org admins on Cursor **Teams** or **Enterprise** — not personal plans, not the public Cursor Marketplace | Dashboard → Team Marketplaces → Default On (below) |

## Individual / local

For **personal / individual Cursor use**: clone or checkout this repo, then symlink the plugin into your local plugins directory. This plugin is **not** on the public Cursor Marketplace; local symlink is the supported path for individual installs.

```bash
git clone https://github.com/multipliers-dev/cursor-team-marketplace.git
# or use an existing checkout — substitute your absolute path below
ln -sfn /absolute/path/to/cursor-team-marketplace/plugins/team-harness ~/.cursor/plugins/local/team-harness
# Reload Cursor window, then invoke /planning-methodology or /new-repo-bootstrap in any repo after reload
```

## Team / Enterprise

For **Teams / Enterprise org admins** — not personal plans, not the public Cursor Marketplace:

1. Dashboard → **Plugins** → **Team Marketplaces**
2. Import this repository: `https://github.com/multipliers-dev/cursor-team-marketplace`
3. Set plugin **`team-harness`** to **Default On**
4. Do **not** treat Default On as zero-wiring Cloud-safety for new Husky repos — when Cloud Agents are expected, wiring includes `environment.json` and optional Node-from-`.nvmrc` scripts (see `/cloud-hooks-bootstrap`)

## Team engineering invariants

Installing `team-harness` does **not** install any Cursor rules (User or Team). Rules are a separate surface from the marketplace plugin.

**Primary path (everyone — article readers, personal plans, Team members):** Customize (sidebar) → **Rules** → **User** → **+ New** → paste [docs/team-engineering-invariants.md](docs/team-engineering-invariants.md). User Rules have no Name/Required UI; the list row is a markdown preview. That is expected. The rule still applies in Agent chat.

**Optional uplevel (Teams/Enterprise admins):** paste the same markdown into Dashboard → **Team Rules** and mark **Required** if you want org-wide enforcement. Not required to use this marketplace or the invariants locally.

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
- No claim that Default On makes Husky Cloud-safe without repo wiring or writes `environment.json` / installs Node
- No product harness copy-paste recipe (use `/new-repo-bootstrap` instead)
- No org-level `.github` repo or team-wide GitHub PR convention system (thin in-repo template via `/new-repo-bootstrap` when useful)

## License

MIT — see [LICENSE](LICENSE).
