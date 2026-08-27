---
name: new-repo-bootstrap
description: >-
  5-minute checklist for a new GitHub repo: what User Rules, marketplace
  skills, and inherited MCP connectors already provide vs what to add in-repo (thin AGENTS.md,
  optional GitHub PR template, domain rules, Husky Cloud wiring, Cloud env,
  manual Bugbot). Use when creating a new repository, bootstrapping a
  greenfield project, or deciding whether to copy harness from another
  product repo.
---

# New-repo bootstrap (5 minutes)

Do **not** copy a full product harness from another app repo. User Rules and the plugin skills already follow Agent chats. Add only what this product needs.

## Already inherited (no file copy)

| Layer | What you get | Caveat |
| --- | --- | --- |
| **User Rules** | Short always-on invariants from `docs/engineering-invariants.md` (authority, topology, stop-after-open, do-not-defer, tools/comms) | Paste via Customize → Rules → User; not org-enforced |
| **Planning methodology** | `/planning-methodology` — full staged-plan procedure | Available via marketplace install when the plugin is installed |
| **Inherited MCP connectors** | MCP servers already on this Cursor account (when configured) | Do not duplicate in-repo MCP configs for connectors you already have — authenticate them instead; prefer `gh` for GitHub writes; do not invent a second GitHub integration; GitHub App covers Cloud/Bugbot |
| **Cloud-hooks scripts** | Canonical Husky bridge + Cloud Node scripts + `/cloud-hooks-bootstrap` | **Not** automatic Cloud-safety — Husky repos still need one-time `prepare` / wiring; Cloud Agents also need committed `environment.json` lifecycle |

User Rules are account-scoped (Customize → Rules → User). They follow Agent chats on this account but are weaker for Cloud Agents and new machines unless you replicate the same paste.

## Still add (in-repo, only what applies)

1. **GitHub App** — grant the new repo access if the App is not “All repositories”.
2. **Thin `AGENTS.md`** — package scripts, layout, Node version, non-obvious notes. Not a second copy of User Rules or planning methodology.
3. **Optional thin GitHub PR template** — `.github/pull_request_template.md` when the repo will open GitHub PRs and does not already have a template. Human / GitHub New-PR skeleton only (Summary, execution-authority checkboxes, test plan, rollback). Not a second copy of User Rules or `/planning-methodology`. Domain sections stay in-repo. See [Thin GitHub PR template](#thin-github-pr-template).
4. **Domain rules / planning supplements** — only if this domain is special (API contracts, facts-vs-prose, route checklists). Do not promote product checklists into `docs/engineering-invariants.md` or User Rules.
5. **Husky** — if the repo uses Husky, one-time wire Cloud-aware `prepare` + ensure-hooks via `/cloud-hooks-bootstrap`. Marketplace / plugin install alone is not enough.
6. **Cloud Agent env** — if Cloud Agents are expected, establish `.cursor/environment.json` (and Node-from-`.nvmrc` wrappers when `.nvmrc` pins a newer major than the Cloud base image) **during bootstrap**, alongside `/cloud-hooks-bootstrap` Husky wiring — not deferred to first Cloud use. See `/cloud-hooks-bootstrap` for the recipe. If only `package.json` `engines.node` suggests a newer major, decide whether to add a `.nvmrc` pin first. Skip only when Cloud Agents are **not** expected (same spirit as an intentional no-harness / planning-only proof repo).
7. **Bugbot** — keep **manual invoke only**. Do not enable automatic runs on every PR. Add `.cursor/BUGBOT.md` only if this repo needs an on-demand review guide.
8. **Optional** Prettier `afterFileEdit` — independent of Husky; only if you want Agent-edit auto-format.

Intentional no-harness / planning-only proof repos stay unharnessed. Do not add a full product harness there just to “match” other repos — including a PR template.

## Thin GitHub PR template

**Ownership (do not collapse these layers):**

| Layer | Role |
| --- | --- |
| User Rules | Always-on agent invariants (`docs/engineering-invariants.md` paste) |
| `/planning-methodology` | Canonical agent procedure (what to call out when opening from a plan) |
| `.github/pull_request_template.md` | Human / GitHub UI skeleton |
| Repo-local additions | Domain-specific sections (visual regression, facts/generation, product verification) |

Skip when: the repo already has a template; or the repo is an intentional no-harness / planning-only proof. Do **not** copy a full product PR template from another app repo. Do **not** create an org-level `.github` repository.

Write this skeleton, then add domain sections in the same file only if this product needs them:

```markdown
<!--
To generate this PR description with Cursor:

"Prepare the PR description in raw markdown using `.github/pull_request_template.md`.
Base it on the current git diff, relevant docs, and test results.
Return it inside a single ```md fenced block."
-->

## Summary

<!-- What changed and why. Link related docs or plan sections. Note scope boundaries: what this PR includes and explicitly does not include. -->

-

## Execution authority

<!-- Pick one. Repo default when unspecified: Open PR only. -->

- [ ] **Plan-only PR** — planning artifact only; implementation not started.
- [ ] **Open PR only** — implementation in this PR; do not merge.
- [ ] **Merge granted** — explicit with rationale from the committed plan slice **or** the user’s instruction for this unplanned task; branch protection remains final gate.

Agents must not merge unless **Merge granted** is explicitly selected with rationale. Branch protection and human review remain the final enforcement boundary.

## Test plan

<!-- Check off what you ran. Docs-only: mark N/A where applicable. -->

-

## Rollback criteria

<!-- Concrete symptoms that mean this PR should be reverted. -->

Revert if:
```

## Explicit non-goals

- Do not cargo-cult product skills, `.agents/`, renovate/analytics workflows, or domain merge-safe extras
- Do not paste full planning methodology into User Rules or a new in-repo rule
- Do not enable automatic Bugbot on PRs
- Do not treat marketplace Cloud-hooks as zero-wiring Cloud-safety
- Do not invent marketplace skills that are not already proven across repos
- Do not create an org-level `.github` repo or an org-wide GitHub PR convention system
- Do not paste `/planning-methodology` procedure into the GitHub PR template

## Agent behavior

When asked to bootstrap a new repo: walk this checklist, add only the in-repo items that apply, offer the thin GitHub PR template when the repo will use GitHub PRs and lacks one, invoke `/cloud-hooks-bootstrap` for Husky repos (including `environment.json` when Cloud Agents are expected), keep Bugbot manual, leave intentional no-harness / planning-only proof repos unharnessed, open **Open PR only** changes targeting `main`, and state clearly what was inherited vs added in-repo.

For **timed technical interviews** dropped into an empty directory, use `/interview-repo-bootstrap` instead — it is a one-shot minimal preset and must not chain into this checklist or `/cloud-hooks-bootstrap`.
