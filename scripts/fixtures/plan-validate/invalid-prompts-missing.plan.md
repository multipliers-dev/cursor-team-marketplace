---
name: Prompt gap
overview: Actionable todo without agent prompt heading.
todos:
  - id: slice-a
    content: "PR: missing prompt"
    status: pending
  - id: plan-closure
    content: "closure"
    status: pending
isProject: false
---

# Prompt gap

## Recommended execution authority

| Slice | Recommended authority | Agent instruction |
| --- | --- | --- |
| slice-a | Open PR only | Do not merge. Stop after opening the PR. |
| plan-closure | Open PR only | Do not merge. Stop after opening the PR. |

Repo default: **Open PR only** (see team skill `/planning-methodology`).

## Slice — slice-a

**Recommended authority:** Open PR only

**Rationale:**

- Missing prompt

**Agent instruction:** Do not merge. Stop after opening the PR.

**Acceptance:**

- Something ships

## Plan closure (docs-only PR)

**Recommended authority:** Open PR only

**Rationale:**

- Closure

**Agent instruction:** Do not merge. Stop after opening the PR.

## Agent prompts (copy/paste for Cursor)

### plan-closure

```text
@.cursor/plans/x.plan.md

Authority: Open PR only — do not merge.

Topology: PR base must be main.

Deliverables: archive.

Verification: manual check.
```
