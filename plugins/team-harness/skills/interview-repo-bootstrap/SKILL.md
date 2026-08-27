---
name: interview-repo-bootstrap
description: >-
  Bootstrap an actually-empty directory into a pre-wired technical interview
  repo (TypeScript + tsx run/dev + Vitest + minimal AGENTS.md + Husky pre-commit +
  minimal GitHub Actions CI + GitHub remote). Universal execution, verification, and
  enforcement only — no product decisions. Use when starting a timed technical
  interview from an empty folder.
---

# Interview repo bootstrap

Timed technical interviews need a clean-slate GitHub repo with execution, verification, and enforcement pre-wired — not product scaffolding.

**Boundary:** this skill stops after the minimal interview preset. Do **not** chain into `/new-repo-bootstrap` or `/cloud-hooks-bootstrap` on success.

## Five-layer model

```
AGENTS.md              instruct
      ↓
tsx (start/dev)        execute
      ↓
Vitest + TypeScript    verify
      ↓
pre-commit             enforce locally
      ↓
GitHub Actions         enforce remotely
      ↓
Git + GitHub           persist/share
```

**Scope test:** *Would I want this capability regardless of what technical problem the interviewer gives me?*

| Yes (include) | No (exclude) |
| --- | --- |
| Vitest, typechecking, `npm start` / `npm run dev` (tsx), `AGENTS.md` | React, Savepoints, database |
| Cloud-hooks primitive (Husky trio + minimal `environment.json`) | PR templates, Bugbot, plans |
| Reliable pre-commit (`test` + `typecheck`) | ESLint, Prettier, lint-staged, deploy |
| Minimal `.cursor/environment.json` | Node-from-`.nvmrc` scripts, `afterFileEdit`, dev terminals/ports |

## When to use

- Dropped into an **actually empty** directory for a timed technical interview
- Need `git init`, TypeScript tooling, agent instructions, hooks, CI, and a GitHub remote without product decisions

## What the plugin ships

| Path | Role |
| --- | --- |
| `templates/interview-repo/` | Interview preset files only (`.gitignore`, `AGENTS.md`, `package.json`, Husky, CI, minimal Cloud lifecycle) |
| `scripts/interview-repo-bootstrap.sh` | Copies preset + hook allowlist; runs hook smoke; creates GitHub remote |

**Hook primitive allowlist** (only these four from plugin `scripts/`):

| Plugin source | Interview repo destination |
| --- | --- |
| `scripts/prepare-git-hooks.sh` | `scripts/prepare-git-hooks.sh` |
| `scripts/verify-git-hooks.sh` | `scripts/verify-git-hooks.sh` |
| `scripts/ensure-hooks.sh` | `scripts/ensure-hooks.sh` |
| `scripts/session-ensure-git-hooks.sh` | `.cursor/hooks/ensure-git-hooks.sh` |

Do **not** copy `interview-repo-bootstrap.sh`, `cloud-agent-install.sh`, `cloud-agent-start.sh`, or `cloud-agent-session-path.sh`.

## Operational sequence

The bootstrap script performs:

```
guard empty directory          (any entry → refuse and list paths)
  → copy template preset + hook allowlist
  → substitute repo name in README / package.json / environment.json
  → git init -b main
  → npm install                  (prepare runs after git exists)
  → rewrite environment.json install to npm ci when lockfile exists
  → direct hook smoke            (sh .husky/pre-commit + sentinel)
  → git add .
  → git commit -m "Initial commit"   (inline user.name/email; assert sentinel in output)
  → gh repo create <name> --source=. --remote=origin --push (--private|--public)
```

**CLI:** `interview-repo-bootstrap.sh [--name NAME] [--dir DIR] [--public] [--dry-run]`

- Default target: current directory (`$PWD`)
- Default visibility: **private**; `--public` opts in
- `--dry-run`: verify tooling; no writes; no `gh auth` required

## Empty-directory guard

The target directory must be **actually empty** before bootstrap writes anything.

- Any entry (including `.DS_Store`) → refuse and list paths
- No allowlist of “harmless” files
- Choose `--dir` elsewhere or remove files manually

## Hook smoke verification

Template `.husky/pre-commit` ends with:

```sh
echo "[interview-bootstrap] pre-commit verify"
```

Bootstrap aborts if `git commit` succeeds but commit output lacks that sentinel — the hook was bypassed or miswired.

## Explicit non-goals

- No `.nvmrc` / `engines`; no interview provenance in README beyond the title
- No `cloud-agent-*` scripts (Cloud VM Node is sufficient for the interview preset)
- No lint-staged, formatting, or build in hooks/CI
- No copying full harness from codenames/resumes/portfolio
- No chaining into `/new-repo-bootstrap` or `/cloud-hooks-bootstrap`

## Agent behavior

When asked to bootstrap an interview repo:

1. Confirm the target directory is **actually empty** (or use `--dir` to an empty path).
2. Run `plugins/team-harness/scripts/interview-repo-bootstrap.sh` from the marketplace checkout (or installed plugin path).
3. Use `--dry-run` first when validating tooling on a fresh VM.
4. **Stop** after bootstrap succeeds — do not invoke `/new-repo-bootstrap` or `/cloud-hooks-bootstrap`.
5. For production/team harness on a non-interview repo, use `/new-repo-bootstrap` instead.

## Related skills

| Skill | When |
| --- | --- |
| `/new-repo-bootstrap` | Production greenfield repos — inherited team layer vs in-repo adds |
| `/cloud-hooks-bootstrap` | Manual Cloud Husky wiring into an **existing** repo (not the interview one-shot preset) |
