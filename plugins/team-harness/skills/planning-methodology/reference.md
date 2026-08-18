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

Present each prompt as `### <todo-id>` plus a fenced `text` block. Frontmatter todo ids are authoritative; headings are copied from them. Every default todo has exactly one matching heading. Full skeleton: [_template.plan.md](_template.plan.md).

Same-repo slice (plan file and code in the same repo → mark the todo in the same PR):

````markdown
### slice-1

```text
@.cursor/plans/<slug>.plan.md

Implement slice slice-1 only. Do not start later slices. Do not archive the plan.

Authority: Open PR only — implement and open the PR; do not merge.

Topology: start from latest origin/main; branch represents only this slice; PR base must be main.

Deliverables: …. Mark slice-1 completed in plan frontmatter in this PR.

Verification: ….
```
````

Cross-repo slice (authoritative plan lives elsewhere → do not edit the plan from the implementation repo; record completion via a plan-status PR in the plan-owning repo). These are variants, not extra headings matching a default todo id:

````markdown
```text
@<plan-repo>/.cursor/plans/<slug>.plan.md

Implement slice <slice-id> only, in <implementation-repo>. Do not start other slices.

Authority: Open PR only — implement and open the PR; do not merge.

Topology: start from that repo’s latest origin/main; branch represents only this slice; PR base must be main.

Deliverables: implementation only. Do not edit the plan file — it lives in <plan-repo>. Do not mark the todo completed here.
```

```text
@.cursor/plans/<slug>.plan.md

Open the plan-status PR for slice <slice-id> only, in <plan-repo>. Prerequisite: implementation PR(s) satisfy the completion condition (link them). Do not start other slices. Do not archive the plan.

Authority: Open PR only — implement and open the PR; do not merge.

Topology: start from latest origin/main; branch represents only this slice; PR base must be main.

Deliverables: mark <slice-id> completed in plan frontmatter (plan-status only).
```
````

Closure verifies the implementation PRs are actually **merged** (all repos), not just that frontmatter says `completed`.

## What does not belong here

Product-specific checklists stay in-repo (examples): ephemeral client-state matrices, API deployment-compatibility matrices, board/card mobile verification, resumes application-research stage, portfolio route/domain examples, product skill verification runbooks.
