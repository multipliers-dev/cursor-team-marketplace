# cursor-team-marketplace

Public Cursor plugin for [multipliers-dev](https://github.com/multipliers-dev): one plugin that ships three capabilities with different portability semantics.

**Background:** [I was solving agent portability at the wrong boundary](https://dev.to/michaeltruong/i-was-solving-agent-portability-at-the-wrong-boundary-1406) (DEV Community) — the scope split (policy vs procedures vs repo mechanics), portability boundaries, and architecture that led to this repository.

| Component | After install | Portability | Meaning |
| --- | --- | --- | --- |
| **Planning methodology skill** | Skill available in Agent chats | **Cross-client** | Single canonical planning procedure for every repo |
| **Repo bootstrap** | `/repo-bootstrap` + `repo-bootstrap.sh` | **Cursor-dependent** | One-shot empty-directory → pre-wired greenfield repo (tsx run/dev + verify + enforce; no product decisions) |
| **Cloud-hooks primitive** | Scripts + bootstrap skill available | **Cursor-dependent** | **Not** automatic Cloud-safety — each Husky repo still needs one-time `prepare` / wiring; when Cloud Agents are expected, also commit `environment.json` lifecycle (and Node-from-`.nvmrc` wrappers when `.nvmrc` pins a newer major). The repo bootstrap preset ships this wiring automatically; use `/cloud-hooks-bootstrap` for existing repos. |

## Git hook reliability across worktrees and Cloud Agents

**Background:** [Git said the commit succeeded. My hooks never ran.](https://dev.to/michaeltruong/git-said-the-commit-succeeded-my-hooks-never-ran-49e2) — the worktree incident that motivated these safeguards, and why hook availability, agent feedback, pre-commit checks, and CI need separate responsibilities.

A configured `core.hooksPath` does not guarantee that Git hooks execute. New worktrees can lack executable Husky shims, while Cursor Cloud Agents introduce a separate hook-dispatcher lifecycle.

The [cloud-hooks-bootstrap](plugins/team-harness/skills/cloud-hooks-bootstrap/SKILL.md) skill provides reusable scripts for:

- Verifying executable Husky shims in the current checkout.
- Attempting repair when shims are missing.
- Warning when hooks remain unavailable.
- Connecting Cursor Cloud's Git hook dispatcher to repository-local hooks.

Local pre-commit checks and CI remain the responsibility of each consuming repository. Installing the plugin alone does not enforce them.

Agent Plugins discovery exposes all three skills under `skills/`. That does **not** make bootstrap or Cloud-hooks skills cross-client portable. See [plugins/team-harness/docs/layers.md](plugins/team-harness/docs/layers.md).

## Install

Not a listing on the public Cursor Marketplace.

Customize (sidebar) → **Plugins** → **+ Add** → **From GitHub Repository** → paste `https://github.com/multipliers-dev/cursor-team-marketplace`.

## Engineering invariants

Installing `team-harness` does **not** install Cursor rules. Rules are a separate surface from the plugin.

Customize (sidebar) → **Rules** → **User** → **+ New** → paste [docs/engineering-invariants.md](docs/engineering-invariants.md).

## Plan validator

[![npm version](https://img.shields.io/npm/v/@multipliers-dev/plan-validator)](https://www.npmjs.com/package/@multipliers-dev/plan-validator)

Published on [npm](https://www.npmjs.com/package/@multipliers-dev/plan-validator) as **`@multipliers-dev/plan-validator`**: a deterministic structural validator for staged Cursor plan files under `.cursor/plans/` (frontmatter, slice todos, agent prompts, and related rules). Installing the team-harness plugin does **not** install this CLI — pin it in consumer repos for agents, local checks, or CI.

```bash
npm install -D @multipliers-dev/plan-validator
```

Consumption patterns (exact version pins, reusable GitHub Actions workflow): [plugins/team-harness/docs/centralized-consumption.md](plugins/team-harness/docs/centralized-consumption.md). Package wrapper and build: [packages/plan-validator/](packages/plan-validator/).

## Documentation

- [Plugin skills and scripts](plugins/team-harness/README.md) — capabilities and implementation reference
- [Skill portability layers](plugins/team-harness/docs/layers.md) — portable vs Cursor-dependent components
- [Versioning](plugins/team-harness/docs/versioning.md) — version alignment

## License

MIT — see [LICENSE](LICENSE).
