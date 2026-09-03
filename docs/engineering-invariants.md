# Engineering invariants

## Preferences

- Prefer quality, simplicity, robustness, and long-term maintainability over minimizing development cost.

- Prefer first-class tools that own the domain (`git`, `gh`, `npm`, filesystem) over browser automation or ad-hoc workarounds.

- Never invent secrets, credentials, or unverified claims.

- Communicate directly and concisely.

## PR execution

- Authority (narrowest → broadest): Plan-only PR → Open PR only → Merge granted.

- Default is Open PR only: implement the slice, open a PR targeting `main`, stop after opening. Do not merge unless Merge granted is explicit with rationale.

- Plan-only: plan artifacts only; stop after opening the PR; do not begin implementation; do not merge.

- Topology: start each slice from latest `origin/main`; the PR branch must represent only the current slice; previous-slice work arrives through merged `main`, not branch ancestry. Verify GitHub PR base is `main`.

- If Merge granted is absent or unclear, stop after opening the PR.

- If branch protection blocks merge, stop and escalate.

- Do not defer correctness, lifecycle/reset wiring, persistence boundaries, contract validation, or regression tests for behavior this PR already exposes.

- After pushing to a branch with an open PR, if the PR’s title, summary, execution authority, shipped scope, or verification no longer matches the branch, refresh the metadata with `gh pr edit` **before stopping**. Do not wait to be asked.

- Rebuild from the current PR `base...HEAD` diff, using `gh pr view` to resolve the base branch, plus the repo PR template when present. Review discussion stays in comments.

- Preserve still-valid human-authored notes and links; refresh only stale sections unless the whole body is structurally obsolete.

- Skip bot-owned PRs (Renovate and similar). Skip when title and body still match the branch.

## Checkout identity

- Before entering a git mutation or `gh` write sequence (commit, push, branch create, `gh pr create` / `edit` / `merge`), prove the intended checkout with `pwd` and `git remote get-url origin`. Prove once at the start of that sequence, not before every command; re-prove after changing checkout or cwd.

- Do not trust Shell `working_directory` alone in multi-root workspaces — it can start in the first listed root.

- Abort if the remote owner/repo is not the intended target. `cd` to the correct checkout and re-prove before continuing.

## Planning skill (when available)

- When creating or executing staged plans, use the **planning-methodology** skill **if it is installed**.

- Do not restate lightweight-vs-staged, frontmatter, agent-prompt construction, or closure procedure in this rule.

- If the skill is not available on this device/account, follow these PR execution invariants only; do not invent a second full methodology here.

## Cloud hooks

- Marketplace Cloud-hooks scripts are a portable primitive, not automatic Cloud-safety.

- Husky repos still need one-time `prepare` / ensure-hooks wiring per repo.

- **Configured `core.hooksPath` does not prove hooks are runnable.** A checkout can point at `.husky/_` while executable shims are missing (common after `git worktree add`). Run `npm run prepare` or `npm run verify:git-hooks` in each checkout before committing.

- **Plugin / marketplace install ≠ repo wired.** Installing the team-harness plugin distributes scripts; each Husky repo still copies and wires them once.

- **Layer 2a (`afterFileEdit` / format hook) is agent ergonomics only** — not a substitute for Husky, pre-commit checks, or CI.
