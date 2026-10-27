#!/usr/bin/env sh
# Copy canonical @multipliers-dev/savepoints-lite skills from node_modules into the
# committed plugin vendor tree (Cursor plugin install does not run npm install).
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PKG_ROOT="$ROOT/node_modules/@multipliers-dev/savepoints-lite"
VENDOR_ROOT="$ROOT/plugins/team-harness/vendor/savepoints-lite"
EXPECTED="$ROOT/scripts/expected-savepoints-vendor-paths.txt"

if [ ! -d "$PKG_ROOT/skills" ]; then
  echo "sync-savepoints-vendor: missing $PKG_ROOT/skills — run npm ci first" >&2
  exit 1
fi

PINNED="$(node -p "require('./package.json').devDependencies['@multipliers-dev/savepoints-lite']")"
INSTALLED="$(node -p "require('$PKG_ROOT/package.json').version")"
if [ "$PINNED" != "$INSTALLED" ]; then
  echo "sync-savepoints-vendor: pin $PINNED != installed $INSTALLED" >&2
  exit 1
fi

rm -rf "$VENDOR_ROOT/skills"
mkdir -p "$VENDOR_ROOT"
cp -R "$PKG_ROOT/skills" "$VENDOR_ROOT/skills"
printf '%s\n' "$INSTALLED" > "$VENDOR_ROOT/PACKAGE_VERSION"

while IFS= read -r rel || [ -n "$rel" ]; do
  [ -z "$rel" ] && continue
  if [ ! -f "$VENDOR_ROOT/$rel" ]; then
    echo "sync-savepoints-vendor: expected path missing after copy: $rel" >&2
    exit 1
  fi
done < "$EXPECTED"

echo "sync-savepoints-vendor: ok ($INSTALLED → $VENDOR_ROOT)"
