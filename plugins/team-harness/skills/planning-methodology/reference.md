# Planning methodology — reference

Extended detail for `/planning-methodology`. Prefer the skill body for day-to-day use.

## Handoff model

plan recommends authority → human accepts by pasting the slice prompt → agent follows → branch protection enforces.

**Baseline capabilities** (when executing a plan): create branches, commit, push, open ready-for-review PRs. For Plan-only PR, commit means the plan artifact only.

## Plan-only PR

**Allowed:** inspect context, create/update `.cursor/plans/*.plan.md`, align with this methodology, commit plan artifact, open plan-only PR.

**Not allowed:** implement product code/tests/workflows; continue past opening the PR; merge.

**Expected diff:** plan artifact only.

**Conversion verification:** source diagrams and implementation-critical structure preserved (not prose-only summaries). See Native plan conversion in the skill.

## Manual verification gate

**Allowed:** run only the named verification; write only allowed gitignored paths; report verdict.

**Not allowed:** commit, open PR, edit tracked files, implement while verifying, continue past the verdict.

## Guidance for plan authors

- Default implementation slices to **Open PR only**
- Use **Plan-only PR** when the plan should land for review before code
- Use **Merge granted** only with rationale + preconditions + verification (config/docs/low-risk)
- Use **Manual verification gate** for evidence-only slices before closure
- Recommend authority **per slice**; topology default is branch-from and PR-target `main`
- When converting a native Cursor plan, wrap-and-slice: add the envelope, preserve mermaid/diagrams and implementation-critical tables/checklists in the executing slice or a Design/Context section — do not compress them into prose
- Multi-repo slices: list **Required repositories** (owner/name + role) in the slice body; add `Repositories:` to the agent prompt; hard-stop if any checkout is missing or identity-mismatched — do not reconstruct from plan/docs/target repo

### Anti-pattern: diagram → prose

Replacing a mermaid flowchart (e.g. a four-layer capability model) with a one-line summary like "four capability layers (day-job vs interview-format vs …)" loses structure agents need at execution time. A summary may accompany a diagram; it must not replace it.

### Anti-pattern: missing source checkout → reconstruct

When a multi-repo slice lists a source repository as read-only authority, launching against only the target repo and reconstructing behavior from the plan, documentation, or target-repo guesses violates the environment preflight. Stop and use a multi-repo Cloud Agent environment with every **Required repositories** checkout present.

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

Verification: PR contains only this slice’s implementation; plan file was not edited.
```

```text
@.cursor/plans/<slug>.plan.md

Open the plan-status PR for slice <slice-id> only, in <plan-repo>. Prerequisite: implementation PR(s) satisfy the completion condition (link them). Do not start other slices. Do not archive the plan.

Authority: Open PR only — implement and open the PR; do not merge.

Topology: start from latest origin/main; branch represents only this slice; PR base must be main.

Deliverables: mark <slice-id> completed in plan frontmatter (plan-status only).

Verification: frontmatter marks <slice-id> completed and links the implementation PR(s).
```
````

Multi-repo extraction slice (source read-only, target read/write — five labeled prompt lines):

````markdown
```text
@<plan-repo>/.cursor/plans/<slug>.plan.md

Implement slice <slice-id> only, in <target-repo>. Do not start other slices.

Authority: Open PR only — implement and open the PR; do not merge.

Topology: start from that repo’s latest origin/main; branch represents only this slice; PR base must be main.

Repositories: multipliers-dev/source-repo (behavioral/source authority, read-only), multipliers-dev/target-repo (implementation target, read/write); verify all are present/readable before implementation; hard-stop if not.

Deliverables: extract/generalize from source into target. If the plan lives in <target-repo>, mark <slice-id> completed in plan frontmatter in this PR; otherwise do not edit the plan file — it lives in <plan-repo> — and do not mark the todo completed here (record via plan-status PR in <plan-repo>).

Verification: preflight proved both checkouts; implementation copied from source paths, not reconstructed from plan/docs; completion recording matches item 5 (same-repo mark in this PR, or cross-repo plan untouched).
```
````

Closure verifies the implementation PRs are actually **merged** (all repos), not just that frontmatter says `completed`.

## What does not belong here

Product-specific checklists stay in-repo (examples): ephemeral client-state matrices, API deployment-compatibility matrices, board/card mobile verification, route/domain examples, product skill verification runbooks.
