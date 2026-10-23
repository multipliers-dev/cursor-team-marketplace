#!/usr/bin/env sh
# Tarball install smoke for @multipliers-dev/plan-validator (no registry publish required).
set -eu
cd "$(dirname "$0")/.."

ROOT="$PWD"
FIXTURES="$ROOT/scripts/fixtures/plan-validate"
TEMPLATE="$ROOT/plugins/team-harness/skills/planning-methodology/_template.plan.md"
VALID="$FIXTURES/valid-minimal.plan.md"
INVALID="$FIXTURES/invalid-prompts-missing.plan.md"

npm ci
npm run build --workspace @multipliers-dev/plan-validator

PACK_DIR=$(mktemp -d)
INSTALL_PREFIX=$(mktemp -d)
cleanup() {
  rm -rf "$PACK_DIR" "$INSTALL_PREFIX"
}
trap cleanup EXIT INT TERM

pack_file=$(npm pack --workspace @multipliers-dev/plan-validator --pack-destination "$PACK_DIR" | tail -n 1)
pack_path="$PACK_DIR/$pack_file"
npm install --prefix "$INSTALL_PREFIX" --no-save "$pack_path"

BIN="$INSTALL_PREFIX/node_modules/.bin/plan-validator"
if [ ! -e "$BIN" ]; then
  echo "error: plan-validator bin not found after tarball install" >&2
  exit 1
fi

# Isolated consumer-like tree (no marketplace node_modules on NODE_PATH).
CONSUMER=$(mktemp -d)
mkdir -p "$CONSUMER/.cursor/plans/active"
cp "$VALID" "$CONSUMER/.cursor/plans/active/ok.plan.md"

PKG_CLI="$INSTALL_PREFIX/node_modules/@multipliers-dev/plan-validator/dist/plan-validator.mjs"

run_direct() {
  NODE_PATH= npm_config_prefix= node "$PKG_CLI" "$@"
}

run_shim_bin() {
  NODE_PATH= npm_config_prefix= "$BIN" "$@"
}

run_npm_exec() {
  NODE_PATH= npm_config_prefix= npm exec --yes --package="file:$pack_path" -- plan-validator "$@"
}

assert_exit() {
  expected=$1
  shift
  set +e
  "$@" >/dev/null 2>&1
  status=$?
  set -e
  if [ "$status" -ne "$expected" ]; then
    echo "error: expected exit $expected from $*; got $status" >&2
    exit 1
  fi
}

assert_stderr_contains() {
  needle=$1
  shift
  set +e
  out=$("$@" 2>&1 >/dev/null)
  status=$?
  set -e
  if ! printf '%s' "$out" | grep -Fq "$needle"; then
    echo "error: expected stderr to contain $needle; status=$status output=$out" >&2
    exit 1
  fi
}

exercise_entrypoint() {
  label=$1
  runner=$2
  shift 2

  assert_exit 0 "$runner" "$VALID"
  assert_exit 1 "$runner" "$INVALID"
  assert_stderr_contains "[prompts.missing]" "$runner" "$INVALID"
  assert_exit 2 "$runner" --bad-flag
  assert_exit 0 "$runner" --profile template "$TEMPLATE"
  assert_exit 0 "$runner" --repo-root "$CONSUMER" --allow-empty

  echo "ok entrypoint $label (valid/invalid/bad-flag/template/allow-empty)"
}

exercise_entrypoint "direct dist" run_direct
exercise_entrypoint "npm .bin shim" run_shim_bin
exercise_entrypoint "npm exec file:tarball" run_npm_exec

# Marketplace invalid plan must not affect consumer root validation.
MARKET_INVALID=$(mktemp -d)
mkdir -p "$MARKET_INVALID/.cursor/plans/active"
cp "$INVALID" "$MARKET_INVALID/.cursor/plans/active/bad.plan.md"
if run_shim_bin --repo-root "$CONSUMER" --allow-empty >/dev/null 2>&1; then
  :
else
  echo "error: consumer root validation failed" >&2
  exit 1
fi
if run_shim_bin --repo-root "$MARKET_INVALID" --allow-empty >/dev/null 2>&1; then
  echo "error: expected invalid marketplace-like tree to fail" >&2
  exit 1
fi

echo "ok plan-validator tarball install smoke (valid/invalid/template/allow-empty/caller isolation)"
