---
name: Bad status
overview: Unrecognized todo status value.
todos:
  - id: slice-a
    content: "PR: bad status"
    status: done
  - id: plan-closure
    content: "closure"
    status: pending
isProject: false
---

# Bad status

## Recommended execution authority

| Slice | Recommended authority | Agent instruction |
| --- | --- | --- |
| slice-a | Open PR only | Do not merge. |
| plan-closure | Open PR only | Do not merge. |

Repo default: **Open PR only**

## Slice — slice-a

**Recommended authority:** Open PR only

**Rationale:**

- r

**Agent instruction:** Stop

**Acceptance:**

- a

## Plan closure (docs-only PR)

**Recommended authority:** Open PR only

**Rationale:**

- c

**Agent instruction:** Stop

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
