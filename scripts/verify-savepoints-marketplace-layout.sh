#!/usr/bin/env sh
# Behavioral layout check: team-harness Savepoints wrapper + vendored skills (no consumer node_modules).
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

verify_plugin_savepoints_layout() {
  plugin_root="$1"
  label="$2"
  wrapper="$plugin_root/skills/savepoints/SKILL.md"
  vendor_router="$plugin_root/vendor/savepoints-lite/skills/savepoints/SKILL.md"
  vendor_provider="$plugin_root/vendor/savepoints-lite/skills/savepoints-notion/SKILL.md"

  for path in "$wrapper" "$vendor_router" "$vendor_provider"; do
    if [ ! -f "$path" ]; then
      echo "verify-savepoints-marketplace-layout: [$label] missing $path" >&2
      return 1
    fi
  done

  if ! grep -q 'package-equivalent install root' "$wrapper"; then
    echo "verify-savepoints-marketplace-layout: [$label] wrapper missing package-equivalent install root contract" >&2
    return 1
  fi
  if ! grep -q 'take precedence' "$wrapper"; then
    echo "verify-savepoints-marketplace-layout: [$label] wrapper missing precedence over canonical npm paths" >&2
    return 1
  fi
  if ! grep -q 'savepoints_lite' "$wrapper"; then
    echo "verify-savepoints-marketplace-layout: [$label] wrapper missing savepoints_lite User Rules namespace" >&2
    return 1
  fi
  if ! grep -q 'savepoints_lite.destination' "$wrapper"; then
    echo "verify-savepoints-marketplace-layout: [$label] wrapper missing savepoints_lite.destination mapping" >&2
    return 1
  fi
  if ! grep -q 'Tier-1 destination handoff' "$wrapper"; then
    echo "verify-savepoints-marketplace-layout: [$label] wrapper missing tier-1 destination handoff section" >&2
    return 1
  fi

  wrapper_dir="$(cd "$(dirname "$wrapper")" && pwd)"
  for rel in ../../vendor/savepoints-lite/skills/savepoints/SKILL.md \
    ../../vendor/savepoints-lite/skills/savepoints-notion/SKILL.md; do
    target="$wrapper_dir/$rel"
    if [ ! -f "$target" ]; then
      echo "verify-savepoints-marketplace-layout: [$label] wrapper link does not resolve: $rel" >&2
      return 1
    fi
  done

  return 0
}

read_team_harness_version() {
  plugin_root="$1"
  overlay="$plugin_root/.cursor-plugin/plugin.json"
  package="$plugin_root/plugin.json"
  if [ -f "$overlay" ]; then
    node -p "require(process.argv[1]).version" "$overlay"
    return 0
  fi
  if [ -f "$package" ]; then
    node -p "require(process.argv[1]).version" "$package"
    return 0
  fi
  echo ""
}

REPO_PLUGIN="$ROOT/plugins/team-harness"
EXPECTED_VERSION="$(read_team_harness_version "$REPO_PLUGIN")"
if [ -z "$EXPECTED_VERSION" ]; then
  echo "verify-savepoints-marketplace-layout: could not read expected team-harness version from $REPO_PLUGIN" >&2
  exit 1
fi

if ! verify_plugin_savepoints_layout "$REPO_PLUGIN" "repo"; then
  exit 1
fi

CACHE_ROOT="${SAVEPOINTS_PLUGIN_CACHE_ROOT:-$HOME/.cursor/plugins/cache}"
CACHE_ANY_WRAPPER=0
CACHE_EXPECTED_MATCH=0
CACHE_VERIFIED=0
CACHE_VERIFIED_PATH=""
CACHE_DISCOVERY_FAILED=0

if [ -d "$CACHE_ROOT" ]; then
  find_list="$(mktemp)"
  find_err="$(mktemp)"
  if find "$CACHE_ROOT" -type f -path '*/team-harness/*/skills/savepoints/SKILL.md' >"$find_list" 2>"$find_err"; then
    while IFS= read -r cache_wrapper || [ -n "$cache_wrapper" ]; do
      [ -z "$cache_wrapper" ] && continue
      [ ! -f "$cache_wrapper" ] && continue
      CACHE_ANY_WRAPPER=1
      cache_plugin="$(cd "$(dirname "$cache_wrapper")/../.." && pwd)"
      cache_version="$(read_team_harness_version "$cache_plugin")"
      if [ "$cache_version" != "$EXPECTED_VERSION" ]; then
        continue
      fi
      CACHE_EXPECTED_MATCH=1
      if ! verify_plugin_savepoints_layout "$cache_plugin" "installed-cache v$EXPECTED_VERSION"; then
        rm -f "$find_list" "$find_err"
        exit 1
      fi
      CACHE_VERIFIED=1
      CACHE_VERIFIED_PATH="$cache_plugin"
    done <"$find_list"
  else
    CACHE_DISCOVERY_FAILED=1
    echo "verify-savepoints-marketplace-layout: installed-cache discovery failed under $CACHE_ROOT ($(tr '\n' ' ' <"$find_err" | sed 's/  */ /g'))" >&2
  fi
  rm -f "$find_list" "$find_err"
fi

if [ "$CACHE_DISCOVERY_FAILED" -eq 1 ]; then
  exit 1
fi

if [ "$CACHE_VERIFIED" -eq 1 ]; then
  echo "verify-savepoints-marketplace-layout: ok (repo + installed cache v$EXPECTED_VERSION at $CACHE_VERIFIED_PATH)"
  exit 0
fi

echo "verify-savepoints-marketplace-layout: ok (repo layout)"
if [ "$CACHE_ANY_WRAPPER" -eq 1 ] && [ "$CACHE_EXPECTED_MATCH" -eq 0 ]; then
  echo "verify-savepoints-marketplace-layout: installed-cache verification not run (team-harness cache found but none at version $EXPECTED_VERSION — refresh plugin)"
elif [ "$CACHE_ANY_WRAPPER" -eq 0 ]; then
  echo "verify-savepoints-marketplace-layout: installed-cache verification not run (no team-harness savepoints wrapper under $CACHE_ROOT — refresh plugin after merge)"
fi
exit 0
