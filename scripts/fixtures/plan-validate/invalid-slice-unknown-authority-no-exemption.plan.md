---
name: Unknown slice authority no exemption
overview: Unrecognized slice authority still requires Acceptance (no Plan-only exemption).
todos:
  - id: slice-a
    content: "PR: slice a"
    status: pending
  - id: plan-closure
    content: "closure"
    status: pending
isProject: false
---

# Unknown slice authority

## Recommended execution authority

| Slice | Recommended authority | Agent instruction |
| --- | --- | --- |
| slice-a | Open PR only | Do not merge. Stop after opening the PR. |
| plan-closure | Open PR only | Do not merge. Stop after opening the PR. |

Repo default: **Open PR only** (see team skill `/planning-methodology`).

## Slice — slice-a

**Recommended authority:** Not a real authority

**Rationale:**

- r

**Agent instruction:** Do not merge. Stop after opening the PR.

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
