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

Use a **fresh Agent-mode chat** per slice.

> **Same-repo template behavior.** The slice prompts below assume the plan file and the implementation land in the **same repo**, so each marks its own todo `completed` in the same PR. For a **cross-repo slice** (authoritative plan lives in a different repo than the implementation), do **not** edit the plan from the implementation repo — use the cross-repo variant below instead.

- **Slice 1 — slice-1** (same-repo)
  - "Implement slice 1 (slice-1) from `@.cursor/plans/<slug>.plan.md` only. Start from latest `origin/main`, verify the branch represents only this slice before opening, verify GitHub PR base is `main`. **Agent instruction:** Do not merge. Stop after opening the PR. Mark `slice-1` completed in plan frontmatter. Do not start later slices. Do not archive the plan."
- **Slice 2 — slice-2** (same-repo)
  - "Implement slice 2 (slice-2) from `@.cursor/plans/<slug>.plan.md` only. Prerequisite: slice 1 merged. Start from latest `origin/main`, verify the branch represents only this slice before opening, verify GitHub PR base is `main`. **Agent instruction:** Do not merge. Stop after opening the PR. Mark `slice-2` completed in plan frontmatter. Do not start plan-closure. Do not archive the plan."
- **Cross-repo slice — implementation PR** (variant; use when the plan lives in a different repo)
  - "Implement slice `<slice-id>` from `@<plan-repo>/.cursor/plans/<slug>.plan.md` only, in `<implementation-repo>`. Start from that repo’s latest `origin/main`, verify the branch represents only this slice before opening, verify GitHub PR base is `main`. **Agent instruction:** Do not merge. Stop after opening the PR. **Do not edit the plan file** — it lives in `<plan-repo>`. Do not mark the todo completed here. Do not start other slices."
- **Cross-repo slice — plan-status PR** (variant; records completion in the plan-owning repo)
  - "Open the plan-status PR for slice `<slice-id>` from `@.cursor/plans/<slug>.plan.md` only, in `<plan-repo>`. Prerequisite: the implementation PR(s) in `<implementation-repo>` are open/merged and satisfy the slice’s completion condition (link them). Start from latest `origin/main`, verify slice-only branch, verify GitHub PR base is `main`. Mark `<slice-id>` completed in plan frontmatter (plan-status only). **Agent instruction:** Do not merge. Stop after opening the PR. Do not start other slices. Do not archive the plan."
- **Plan closure — plan-closure**
  - "Execute plan-closure from `@.cursor/plans/<slug>.plan.md` only. Prerequisites: implementation PRs actually **merged** to each target repo’s `main` (not merely frontmatter `completed`), including any cross-repo implementation PRs and their plan-status PR. Start from latest `origin/main`, verify slice-only branch, open PR targeting `main`, verify base is `main`. Docs-only: verify merges, add `# Shipped`, archive plan, mark `plan-closure` completed. **Agent instruction:** Do not merge. Stop after opening the PR."
