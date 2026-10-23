#!/usr/bin/env sh
# Marketplace-only: run installed tarball CLI like consumer CI (caller = repo root).
# Invoked from cursor-team-marketplace CI — not exposed via reusable workflow_call.
set -eu
cd "$(dirname "$0")/.."
ROOT="$PWD"

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

PKG_CLI="$INSTALL_PREFIX/node_modules/@multipliers-dev/plan-validator/dist/plan-validator.mjs"
if [ ! -f "$PKG_CLI" ]; then
  echo "error: missing installed CLI at $PKG_CLI" >&2
  exit 1
fi

run_cli() {
  NODE_PATH= npm_config_prefix= node "$PKG_CLI" "$@"
}

run_cli --repo-root "$ROOT" --allow-empty

run_cli --repo-root "$ROOT" --profile template \
  "$ROOT/plugins/team-harness/skills/planning-methodology/_template.plan.md"

echo "ok plan-validator marketplace tarball gates (allow-empty + template on repo root)"
