---
name: Plan title
overview: One-line summary of the multi-PR plan.
todos:
  - id: slice-1
    content: "PR 1: First merge-safe slice"
    status: pending
  - id: slice-2
    content: "PR 2: Second merge-safe slice"
    status: pending
  - id: plan-closure
    content: "Docs-only PR after last slice: add # Shipped note, move plan to .cursor/plans/archive/YYYY-MM-DD-slug.plan.md"
    status: pending
isProject: false
---

# Plan title

> **Boilerplate only.** Copy to `.cursor/plans/<slug>.plan.md` and fill real slices. Do **not** execute this template as an active plan.

## Recommended execution authority

| Slice        | Recommended authority | Agent instruction                        |
| ------------ | --------------------- | ---------------------------------------- |
| slice-1      | Open PR only          | Do not merge. Stop after opening the PR. |
| slice-2      | Open PR only          | Do not merge. Stop after opening the PR. |
| plan-closure | Open PR only          | Do not merge. Stop after opening the PR. |

Repo default: **Open PR only** (see team skill `/planning-methodology`).

Use for **cross-cutting / multi-concern** work. Small isolated fixes can be direct PRs — see Lightweight vs staged in the skill.

## Repository topology (default)

Multi-slice plans stack execution order, not Git branches. Integration branch is `main` unless a slice explicitly authorizes otherwise.

**Before implementation:** start from latest `origin/main`.

**Before opening the PR:** branch represents only this slice — prior-slice work is on the integration branch, not via branch ancestry.

**After opening the PR:** GitHub PR base is `main`; diff excludes prior-slice work except through merged `main`.

---

## Slice 1 — First merge-safe slice

**Recommended authority:** Open PR only

**Rationale:**

- …

**Agent instruction:** Do not merge. Stop after opening the PR.

**Goal:** …

**Acceptance:** …

---

## Slice 2 — Second merge-safe slice

**Recommended authority:** Open PR only

**Rationale:**

- …

**Agent instruction:** Do not merge. Stop after opening the PR.

**Goal:** …

**Acceptance:** …

---

## Plan closure (docs-only PR)

**Recommended authority:** Open PR only

**Rationale:**

- Docs-only archival; human review of closure checklist

**Agent instruction:** Do not merge. Stop after opening the PR.

After the last implementation slice merges:

1. Verify implementation todos are `completed` or `cancelled`
2. Verify Manual verification gate verdicts when applicable
3. Add `# Shipped` with date, PR links, deferred work
4. Move to `.cursor/plans/archive/YYYY-MM-DD-slug.plan.md`
5. Mark `plan-closure` completed; update references

---

## Agent prompts (copy/paste for Cursor)

Use a **fresh Agent-mode chat** per slice. Each default frontmatter todo has exactly one `### <todo-id>` heading copied from that todo’s `id` — do not rename ids to match prose.

> **Same-repo template behavior.** The slice prompts below assume the plan file and the implementation land in the **same repo**, so each marks its own todo `completed` in the same PR. For a **cross-repo slice** (authoritative plan lives in a different repo than the implementation), do **not** edit the plan from the implementation repo — use the cross-repo variant below instead.

### slice-1

```text
@.cursor/plans/<slug>.plan.md

Implement slice slice-1 only. Do not start slice-2 or later slices. Do not archive the plan.

Authority: Open PR only — implement and open the PR; do not merge.

Topology: start from latest origin/main; branch represents only this slice; PR base must be main.

Deliverables: …. Mark slice-1 completed in plan frontmatter in this PR.

Verification: ….
```

### slice-2

```text
@.cursor/plans/<slug>.plan.md

Implement slice slice-2 only. Prerequisite: slice-1 merged. Do not start plan-closure. Do not archive the plan.

Authority: Open PR only — implement and open the PR; do not merge.

Topology: start from latest origin/main; branch represents only this slice; PR base must be main.

Deliverables: …. Mark slice-2 completed in plan frontmatter in this PR.

Verification: ….
```

### plan-closure

```text
@.cursor/plans/<slug>.plan.md

Execute only plan-closure.

Authority: Open PR only — docs-only archive PR; do not merge.

Prerequisites: implementation PRs actually merged to each target repo’s main (not merely frontmatter completed), including any cross-repo implementation PRs and their plan-status PR.

Topology: start from latest origin/main; branch represents only this slice; PR base must be main.

Deliverables: verify slice todos, add # Shipped note, move plan to .cursor/plans/archive/YYYY-MM-DD-slug.plan.md, mark plan-closure completed, update agent prompt references to the archived path.

Verification: confirm all prerequisite implementation PRs are merged and slice todos are completed before archiving.
```

#### Cross-repo variants

When the authoritative plan lives in a different repo than the implementation, use one of these **instead of** the same-repo prompt. Do not add a second `###` heading matching a default todo id.

Implementation PR (in `<implementation-repo>`; do not edit the plan):

```text
@<plan-repo>/.cursor/plans/<slug>.plan.md

Implement slice <slice-id> only, in <implementation-repo>. Do not start other slices.

Authority: Open PR only — implement and open the PR; do not merge.

Topology: start from that repo’s latest origin/main; branch represents only this slice; PR base must be main.

Deliverables: implementation only. Do not edit the plan file — it lives in <plan-repo>. Do not mark the todo completed here.

Verification: PR contains only this slice’s implementation; plan file was not edited.
```

Plan-status PR (in `<plan-repo>`):

```text
@.cursor/plans/<slug>.plan.md

Open the plan-status PR for slice <slice-id> only, in <plan-repo>. Prerequisite: the implementation PR(s) in <implementation-repo> are open/merged and satisfy the slice’s completion condition (link them). Do not start other slices. Do not archive the plan.

Authority: Open PR only — implement and open the PR; do not merge.

Topology: start from latest origin/main; branch represents only this slice; PR base must be main.

Deliverables: mark <slice-id> completed in plan frontmatter (plan-status only).

Verification: frontmatter marks <slice-id> completed and links the implementation PR(s).
```
