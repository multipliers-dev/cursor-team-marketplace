# cursor-team-marketplace

Public Team Marketplace for [multipliers-dev](https://github.com/multipliers-dev): one plugin that ships three capabilities with different portability semantics.

| Component | After install | Meaning |
| --- | --- | --- |
| **Planning methodology skill** | Skill available in Agent chats | Single canonical planning procedure for every repo |
| **New-repo bootstrap skill** | `/new-repo-bootstrap` | 5-minute checklist: inherited team layer vs in-repo adds |
| **Cloud-hooks primitive** | Scripts + bootstrap skill available | **Not** automatic Cloud-safety — each Husky repo still needs one-time `prepare` / wiring |

## Import + Default On

1. Dashboard → **Plugins** → Team Marketplaces
2. Import this repository: `https://github.com/multipliers-dev/cursor-team-marketplace`
3. Set plugin **`team-harness`** to **Default On**
4. Do **not** treat Default On as zero-wiring Cloud-safety for new Husky repos

## Local smoke (before / without marketplace)

```bash
ln -sfn /absolute/path/to/cursor-team-marketplace/plugins/team-harness ~/.cursor/plugins/local/team-harness
# Reload Cursor window, then invoke /planning-methodology or /new-repo-bootstrap (e.g. in ai-learning)
```

## Layout

```text
.
├── .cursor-plugin/marketplace.json
└── plugins/team-harness/
    ├── .cursor-plugin/plugin.json
    ├── skills/planning-methodology/
    ├── skills/new-repo-bootstrap/
    ├── skills/cloud-hooks-bootstrap/
    └── scripts/   # prepare-git-hooks.sh, ensure-hooks.sh, session-ensure-git-hooks.sh
```

## Checks

The `Protect main` ruleset requires a GitHub check named **`test`**. Locally:

```bash
sh scripts/check.sh
```

## Explicit non-goals

- No Team Rules in this package (Rules pointer lands separately in Cursor Team Rules)
- No product checklists (API/board/client-state, resumes research, portfolio routes)
- No claim that Default On makes Husky Cloud-safe without repo wiring
- No product harness copy-paste recipe (use `/new-repo-bootstrap` instead)
- No org-level `.github` repo or team-wide GitHub PR convention system (thin in-repo template via `/new-repo-bootstrap` when useful)
