---
name: Prompt deliverables placeholder
overview: Deliverables line is ellipsis-only under default profile.
todos:
  - id: slice-a
    content: "PR: slice a"
    status: pending
  - id: plan-closure
    content: "closure"
    status: pending
isProject: false
---

# Prompt placeholder

## Recommended execution authority

| Slice | Recommended authority | Agent instruction |
| --- | --- | --- |
| slice-a | Open PR only | Do not merge. Stop after opening the PR. |
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
Deliverables: …
Verification: concrete checks
```

### plan-closure

```text
Authority: Open PR only — x
Topology: x
Deliverables: x
Verification: x
```
