# Planning methodology — reference

Extended detail for `/planning-methodology`. Prefer the skill body for day-to-day use.

## Handoff model

plan recommends authority → human accepts by pasting the slice prompt → agent follows → branch protection enforces.

**Baseline capabilities** (when executing a plan): create branches, commit, push, open ready-for-review PRs. For Plan-only PR, commit means the plan artifact only.

## Plan-only PR

**Allowed:** inspect context, create/update `.cursor/plans/*.plan.md`, align with this methodology, commit plan artifact, open plan-only PR.

**Not allowed:** implement product code/tests/workflows; continue past opening the PR; merge.

**Expected diff:** plan artifact only.

## Manual verification gate

**Allowed:** run only the named verification; write only allowed gitignored paths; report verdict.

**Not allowed:** commit, open PR, edit tracked files, implement while verifying, continue past the verdict.

## Guidance for plan authors

- Default implementation slices to **Open PR only**
- Use **Plan-only PR** when the plan should land for review before code
- Use **Merge granted** only with rationale + preconditions + verification (config/docs/low-risk)
- Use **Manual verification gate** for evidence-only slices before closure
- Recommend authority **per slice**; topology default is branch-from and PR-target `main`

## Example prompts

Same-repo slice (plan file and code in the same repo → mark the todo in the same PR):

```markdown
## Agent prompts (copy/paste for Cursor)

- **Slice 1 — slice-1**
  - "Implement slice 1 (slice-1) from `@.cursor/plans/<slug>.plan.md` only. Start from latest `origin/main`, verify the branch represents only this slice before opening, verify GitHub PR base is `main`. **Agent instruction:** Do not merge. Stop after opening the PR. Mark `slice-1` completed in plan frontmatter. Do not start later slices."
```

Cross-repo slice (authoritative plan lives elsewhere → do not edit the plan from the implementation repo; record completion via a plan-status PR in the plan-owning repo):

```markdown
- **Cross-repo slice `<slice-id>` — implementation PR**
  - "Implement `<slice-id>` from `@<plan-repo>/.cursor/plans/<slug>.plan.md` only, in `<implementation-repo>`. **Agent instruction:** Do not merge. Stop after opening the PR. Do not edit the plan file (it lives in `<plan-repo>`). Do not mark the todo completed here."
- **Cross-repo slice `<slice-id>` — plan-status PR**
  - "Open the plan-status PR for `<slice-id>` in `<plan-repo>`. Prerequisite: implementation PR(s) satisfy the completion condition (link them). Mark `<slice-id>` completed in frontmatter (plan-status only). **Agent instruction:** Do not merge. Stop after opening the PR."
```

Closure verifies the implementation PRs are actually **merged** (all repos), not just that frontmatter says `completed`.

## What does not belong here

Product-specific checklists stay in-repo (examples): ephemeral client-state matrices, API deployment-compatibility matrices, board/card mobile verification, resumes application-research stage, portfolio route/domain examples, product skill verification runbooks.
