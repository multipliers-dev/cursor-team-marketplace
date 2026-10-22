---
name: Wrong closure order
overview: Multi-slice plan without plan-closure as last todo.
todos:
  - id: plan-closure
    content: "closure first"
    status: pending
  - id: slice-a
    content: "PR: slice after closure"
    status: pending
isProject: false
---

# Wrong todo order

## Recommended execution authority

| Slice | Recommended authority | Agent instruction |
| --- | --- | --- |
| plan-closure | Open PR only | Do not merge. |
| slice-a | Open PR only | Do not merge. |

Repo default: **Open PR only**

## Plan closure (docs-only PR)

**Recommended authority:** Open PR only

**Rationale:**

- c

**Agent instruction:** Stop

## Slice — slice-a

**Recommended authority:** Open PR only

**Rationale:**

- r

**Agent instruction:** Stop

**Acceptance:**

- ships

## Agent prompts (copy/paste for Cursor)

### plan-closure

```text
Authority: Open PR only — x
Topology: x
Deliverables: x
Verification: x
```

### slice-a

```text
Authority: Open PR only — x
Topology: x
Deliverables: x
Verification: x
```
