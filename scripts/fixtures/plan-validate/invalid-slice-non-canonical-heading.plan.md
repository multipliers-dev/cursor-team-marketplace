---
name: Non-canonical slice heading
overview: Same as missing slice — substring heading does not bind todo id.
todos:
  - id: slice-a
    content: "PR: slice a"
    status: pending
  - id: plan-closure
    content: "closure"
    status: pending
isProject: false
---

# Non-canonical slice heading

## Recommended execution authority

| Slice | Recommended authority | Agent instruction |
| --- | --- | --- |
| slice-a | Open PR only | Do not merge. Stop after opening the PR. |
| plan-closure | Open PR only | Do not merge. Stop after opening the PR. |

Repo default: **Open PR only** (see team skill `/planning-methodology`).

## Slice 1 — slice-a prose title

**Recommended authority:** Open PR only

**Rationale:**

- Template-style heading without canonical Slice — id form

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
