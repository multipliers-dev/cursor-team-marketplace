# cursor-team-marketplace

Public Team Marketplace for [multipliers-dev](https://github.com/multipliers-dev): one plugin that ships two capabilities with different portability semantics.

| Component | After **Default On** | Meaning |
| --- | --- | --- |
| **Planning methodology skill** | Automatic skill install | Single canonical planning procedure for every repo |
| **Cloud-hooks primitive** | Scripts + bootstrap skill available | **Not** automatic Cloud-safety — each Husky repo still needs one-time `prepare` / wiring |

## Import + Default On

1. Dashboard → **Plugins** → Team Marketplaces
2. Import this repository: `https://github.com/multipliers-dev/cursor-team-marketplace`
3. Set plugin **`team-harness`** to **Default On**
4. Do **not** treat Default On as zero-wiring Cloud-safety for new Husky repos

## Local smoke (before / without marketplace)

```bash
ln -sfn /absolute/path/to/cursor-team-marketplace/plugins/team-harness ~/.cursor/plugins/local/team-harness
# Reload Cursor window, then invoke /planning-methodology (e.g. in ai-learning)
```

## Layout

```text
.
├── .cursor-plugin/marketplace.json
└── plugins/team-harness/
    ├── .cursor-plugin/plugin.json
    ├── skills/planning-methodology/
    ├── skills/cloud-hooks-bootstrap/
    └── scripts/   # prepare-git-hooks.sh, ensure-hooks.sh, session-ensure-git-hooks.sh
```

## Explicit non-goals

- No Team Rules in this package (Rules pointer lands separately in Cursor Team Rules)
- No product checklists (API/board/client-state, resumes research, portfolio routes)
- No claim that Default On makes Husky Cloud-safe without repo wiring
