# Package surface vs per-skill portability

Agent Plugins compatibility here is **package-level syntactic compliance**, not a claim that every discovered skill is cross-client functional.

The [Agent Plugins 1.0](https://agent-plugins.org/specification) fixed discovery model (`skills/`) exposes all three skills to any compatible client. The portable [`plugin.json`](../plugin.json) describes the **primary cross-client capability** (planning methodology). Keeping Cursor-dependent skills in `skills/` is a deliberate trade-off: one skill tree, standard discovery, honest per-skill classification — not a second directory or duplicated trees.

## Layers

| Layer | Paths | Role |
| --- | --- | --- |
| **Agent Plugins 1.0 package surface** | [`plugin.json`](../plugin.json), [`skills/`](../skills/) | Syntactic compliance: closed manifest + fixed skill discovery. **Not** a claim that every discovered skill is cross-client functional. |
| **Cursor extension** | [`.cursor-plugin/plugin.json`](../.cursor-plugin/plugin.json), root [`.cursor-plugin/marketplace.json`](../../../.cursor-plugin/marketplace.json) | Install flow, explicit `"skills": "./skills"` |
| **Shared supporting assets** | [`scripts/`](../scripts/), [`templates/`](../templates/), repo [`docs/engineering-invariants.md`](../../../docs/engineering-invariants.md) | Copied or referenced by skills; not plugin components |
| **Repo-dev-only** | [`scripts/check.sh`](../../../scripts/check.sh), [`scripts/test-*-runtime.sh`](../../../scripts/) | Marketplace CI |
| **Marketplace-only** | root [`.cursor-plugin/marketplace.json`](../../../.cursor-plugin/marketplace.json) | Team catalog (`pluginRoot: plugins`) |
| **Consumer-local** | target repo `.cursor/environment.json`, `.husky/*`, User Rules paste | Wired by bootstrap skills |

Unlike [`renovate-workflow`](https://github.com/multipliers-dev/renovate-workflow) (single-plugin repo, Agent Plugin ≈ portable workflow), **team-harness** ships one cross-client skill and two Cursor-dependent skills on the same discovery surface. That tests whether the packaging convention works when portability is not binary.

## Discovered skills

| Discovered skill | Portability | Notes |
| --- | --- | --- |
| `planning-methodology` | **Cross-client** | Primary capability named in package manifest `description`. Merge-safe PR doctrine, authority ladder, topology, and `gh` workflows transfer. `.cursor/plans/` paths are Cursor conventions other clients would rewrite — not runtime deps. |
| `repo-bootstrap` | **Cursor-dependent** | Stays in `skills/` per spec. Procedure assumes Cursor plugin install; output wires `.cursor/hooks.json`, `.cursor/environment.json`. |
| `cloud-hooks-bootstrap` | **Cursor-dependent** | Entire design targets Cursor Cloud: `~/.cursor/agent-hooks`, `~/.cursor/husky-bridge`, committed `.cursor/environment.json`, Cloud VM install/start lifecycle. |

**Important:** Agent Plugins 1.0 fixed discovery is `skills/` — there is no supported way to hide Cursor-only skills from other clients without duplicating trees. The boundary is **semantic and documentary**, not a second skill directory. Do **not** duplicate skills under `.cursor/skills/` or `.cursor-plugin/skills/`.

## Reference implementations

```text
renovate-workflow
    Agent Plugin ≈ portable workflow (+ Cursor extensions)

team-harness
    Agent Plugin package (syntactic compliance)
    ├── genuinely cross-client skill (planning-methodology)
    └── client-specific skills sharing the standard discovery mechanism
```

See also [versioning.md](versioning.md).
