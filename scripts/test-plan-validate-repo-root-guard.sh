#!/usr/bin/env sh
# Proves validate-plans --repo-root validates the caller tree, not the marketplace checkout.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
CLI="$ROOT/plugins/team-harness/scripts/validate-plans.ts"

WORKDIR=$(mktemp -d)
cleanup() {
  rm -rf "$WORKDIR"
}
trap cleanup EXIT INT TERM

CALLER="$WORKDIR/caller"
MARKET="$WORKDIR/marketplace-validator"
mkdir -p "$CALLER/.cursor/plans/active" "$MARKET/.cursor/plans/active"

# Invalid plan only under marketplace path (would fail if repo-root pointed at marketplace).
cat >"$MARKET/.cursor/plans/active/bad.plan.md" <<'EOF'
---
name: bad
overview: x
todos:
  - id: only-slice
    content: slice
    status: pending
isProject: false
---
# Bad

## Slice — only-slice

**Recommended authority:** Open PR only

## Agent prompts (copy/paste for Cursor)
EOF

# Valid plan under caller (canonical fixture).
cp "$ROOT/scripts/fixtures/plan-validate/valid-minimal.plan.md" \
  "$CALLER/.cursor/plans/active/ok.plan.md"

run_cli() {
  npx --yes -p "tsx@^4.23.13" -p "yaml@^2.8.1" tsx "$CLI" "$@"
}

if ! run_cli --repo-root "$CALLER" --allow-empty >/dev/null 2>&1; then
  echo "error: expected caller-root validation to pass" >&2
  run_cli --repo-root "$CALLER" --allow-empty >&2 || true
  exit 1
fi

if run_cli --repo-root "$MARKET" --allow-empty >/dev/null 2>&1; then
  echo "error: expected marketplace-root validation to fail on invalid plan" >&2
  exit 1
fi

echo "ok plan-validate repo-root guard (caller vs marketplace paths)"
