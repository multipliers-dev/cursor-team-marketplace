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

REPO_PLUGIN="$ROOT/plugins/team-harness"
if ! verify_plugin_savepoints_layout "$REPO_PLUGIN" "repo"; then
  exit 1
fi

CACHE_ROOT="${SAVEPOINTS_PLUGIN_CACHE_ROOT:-$HOME/.cursor/plugins/cache}"
CACHE_RAN=0
CACHE_OK=0

if command -v rg >/dev/null 2>&1 && [ -d "$CACHE_ROOT" ]; then
  while IFS= read -r cache_wrapper; do
    [ -z "$cache_wrapper" ] && continue
    [ ! -f "$cache_wrapper" ] && continue
    cache_plugin="$(cd "$(dirname "$cache_wrapper")/../.." && pwd)"
    CACHE_RAN=1
    if verify_plugin_savepoints_layout "$cache_plugin" "installed-cache"; then
      CACHE_OK=1
      echo "verify-savepoints-marketplace-layout: ok (repo + installed cache $cache_plugin)"
      exit 0
    fi
  done <<EOF
$(rg --files -g 'team-harness/*/skills/savepoints/SKILL.md' "$CACHE_ROOT" 2>/dev/null || true)
EOF
  if [ "$CACHE_RAN" -eq 1 ] && [ "$CACHE_OK" -eq 0 ]; then
    echo "verify-savepoints-marketplace-layout: installed cache present but failed full Savepoints layout checks" >&2
    exit 1
  fi
fi

echo "verify-savepoints-marketplace-layout: ok (repo layout)"
if [ "$CACHE_RAN" -eq 0 ]; then
  echo "verify-savepoints-marketplace-layout: installed-cache verification not run (no team-harness savepoints wrapper under $CACHE_ROOT — refresh plugin after merge)"
fi
exit 0
