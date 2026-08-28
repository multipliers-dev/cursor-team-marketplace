---
name: repo-bootstrap
description: >-
  Bootstrap an actually-empty directory into a pre-wired repo (TypeScript + tsx
  run/dev + Vitest + minimal AGENTS.md + Husky pre-commit + minimal GitHub
  Actions CI + GitHub remote). Universal execution, verification, and
  enforcement only — no product decisions. Use when starting a greenfield repo
  from an empty folder.
---

# Repo bootstrap

Greenfield repos need a clean-slate GitHub repo with execution, verification, and enforcement pre-wired — not product scaffolding.

**Boundary:** this skill stops after the minimal preset. Do **not** chain into `/cloud-hooks-bootstrap` on success.

> `/repo-bootstrap` only operates on actually-empty directories. Existing repos are out of scope; use `/cloud-hooks-bootstrap` when the needed retrofit is hook/cloud wiring, otherwise plan the repo-specific changes explicitly.

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

**Scope test:** *Would I want this capability regardless of what problem I'm solving in this repo?*

| Yes (include) | No (exclude) |
| --- | --- |
| Vitest, typechecking, `npm start` / `npm run dev` (tsx), `AGENTS.md` | React, Savepoints, database |
| Cloud-hooks primitive (Husky trio + minimal `environment.json`) | PR templates, Bugbot, plans |
| Reliable pre-commit (`test` + `typecheck`) | ESLint, Prettier, lint-staged, deploy |
| Minimal `.cursor/environment.json` | Node-from-`.nvmrc` scripts, `afterFileEdit`, dev terminals/ports |

## When to use

- Dropped into an **actually empty** directory for a new repo
- Need `git init`, TypeScript tooling, agent instructions, hooks, CI, and a GitHub remote without product decisions

## What the plugin ships

| Path | Role |
| --- | --- |
| `templates/repo/` | Greenfield preset files only (`.gitignore`, `AGENTS.md`, `package.json`, Husky, CI, minimal Cloud lifecycle) |
| `scripts/repo-bootstrap.sh` | Copies preset + hook allowlist; runs hook smoke; creates GitHub remote |

**Hook primitive allowlist** (only these four from plugin `scripts/`):

| Plugin source | Repo destination |
| --- | --- |
| `scripts/prepare-git-hooks.sh` | `scripts/prepare-git-hooks.sh` |
| `scripts/verify-git-hooks.sh` | `scripts/verify-git-hooks.sh` |
| `scripts/ensure-hooks.sh` | `scripts/ensure-hooks.sh` |
| `scripts/session-ensure-git-hooks.sh` | `.cursor/hooks/ensure-git-hooks.sh` |

Do **not** copy `repo-bootstrap.sh`, `cloud-agent-install.sh`, `cloud-agent-start.sh`, or `cloud-agent-session-path.sh`.

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

**CLI:** `repo-bootstrap.sh [--name NAME] [--dir DIR] [--public] [--dry-run]`

- Default target: current directory (`$PWD`)
- Default visibility: **private**; `--public` opts in
- `--dry-run`: verify tooling; no writes; no `gh auth` required

## Empty-directory guard

The target directory must be **actually empty** before bootstrap writes anything.

- Any entry (including `.DS_Store`) → refuse and list paths
- No allowlist of "harmless" files
- Choose `--dir` elsewhere or remove files manually

## Hook smoke verification

Template `.husky/pre-commit` ends with:

```sh
echo "[repo-bootstrap] pre-commit verify"
```

Bootstrap aborts if `git commit` succeeds but commit output lacks that sentinel — the hook was bypassed or miswired.

## Explicit non-goals

- No `.nvmrc` / `engines`; no extra provenance in README beyond the title
- No `cloud-agent-*` scripts (Cloud VM Node is sufficient for the preset)
- No lint-staged, formatting, or build in hooks/CI
- No copying a full product harness from another app repo
- No cloning cursor-team-marketplace or any other repo to obtain plugin files
- No chaining into `/cloud-hooks-bootstrap`
- No operating on non-empty or existing repos

## Agent behavior

When asked to bootstrap a repo:

1. Confirm the target directory is **actually empty** (or use `--dir` to an empty path). If the directory is not empty or is an existing repo, **stop** — `/repo-bootstrap` does not apply; use `/cloud-hooks-bootstrap` for hook/cloud wiring only, or plan repo-specific changes explicitly.
2. Locate the installed **team-harness** plugin on disk (Customize → Plugins, or Cursor's local plugins directory). Run `scripts/repo-bootstrap.sh` from that plugin root. If the packaged script cannot be found, **stop** and tell the user the plugin is not installed — do not clone cursor-team-marketplace or any other repo to recover.
3. Use `--dry-run` first when validating tooling on a fresh VM.
4. **Stop** after bootstrap succeeds — do not invoke `/cloud-hooks-bootstrap`.

## Related skills

| Skill | When |
| --- | --- |
| `/cloud-hooks-bootstrap` | Hook/cloud wiring into an **existing** repo — not a generic migration path for non-empty directories |
| `/planning-methodology` | Staged plans and merge-safe PR procedure when bootstrap is part of a larger initiative |
