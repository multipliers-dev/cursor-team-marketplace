---
name: Valid single-slice plan
overview: One actionable todo; plan-closure not required.
todos:
  - id: only-slice
    content: "PR: only slice"
    status: pending
isProject: false
---

# Valid single-slice plan

## Recommended execution authority

| Slice | Recommended authority | Agent instruction |
| --- | --- | --- |
| only-slice | Open PR only | Do not merge. Stop after opening the PR. |

Repo default: **Open PR only** (see team skill `/planning-methodology`).

## Repository topology (default)

Multi-slice plans stack execution order, not Git branches. Integration branch is `main`.

**Before implementation:** start from latest `origin/main`.

**Before opening the PR:** branch represents only this slice.

**After opening the PR:** GitHub PR base is `main`.

## Slice — only-slice

**Recommended authority:** Open PR only

**Rationale:**

- Single-slice fixture

**Agent instruction:** Do not merge. Stop after opening the PR.

**Acceptance:**

- Ships the only slice

## Agent prompts (copy/paste for Cursor)

### only-slice

```text
@.cursor/plans/valid-single-slice.plan.md

Implement slice only-slice only.

Authority: Open PR only — do not merge.

Topology: start from latest origin/main; PR base must be main.

Deliverables: ship work.

Verification: npm test.
```
