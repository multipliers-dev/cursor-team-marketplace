---
name: new-repo-bootstrap
description: >-
  5-minute checklist for a new GitHub repo: what Team Rules, marketplace
  skills, and Team MCP already provide vs what to add in-repo (thin AGENTS.md,
  domain rules, Husky Cloud wiring, Cloud env, manual Bugbot). Use when
  creating a new repository, bootstrapping a greenfield project, or deciding
  whether to copy harness from another product repo.
---

# New-repo bootstrap (5 minutes)

Do **not** copy product harness from `codenames-ai-guesser`, `resumes`, or `portfolio`. The team layer already follows Agent chats. Add only what this product needs.

## Already inherited (no file copy)

| Layer | What you get | Caveat |
| --- | --- | --- |
| **Team Rules** | Short always-on invariants (authority, topology, stop-after-open, do-not-defer, tools/comms) | Enforced in every Agent chat |
| **Planning methodology** | `/planning-methodology` — full staged-plan procedure | User Marketplace today; Team Default On is a known Cursor product blocker — not a packaging failure |
| **Team MCP** | PostHog, Notion, Vercel after you authenticate once | GitHub MCP stays local PAT-backed readonly; `gh` handles writes; GitHub App covers Cloud/Bugbot |
| **Cloud-hooks scripts** | Canonical installer/bridge + `/cloud-hooks-bootstrap` | **Not** automatic Cloud-safety — Husky repos still need one-time `prepare` / wiring |

User Rules / `~/.cursor` follow this machine only. They are weaker for Cloud Agents and new machines.

## Still add (in-repo, only what applies)

1. **GitHub App** — grant the new repo access if the App is not “All repositories”.
2. **Thin `AGENTS.md`** — package scripts, layout, Node version, non-obvious notes. Not a second copy of Team Rules or planning methodology.
3. **Domain rules / planning supplements** — only if this domain is special (API contracts, facts-vs-prose, route checklists). Do not promote product checklists to the team layer.
4. **Husky** — if the repo uses Husky, one-time wire Cloud-aware `prepare` + ensure-hooks via `/cloud-hooks-bootstrap`. Default On / plugin install alone is not enough.
5. **Cloud Agent env** — add `.cursor/environment.json` the first time you use Cloud Agents on this repo, after a successful Build.
6. **Bugbot** — keep **manual invoke only**. Do not enable automatic runs on every PR. Add `.cursor/BUGBOT.md` only if this repo needs an on-demand review guide.
7. **Optional** Prettier `afterFileEdit` — independent of Husky; only if you want Agent-edit auto-format.

`ai-learning` is the planning-portability proof (unharnessed). Do not add a full product harness there just to “match” other repos.

## Explicit non-goals

- Do not cargo-cult product skills, `.agents/`, renovate/analytics workflows, or domain merge-safe extras
- Do not paste full planning methodology into Team Rules or a new in-repo rule
- Do not enable automatic Bugbot on PRs
- Do not treat marketplace Cloud-hooks as zero-wiring Cloud-safety
- Do not invent marketplace skills that are not already proven across repos

## Agent behavior

When asked to bootstrap a new repo: walk this checklist, add only the in-repo items that apply, invoke `/cloud-hooks-bootstrap` for Husky repos, keep Bugbot manual, open **Open PR only** changes targeting `main`, and state clearly what was inherited vs added in-repo.
