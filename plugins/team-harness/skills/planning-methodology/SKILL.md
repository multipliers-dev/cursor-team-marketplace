---
name: planning-methodology
description: >-
  Portable staged-plan and merge-safe PR methodology (lightweight vs staged,
  execution authority, topology, frontmatter, agent prompts, plan closure).
  Use when creating or executing .cursor/plans, slicing work into PRs, writing
  agent prompts, or when User Rules point at this planning methodology skill.
---

# Planning methodology (canonical)

Single canonical **procedure** for merge-safe, staged planning. User Rules hold short always-on **invariants** (the `docs/engineering-invariants.md` paste from the installed **team-harness** plugin) — do not paste this full methodology into User Rules.

Repo domain checklists (API contracts, client-state matrices, route/domain examples, product skill verification runbooks, and similar) stay **in-repo**. This skill is the shared procedure only.

## When to use

- Creating or revising `.cursor/plans/*.plan.md`
- Choosing lightweight direct PR vs staged multi-PR plan
- Writing copy/paste agent prompts for slices
- Executing a plan slice (authority, topology, stop conditions)
- Closing / archiving a staged plan

## Lightweight vs staged

Not every change needs a multi-slice plan:

| Work shape                                                     | Path                                      |
| -------------------------------------------------------------- | ----------------------------------------- |
| Typo / small isolated fix                                      | Direct small PR; no multi-slice plan      |
| One coherent concern (one page, one module, one intent update) | Single implementation PR                  |
| Cross-cutting work spanning multiple concerns                  | Staged multi-PR plan via `.cursor/plans/` |

Lightweight PRs still follow **Open PR only** (default) and merge-safe rules — they skip the plan template. For unplanned lightweight work, the user may grant **Merge granted** with rationale in the current instruction without inventing a staged plan solely to authorize merge.

## Execution authority

**Repo default when no plan slice applies: Open PR only** — implement and open a PR; do not merge unless the current committed plan slice **or** the user’s explicit instruction for the current unplanned task grants **Merge granted** with rationale.

Authority ladder (narrowest → broadest):

```text
Plan-only PR  →  Open PR only  →  Merge granted
```

Orthogonal (not on the ladder): **Manual verification gate** — no commit, no PR, no tracked edits; run only the named verification; report verdict; stop.

| Label                    | Agent instruction (template)                                                                                                                                                               |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Plan-only PR             | Do not implement. Stop after opening the plan-only PR.                                                                                                                                     |
| Open PR only             | Do not merge. Stop after opening the PR.                                                                                                                                                   |
| Merge granted            | You may merge after documented verification passes and preconditions are met. Branch protection remains the final gate.                                                                    |
| Manual verification gate | Do not commit or open a PR. Run only the specified manual verification, do not perform implementation work, write only allowed gitignored outputs if needed, report the verdict, and stop. |

**Alias phrases → Plan-only PR** (unless broader authority is explicit): “commit the plan and open a PR”, “commit the plan only”, “open a plan-only PR”, “prepare a planning PR”, “open a PR for plan review”, “redraft the plan and open the PR”, “commit only the plan”, “plan review before implementation”.

Every slice documents: **Recommended authority**, **Rationale**, **Agent instruction** (verbatim in the prompt). Manual gates also document specified verification, allowed gitignored outputs, and verdict/stop. Merge granted also documents preconditions and required verification.

Branch protection and human review are the final enforcement boundary. Authority labels are handoff instructions, not credential envelopes.

## Repository topology invariant

Multi-slice plans stack **execution order**, not Git branches. Integration branch is `main` unless documented otherwise.

Do not infer PR target or topology from the current branch, a prior slice branch, another open PR, or local git state.

| Phase                 | Check                                                                                         |
| --------------------- | --------------------------------------------------------------------------------------------- |
| Before implementation | Start from latest `origin/main` (fresh branch)                                                |
| Before opening PR     | Branch represents **only** this slice; prior-slice work is on `main`, not via branch ancestry |
| After opening PR      | GitHub PR base is `main`; diff has no prior-slice work except through merged `main`           |

On mismatch: stop; do not continue on that PR.

## Merge-safe PRs (generic)

Each PR must be merge-safe on its own. Do not defer known gaps the current PR already exposes:

- correctness
- lifecycle / reset wiring for state this PR adds
- persistence boundaries
- validation / fallbacks / contract tests for behavior this PR introduces
- regression tests for behavior this PR introduces

Later PRs add capability that is genuinely unavailable — not paper over missing resets, tests, or wiring.

## Staged plan authoring

For multi-PR plans under `.cursor/plans/`:

0. Name files `*.plan.md` with frontmatter: `name`, `overview`, `todos`, `isProject`. Prefer [_template.plan.md](_template.plan.md).
1. Per-PR acceptance must be merge-safe alone on `main`.
2. Per-PR test plan lists checks required in **that** PR.
3. Do not park correctness that this merge already requires into a later PR.
4. End frontmatter todos with `plan-closure` (docs-only archive after last implementation slice).
5. **Recording slice completion depends on where the authoritative plan file lives:**
   - **Same-repo slice** (plan file and implementation are in the same repo): mark **its** todo `completed` in frontmatter in the **same** PR as the code.
   - **Cross-repo slice** (authoritative plan lives in a different repo than the implementation): do **not** duplicate or edit the plan from the implementation repo. Land the implementation PR(s) in their own repo, then record completion via a dedicated **plan-status PR** in the plan-owning repo after the implementation PR(s) satisfy the slice’s completion condition.
6. Do not archive inside implementation PRs unless the PR is the closure PR.
7. Include **Agent prompts (copy/paste for Cursor)** — one prompt per agent-executable frontmatter todo (including `plan-closure`, Manual gates, and any cross-repo plan-status PR). Present each prompt as `### <todo-id>` (heading copied from the existing frontmatter `id`; do not rename ids to match prose) plus a fenced `text` block with labeled Authority / Topology / Deliverables / Verification lines. Do not use quoted one-line bullets. Every default frontmatter todo has exactly one corresponding `### <todo-id>` heading. Each prompt: `@` plan path, slice id, scope boundaries (`only` / `do not start …`), deliverables/stop, verbatim Agent instruction, prerequisites, topology reminders when opening a PR, and the completion-recording rule from item 5 — same-repo prompts say “mark `<slice>` completed in plan frontmatter in this PR”; cross-repo implementation prompts say “do not edit the plan; record completion via the plan-status PR in the plan-owning repo.” This skill owns those structural prompt-layout invariants; repo `_template.plan.md` copies may specialize wording (domain notes, examples) but must not change the layout structure.
8. Include plan-level `## Recommended execution authority` table plus per-slice authority blocks.
9. **Native plan conversion:** When redrafting a Cursor-native plan (`~/.cursor/plans/`) into a committed `.cursor/plans/*.plan.md`, **wrap and slice; do not strip.** Add the required envelope (frontmatter todos, authority table, topology, per-slice blocks, agent prompts, `plan-closure`). Preserve mermaid/markdown diagrams and tables/checklists that encode the work (phased strategies, verification lists, capability models). Put those artifacts in the slice that will execute them, or in a `## Design` / `## Context` section implementation slices must follow — not only as a compressed appendix. A one-line summary may accompany a diagram; it must not replace it. "Redraft / align with this methodology" means add the envelope; it does not mean delete design artifacts to match the boilerplate skeleton. A pointer to `~/.cursor/plans/` is not enough — those files are local and not reviewable in the PR. Plan-review / conversion verification must include: source diagrams and implementation-critical structure preserved.

## Active vs archived

- Active: `.cursor/plans/*.plan.md` excluding `archive/` and `_template.plan.md` (never execute the template).
- Archive: historical only unless explicitly asked.
- Prefer active over archived when both exist; call out ambiguity.

## Plan completion (closure)

After the last implementation PR merges, docs-only closure PR:

1. Verify implementation PRs are actually **merged** to each target repo’s integration branch — do not trust frontmatter `completed` state alone. For cross-repo slices, verify the implementation PR(s) in the other repo(s) **and** the plan-status PR that recorded completion in this repo.
2. Verify remaining todos are `completed` or `cancelled`
3. Verify Manual verification gate verdicts / allowed artifacts
4. Add `# Shipped` (date, PR links across all repos, deferred work)
5. Move plan to `.cursor/plans/archive/YYYY-MM-DD-<slug>.plan.md`
6. Mark `plan-closure` completed; update references
7. No production behavior changes

## PR description (when opening from a plan)

When **opening** a PR from a plan slice, call out:

- Execution authority (Plan-only PR / Open PR only / Merge granted)
- PR target (default `main`)
- Which slice todo was marked completed (if any)
- What ships in **this** PR only
- Verification run
- Anything intentionally deferred

### Keep PR metadata current after follow-up pushes

After a later push to a branch that already has an open PR, refresh metadata when it no longer matches the branch — do not wait to be asked.

1. Run `gh pr view` for title, body, and **base branch** (the actual PR base, not a hardcoded `origin/main`).
2. Diff `base...HEAD` against the current branch state.
3. If title, summary, execution authority, shipped scope, or verification no longer matches the branch, refresh with `gh pr edit` **before stopping**.
4. Rebuild from the current PR `base...HEAD` diff plus the repo PR template when present. Review discussion stays in comments.

**Title:** update only when the headline is wrong.

**Body:** refresh drifted sections; do not leave an open-time Summary, authority checkbox, todo status, or Test plan that no longer matches the branch.

**Preserve** still-valid human-authored notes and links; do not regenerate the body wholesale unless it is structurally obsolete.

**Exclude** bot-owned PRs (Renovate and similar). **Skip** when title and body still match the branch.

Planning topology still defaults to targeting `main`; the keep-current diff uses the **actual PR base** from `gh pr view`.

## Progressive disclosure

- Full template skeleton: [_template.plan.md](_template.plan.md)
- Extended authority examples / handoff model: [reference.md](reference.md)

## Ownership reminder

| Layer      | Contents                                                                                                      |
| ---------- | ------------------------------------------------------------------------------------------------------------- |
| User Rules | Short invariants + pointer to this skill — not a second copy of this procedure                                |
| This skill | Full portable methodology, including canonical agent-prompt **layout** (heading + fence + labeled lines)      |
| Repo       | Domain supplements and wording specialization only — do not change prompt-layout structure                    |
