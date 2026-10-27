#!/usr/bin/env sh
# Behavioral layout check: team-harness Savepoints wrapper + vendored skills (no consumer node_modules).
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN="$ROOT/plugins/team-harness"
WRAPPER="$PLUGIN/skills/savepoints/SKILL.md"
VENDOR_ROUTER="$PLUGIN/vendor/savepoints-lite/skills/savepoints/SKILL.md"
VENDOR_PROVIDER="$PLUGIN/vendor/savepoints-lite/skills/savepoints-notion/SKILL.md"

for path in "$WRAPPER" "$VENDOR_ROUTER" "$VENDOR_PROVIDER"; do
  if [ ! -f "$path" ]; then
    echo "verify-savepoints-marketplace-layout: missing $path" >&2
    exit 1
  fi
done

# Wrapper must establish marketplace install root (overrides canonical node_modules wording).
if ! grep -q 'package-equivalent install root' "$WRAPPER"; then
  echo "verify-savepoints-marketplace-layout: wrapper missing package-equivalent install root contract" >&2
  exit 1
fi
if ! grep -q 'take precedence' "$WRAPPER"; then
  echo "verify-savepoints-marketplace-layout: wrapper missing precedence over canonical npm paths" >&2
  exit 1
fi

# Paths referenced from wrapper must resolve on disk (same layout as installed plugin cache).
WRAPPER_DIR="$(cd "$(dirname "$WRAPPER")" && pwd)"
for rel in ../../vendor/savepoints-lite/skills/savepoints/SKILL.md \
  ../../vendor/savepoints-lite/skills/savepoints-notion/SKILL.md; do
  target="$WRAPPER_DIR/$rel"
  if [ ! -f "$target" ]; then
    echo "verify-savepoints-marketplace-layout: wrapper link does not resolve: $rel" >&2
    exit 1
  fi
done

# Optional: verify an installed plugin cache checkout (post marketplace refresh).
if command -v rg >/dev/null 2>&1; then
  cache_wrapper="$(rg --files -g 'team-harness/*/skills/savepoints/SKILL.md' \
    "${SAVEPOINTS_PLUGIN_CACHE_ROOT:-$HOME/.cursor/plugins/cache}" 2>/dev/null | head -n 1 || true)"
  if [ -n "$cache_wrapper" ] && [ -f "$cache_wrapper" ]; then
    cache_plugin="$(cd "$(dirname "$cache_wrapper")/../.." && pwd)"
    if [ ! -f "$cache_plugin/vendor/savepoints-lite/skills/savepoints/SKILL.md" ]; then
      echo "verify-savepoints-marketplace-layout: installed cache missing vendored router at $cache_plugin" >&2
      exit 1
    fi
    echo "verify-savepoints-marketplace-layout: ok (repo + installed cache $cache_plugin)"
    exit 0
  fi
fi

echo "verify-savepoints-marketplace-layout: ok (repo layout; no installed plugin cache yet — refresh team-harness after merge to verify cache)"
