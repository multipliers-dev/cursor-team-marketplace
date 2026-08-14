---
name: cloud-hooks-bootstrap
description: >-
  One-time Cloud-aware Husky wiring using the team-harness portable scripts
  (prepare-git-hooks, ensure-hooks bridge, sessionStart rechain). Use when
  porting Cloud git-hook safety into a repo, fixing CI=true skipping Husky on
  Cursor Cloud, or when Default On alone is not enough for Cloud commits.
---

# Cloud-hooks bootstrap (portable primitive)

**Default On ≠ zero-wiring Cloud-safety.** Installing this plugin distributes the canonical scripts and this recipe. Repositories that use Husky still need a **one-time local wiring** step.

Proven source: `codenames-ai-guesser` Cloud husky bridge (`prepare-git-hooks.sh`, `ensure-hooks.sh`, sessionStart rechain).

## When to use

- A Husky repo silently skips hooks on Cursor Cloud because `CI=true`
- Porting Cloud-safe prepare/ensure from this plugin into `resumes`, `portfolio`, or a new repo
- Explaining why marketplace Default On did not fix Cloud commits by itself

## What the plugin ships

Relative to the `team-harness` plugin root:

| Path                                  | Role                                                                                                                        |
| ------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `scripts/prepare-git-hooks.sh`        | Cloud-aware prepare: run Husky on Cursor Cloud even when `CI=true`; skip Vercel / GitHub Actions / non-Cloud CI             |
| `scripts/ensure-hooks.sh`             | Point Cloud `agent-hooks` dispatcher at `~/.cursor/husky-bridge`, which resolves the current repo’s `.husky/*` at hook time |
| `scripts/session-ensure-git-hooks.sh` | `sessionStart` rechain when `agent-hooks` appears after late `npm prepare`                                                  |

## One-time wiring checklist (per Husky repo)

1. Copy (or vendor) the three scripts into the repo — typical layout:
   - `scripts/prepare-git-hooks.sh`
   - `scripts/ensure-hooks.sh`
   - `.cursor/hooks/ensure-git-hooks.sh` ← from `session-ensure-git-hooks.sh`
2. Point `package.json` `"prepare"` at the Cloud-aware prepare script (replace naive `husky` / `if CI skip` helpers).
3. Ensure `.cursor/hooks.json` includes a `sessionStart` entry that runs `.cursor/hooks/ensure-git-hooks.sh` (fail-open).
4. Keep **per-repo** `.husky/pre-commit` (and friends) contents — lint-staged recipes differ; the plugin does not replace them.
5. Optional Prettier `afterFileEdit` stays product/repo-specific — not required by this primitive.
6. Verify on Cloud: a commit triggers the bridge (`[ensure-hooks]` messages) and runs the repo’s Husky hooks.

## Explicit non-goals

- Do not claim a brand-new Husky repo is Cloud-safe after Default On alone
- Do not overwrite product-specific hook contents from this skill
- Do not add Team Rules here (separate Part B)

## Agent behavior

When asked to wire Cloud hooks into a repo: copy from this plugin’s `scripts/`, update `prepare` + `sessionStart`, open an Open-PR-only change for that repo, and state clearly that Default On was not sufficient by itself.
