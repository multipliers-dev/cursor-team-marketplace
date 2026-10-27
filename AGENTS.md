# Agent instructions

Cursor plugin marketplace for [multipliers-dev](https://github.com/multipliers-dev) team-harness (planning methodology, repo bootstrap, cloud-hooks bootstrap).

## Commands

| Command | Purpose |
| --- | --- |
| `npm test` | Build plan-validator workspace and run Vitest |
| `npm run typecheck` | Typecheck scripts |
| `npm run validate:plans` | Structural checks for `.cursor/plans/*.plan.md` |

See [README.md](README.md) for install, components, and engineering invariants. Session logging uses the installed team-harness Savepoints integration (global User Rules + vendored skills under `plugins/team-harness/vendor/savepoints-lite/`); see [engineering invariants](docs/engineering-invariants.md).

## Discipline

- Keep changes focused; do not add product scaffolding unless the task requires it.
- Commit in small, logical steps with clear messages.
