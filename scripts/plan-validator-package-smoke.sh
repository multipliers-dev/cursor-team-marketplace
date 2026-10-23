#!/usr/bin/env sh
# Tarball install smoke for @multipliers-dev/plan-validator (no registry publish required).
set -eu
cd "$(dirname "$0")/.."

ROOT="$PWD"
FIXTURES="$ROOT/scripts/fixtures/plan-validate"
TEMPLATE="$ROOT/plugins/team-harness/skills/planning-methodology/_template.plan.md"

npm ci
npm run build --workspace @multipliers-dev/plan-validator

PACK_DIR=$(mktemp -d)
INSTALL_PREFIX=$(mktemp -d)
cleanup() {
  rm -rf "$PACK_DIR" "$INSTALL_PREFIX"
}
trap cleanup EXIT INT TERM

pack_file=$(npm pack --workspace @multipliers-dev/plan-validator --pack-destination "$PACK_DIR" | tail -n 1)
npm install --prefix "$INSTALL_PREFIX" --no-save "$PACK_DIR/$pack_file"

BIN="$INSTALL_PREFIX/node_modules/.bin/plan-validator"
if [ ! -e "$BIN" ]; then
  echo "error: plan-validator bin not found after tarball install" >&2
  exit 1
fi

# Isolated consumer-like tree (no marketplace node_modules on NODE_PATH).
CONSUMER=$(mktemp -d)
mkdir -p "$CONSUMER/.cursor/plans/active"
cp "$FIXTURES/valid-minimal.plan.md" "$CONSUMER/.cursor/plans/active/ok.plan.md"

PKG_CLI="$INSTALL_PREFIX/node_modules/@multipliers-dev/plan-validator/dist/plan-validator.mjs"

run_bin() {
  NODE_PATH= npm_config_prefix= node "$PKG_CLI" "$@"
}

run_bin "$FIXTURES/valid-minimal.plan.md" >/dev/null

if run_bin "$FIXTURES/invalid-prompts-missing.plan.md" >/dev/null 2>&1; then
  echo "error: expected invalid fixture to fail" >&2
  exit 1
fi

run_bin --profile template "$TEMPLATE" >/dev/null

if ! run_bin --repo-root "$CONSUMER" --allow-empty >/dev/null 2>&1; then
  echo "error: expected allow-empty consumer root to pass" >&2
  exit 1
fi

# Marketplace invalid plan must not affect consumer root validation.
MARKET_INVALID=$(mktemp -d)
mkdir -p "$MARKET_INVALID/.cursor/plans/active"
cp "$FIXTURES/invalid-prompts-missing.plan.md" "$MARKET_INVALID/.cursor/plans/active/bad.plan.md"
if run_bin --repo-root "$CONSUMER" --allow-empty >/dev/null 2>&1; then
  :
else
  echo "error: consumer root validation failed" >&2
  exit 1
fi
if run_bin --repo-root "$MARKET_INVALID" --allow-empty >/dev/null 2>&1; then
  echo "error: expected invalid marketplace-like tree to fail" >&2
  exit 1
fi

echo "ok plan-validator tarball install smoke (valid/invalid/template/allow-empty/caller isolation)"
