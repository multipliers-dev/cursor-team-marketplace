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

## Planning skill (when available)

- When creating or executing staged plans, use the team marketplace **planning-methodology** skill **if it is installed** (User or Team marketplace).

- Do not restate lightweight-vs-staged, frontmatter, agent-prompt construction, or closure procedure in Team Rules.

- If the skill is not available on this device/account, follow these PR execution invariants only; do not invent a second full methodology here.

- Do not assume Team Default On distribution until that Cursor path works.

## Cloud hooks

- Marketplace Cloud-hooks scripts are a portable primitive, not automatic Cloud-safety.

- Husky repos still need one-time `prepare` / ensure-hooks wiring per repo.
