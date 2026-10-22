---
name: Valid minimal plan
overview: Smoke fixture that satisfies core validator rules.
todos:
  - id: slice-a
    content: "PR: first slice"
    status: pending
  - id: plan-closure
    content: "Docs-only closure"
    status: pending
isProject: false
---

# Valid minimal plan

## Recommended execution authority

| Slice | Recommended authority | Agent instruction |
| --- | --- | --- |
| slice-a | Open PR only | Do not merge. Stop after opening the PR. |
| plan-closure | Open PR only | Do not merge. Stop after opening the PR. |

Repo default: **Open PR only** (see team skill `/planning-methodology`).

## Repository topology (default)

Multi-slice plans stack execution order, not Git branches. Integration branch is `main`.

**Before implementation:** start from latest `origin/main`.

**Before opening the PR:** branch represents only this slice.

**After opening the PR:** GitHub PR base is `main`.

## Slice — slice-a

**Recommended authority:** Open PR only

**Rationale:**

- Minimal valid fixture

**Agent instruction:** Do not merge. Stop after opening the PR.

**Acceptance:**

- Ships feature A

## Plan closure (docs-only PR)

**Recommended authority:** Open PR only

**Rationale:**

- Docs-only archival

**Agent instruction:** Do not merge. Stop after opening the PR.

## Agent prompts (copy/paste for Cursor)

### slice-a

```text
@.cursor/plans/valid-minimal.plan.md

Implement slice slice-a only.

Authority: Open PR only — do not merge.

Topology: start from latest origin/main; PR base must be main.

Deliverables: ship feature A.

Verification: npm test.
```

### plan-closure

```text
@.cursor/plans/valid-minimal.plan.md

Execute only plan-closure.

Authority: Open PR only — do not merge.

Topology: start from latest origin/main; PR base must be main.

Deliverables: archive the plan.

Verification: confirm prerequisites merged.
```
