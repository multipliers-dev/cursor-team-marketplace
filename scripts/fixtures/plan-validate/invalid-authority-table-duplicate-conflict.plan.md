---
name: Duplicate conflicting table rows
overview: Two authority table rows for slice-a with different recognized labels.
todos:
  - id: slice-a
    content: "PR: slice a"
    status: pending
  - id: plan-closure
    content: "closure"
    status: pending
isProject: false
---

# Duplicate conflicting table rows

## Recommended execution authority

| Slice | Recommended authority | Agent instruction |
| --- | --- | --- |
| slice-a | Merge granted | May merge when verified. |
| slice-a | Manual verification gate | Human must verify before merge. |
| plan-closure | Open PR only | Do not merge. Stop after opening the PR. |

Repo default: **Open PR only** (see team skill `/planning-methodology`).

## Slice — slice-a

**Recommended authority:** Open PR only

**Rationale:**

- r

**Agent instruction:** Do not merge. Stop after opening the PR.

**Acceptance:**

- ships

## Plan closure (docs-only PR)

**Recommended authority:** Open PR only

**Rationale:**

- c

**Agent instruction:** Do not merge. Stop after opening the PR.

## Agent prompts (copy/paste for Cursor)

### slice-a

```text
Authority: Open PR only — x
Topology: x
Deliverables: x
Verification: x
```

### plan-closure

```text
Authority: Open PR only — x
Topology: x
Deliverables: x
Verification: x
```
